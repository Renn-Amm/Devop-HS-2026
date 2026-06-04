# DEBUG.md — Challenge 4: Deploy to Kubernetes

## Scenario

Pipeline pushes image to ttl.sh and applies the Pod manifest.
kubectl get pods shows ImagePullBackOff. The image field in the manifest
matches the tag the pipeline pushed. On the Jenkins machine docker pull
succeeds fine.

## My Initial Theory

My first thought was that the tag was wrong or the image had expired on
ttl.sh since it has a 2h TTL. I checked the tag in the manifest against
what the pipeline pushed and they matched. I asked:

> "The image pulls fine from Jenkins but the Pod shows ImagePullBackOff
> — could ttl.sh block pulls from inside a Kubernetes cluster?"

AI pushed back — the more likely explanation is that the kubelet on the
cluster node is doing the pulling, not Jenkins. The kubelet runs in a
completely different network context. That reframing made the problem
clearer.

## Hypotheses

### Hypothesis 1 — Image expired on ttl.sh before kubelet pulled it (most likely)

ttl.sh images expire after the TTL in the tag (2h). If there was any
delay between the push and the Pod being scheduled, the image may have
already expired by the time the kubelet tried to pull it.

Verification:
```bash
kubectl describe pod myapp | grep -A5 Events
```
If the event log shows 404 Not Found or manifest unknown from the
registry, the image has expired.

### Hypothesis 2 — Kubelet cannot reach ttl.sh from inside the cluster

The Jenkins machine can reach ttl.sh but the cluster nodes may be on a
different network without external internet access.

Verification:
```bash
kubectl run test --image=busybox --rm -it --restart=Never -- \
    wget -qO- https://ttl.sh
```
If this times out the cluster has no outbound internet access.

## Fix

Push a fresh image immediately before applying the manifest so the
kubelet pulls it before it expires:

```bash
docker build -t ttl.sh/renn-amm:2h .
docker push ttl.sh/renn-amm:2h
kubectl delete pod myapp --ignore-not-found
kubectl apply -f k8s_deploy/pod.yaml
```

The pipeline already does this in order so expiry is only a risk if
the deploy stage is delayed significantly after the push stage.

## Lesson

"I can pull this image" means your machine has network access to the
registry right now — it says nothing about whether the cluster kubelet
shares that network path or whether the image will still exist when
it tries.
