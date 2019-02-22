# Mongo

This is an example of deploying a 3-node MongoDB replica set as a _StatefulSet_ using the `local`
_PersistentVolume_ spec on Minikube.

### Create local volumes

Minikube storage is ephemeral except for a few special directories. One of those directories is
`/data`, so that's where we'll be creating our "volumes".

In a production scenario, these folders would probably be some sort of mounted block storage like
AWS Elastic Block Storage or GCP Persistent Disk. It is also possible to configure the cluster to
_dynamically_ provision these volumes (and dispose of them); however, this is not possible when
using local folders.

SSH into the Minikube VM and create 3 folders:

```bash
minikube ssh

sudo mkdir -p /data/pv-0
sudo mkdir -p /data/pv-1
sudo mkdir -p /data/pv-2
```

### Create StorageClass

When using `local` volumes, the _StorageClass_ resource is used primarily for the `volumeBindingMode: WaitForFirstConsumer`
field. Per the docs: _Delaying volume binding allows the scheduler to consider all of a pod’s scheduling constraints when choosing an appropriate PersistentVolume for a PersistentVolumeClaim._

The _StorageClass_ is also used to bind a specific type of _PersistentVolume_ to a _PersistentVolumeClaim_.

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: mongo-sc
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
```

### Create PersistentVolumes

The _PersistentVolume_ resource is a resource in the cluster just like a _Node_. It is provisioned
by the cluster administrator, and is consumed by a _PersistentVolumeClaim_. Because we are going to
have 3 replicas, we will need to create 3 _PV_s.

The `spec.capacity.storage` field defines how much storage capacity is available to be consumed. If
a _PVC_ requests more than this amount, it won't be bound to the _PV_.

The `spec.accessModes` field declares the type of r/w access allowed. For example, if the _PVC_
requires `ReadWriteMany` access, it can only be bound to an appropriately configured _PV_.

The `spec.persistentVolumeReclaimPolicy` field declares the policy for reclaiming storage after a
_PV_ is deleted. `Retain` is the default for manually-provisioned _PV_s; `Delete` is the default for
dynamically-provisioned _PV_s.

The `spec.storageClassName` field defines the name of the _SC_ that the _PV_ inherits from. When the
_SC_ is defined, the _PVC_ must also declare the same _SC_ in order to be bound.

The `spec.local.path` field defines the path on the local filesystem to use as storage. Using this
field also requires the use of `nodeAffinity`, which determines which _Node_ to deploy the _PV_ to.

The local folder must be created before deploying the _PV_. If you need to do any initial data
population, you can bind-mount the folder to a Docker container and remove the container when you're
done. On a multi-node cluster, you would do this by SSHing into the node and running `docker run`.

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: mongo-pv-0
spec:
  capacity:
    storage: 100Mi
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: mongo-sc
  local:
    path: /data/pv-0
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - minikube
```

### Create Service

The _Service_ resource is an abstraction that defines a logical set of pods and a policy to access
them. In a normal _Deployment_, you can create the service after the deployment, or simply expose
the deployment using `kubectl`. A _StatefulSet_ requires the service to be created first.

The `metadata.labels` field will be matched by the `spec.selector.matchLabels` field in the _StatefulSet_.

Setting `clusterIP` to `None` makes this a [_headless service_](https://kubernetes.io/docs/concepts/services-networking/service/#headless-services).

The `port` is the port to access the service, while the `targetPort` is the exposed port in the
container.

Finally, the selector will match `spec.template.metadata.labels` in the _StatefulSet_.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: mongo
  labels:
    app: mongo
spec:
  clusterIP: None
  ports:
  - name: mongodb
    port: 27017
    targetPort: 27017
  selector:
    app: mongo
```

### Create StatefulSet

The _StatefulSet_ resource is a special type of deployment intended for stateful applications.

The pod name in a _StatefulSet_ will always be the same, which is important because your application
will most likely always point to the same database URI. _StatefulSet_s also scale up and down in
order; i.e., `db-0` will be created first, followed by `db-1`.

In this example, the Mongo URI will be `mongodb://db-0.mongo:27017`. The naming convention is the
pod name followed by the service name. This is important because when configuring the Mongo replica
set, we need to have stable host names so the databases can communicate with one another.

Notice that we are not creating a separate _PersistentVolumeClaim_. This is because the
_StatefulSet_ will create a _PVC_ each time it is scaled.

The `spec.volumeClaimTemplates` field is a list of _PVC_s. The `mongo-pvc` _PVC_ will be satisfied
by the `mongo-pv` _PV_ created earlier. The claim name will be `mongo-pvc-db-0` and will always be
paired to the `db-0` pod.

Note that the _PV_ bound to the _PVC_ is not guaranteed to be in order (in my experience). This
means that `mongo-pv-1` could be bound to `mongo-pvc-db-0`. You can run `kubectl get pv,pvc` to see
a summary of the resulting binding operations.

Also note that there is only 1 replica to start. This is because we will need to do some manual
configuration in the `mongo` shell before scaling up.

The `"docker-entrypoint.sh --replSet rs"` command tells the Mongo daemon that it is part of a
replica set named "rs".

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: db
spec:
  replicas: 1
  serviceName: mongo
  selector:
    matchLabels:
      app: mongo
  template:
    metadata:
      labels:
        app: mongo
    spec:
      containers:
      - name: mongo
        image: mongo:3.6.4
        ports:
        - name: mongodb
          containerPort: 27017
        volumeMounts:
        - name: mongo-pvc
          mountPath: /data/db
        command: ["docker-entrypoint.sh", "--replSet", "rs"]
  volumeClaimTemplates:
  - metadata:
      name: mongo-pvc
    spec:
      storageClassName: mongo-sc
      accessModes:
      - ReadWriteOnce
      resources:
        requests:
          storage: 100Mi
```

### Configure Mongo Replica Set

We are going to make the pod `db-0` the master in the replica set and add the URIs of the upcoming
slave replicas.

There are "sidecar" containers that can be run in the same pod as the database container that do
this for you automatically, but I think it's important to see how this works under the hood (and how
easy it is).

First execute the Mongo shell in the pod:

```bash
kubectl exec -it db-0 -- mongo
```

Then initiate the replica set:

```javascript
rs.initiate();
```

Your prompt should change to `rs:PRIMARY>`, if it doesn't, give it a few seconds and hit enter
again.

Run `rs.conf();` to see the configuration for the replica set. Notice that the host name
`db-0:27017` is incorrect. You need to change this, otherwise the slave replicas won't be able to
connect to the master.

```javascript
var conf = rs.conf();

conf.members[0].host = "db-0.mongo:27017";

rs.reconfig(conf);
```

Now we can add the replicas. Notice how we can reliably assume the name of the pods that will be
deployed when scaling up, because we are using a _StatefulSet_.

```javascript
rs.add({ host: "db-1.mongo:27017", priority: 0, votes: 0 });
rs.add({ host: "db-2.mongo:27017", priority: 0, votes: 0 });
```

### Scale Up

Now we can add the final members to our replica set.

```bash
kubectl scale sts db --replicas=3
```

Wait a few seconds and run `kubectl get pods`. You should see:

```
NAME      READY     STATUS    RESTARTS   AGE
db-0      1/1       Running   0          16m
db-1      1/1       Running   0          12s
db-2      1/1       Running   0          9s
```

Go back to the `mongo` shell in `db-0` and run `rs.status();` to confirm that the new members have
the `SECONDARY` state.

Remember that database operations should be done on the `PRIMARY`. The `SECONDARY` replicas will
keep themselves in-sync. If you do need to run a query on a slave, run `rs.slaveOk();` when
connected to the slave.
