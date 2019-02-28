# MongoDB Replica Set

This is an example of deploying a 3-node MongoDB replica set as a StatefulSet.

## Setup
  1. Ensure the `storage` add-on has been enabled on your cluster. Read the `microk8s` [README](https://github.com/ubuntu/microk8s) and `hostpath-provisioner` [README](https://github.com/juju-solutions/hostpath-provisioner) for more information.

## Deployment

We will be deploying a Service and a StatefulSet.

The Service must be deployed before the StatefulSet and the Service must be a _headless_ Service,
i.e., it must not have a Cluster IP.

The Pod name in a StatefulSet will always be the same, and will always scale in order, i.e., `db-0`
will be created first, followed by `db-1`. This is important, as it ensures the DNS lookup will
point to the appropriate resource.

We don't need to create separate PersistentVolumeClaims because the StatefulSet will create one each
time it is scaled.

We need to change the default command to pass the `--replSet` flag to `docker-entrypoint.sh`, which
creates a Replica Set (named `rs` in this example).

We are starting with 1 replica to start because we will be configuring the Replica Set in MongoDB
manually. You can use the _sidecar container_ pattern to do this automatically using [mongo-k8s-sidecar](https://github.com/cvallance/mongo-k8s-sidecar).

To deploy, run `kubectl apply -f .` inside the `examples/MongoDB_Replica_Set` directory.

### Configuring the Replica Set

We are going to make the pod `db-0` the master in the replica set and add the URIs of the upcoming
slave replicas.

First make sure the StatefulSet is ready (this can take a minute if pulling the image for the first
time):

```bash
kubectl get sts db
```

Execute the Mongo shell in the pod:

```bash
kubectl exec -it db-0 -- mongo
```

Initiate the replica set:

```javascript
rs.initiate();
```

Your prompt should change to `rs:PRIMARY>`, if it doesn't, give it a few seconds and hit enter
again (it might change to `rs:OTHER>` first).

The host name is the pod name by default, but we need to change it to `<pod.name>.<svc.name>`.

```javascript
var conf = rs.conf();

conf.members[0].host = "db-0.mongo:27017";

rs.reconfig(conf);
```

Now we can add the replicas. Notice how we can reliably assume the name of the pods that will be
deployed when scaling up.

```javascript
rs.add({ host: "db-1.mongo:27017", priority: 0, votes: 0 });
rs.add({ host: "db-2.mongo:27017", priority: 0, votes: 0 });
```

Enter `exit` to exit the Mongo shell.

### Scale Up

Now we can add the final members to our replica set.

```bash
kubectl scale sts db --replicas=3
```

Wait a few seconds and run `kubectl get sts db`. You should see 3/3 as ready.

Go back to the Mongo shell in `db-0` and run `rs.status();` to confirm that the new members have
the `SECONDARY` state.

Remember that database operations should be done on the `PRIMARY`. The `SECONDARY` replicas will
keep themselves in-sync. If you do need to run a query on a slave, run `rs.slaveOk();` when
connected to the slave.

## Tear Down

Deleting a StatefulSet does not provide any guarantees on the termination of created Pods, so scale
down to 0 replicas before deletion.

```bash
kubectl scale sts db --replicas=0

# Ensure 0/0 are ready
kubectl get sts db

kubectl delete sts db

kubectl delete svc mongo

# Reclaim Policy is "Delete" by default, so the volumes will be deleted once the claims are removed
kubectl delete pvc mongo-db-0
kubectl delete pvc mongo-db-1
kubectl delete pvc mongo-db-2
```

## Accessing MongoDB Outside the Cluster

Applications running inside the cluster can access the database using DNS. Not exposing your
database to the outside world is great for security, but makes administration more difficult.

The easiest way to access a port on a Kubernetes resource is to enable [port forwarding](https://kubernetes.io/docs/tasks/access-application-cluster/port-forward-access-application-cluster/).
