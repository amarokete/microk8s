# HTTP Ingress

This is a basic example of using Ingress to access a Service from outside the cluster.

## Setup

  1. Ensure port 80 on the Vagrant guest is properly forwarded to your host.
  2. Ensure the `ingress` add-on is enabled for your cluster.

## Deployment

Run `kubectl apply -f .` inside the `examples/HTTP_Ingress` directory. You can also run each file
individually, but the order is important: Service > Deployment > Ingress.

In this example, Nginx could be replaced by any containerized HTTP web application.

## Tear Down

```bash
kubectl delete ing nginx

kubectl delete deploy nginx

kubectl delete svc nginx
```
