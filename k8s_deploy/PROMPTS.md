# PROMPTS.md — Challenge 4: Deploy to Kubernetes

## How I Used This Session

Same approach as previous challenges — identified the moving parts,
formed a view on how they connect, then used the AI to fill gaps and
correct wrong assumptions.

---

## Authenticating Jenkins to Kubernetes

The challenge required a ServiceAccount token. I understood the concept
but asked:

> "Why do we need a ServiceAccount token rather than copying the
> kubeconfig from the kubernetes VM directly?"

AI explained that Jenkins runs as its own process with no access to the
cluster kubeconfig. The ServiceAccount token is the portable credential
that can be stored in Jenkins and used from the pipeline without copying
sensitive cluster files around.

## What I decided
- Created jenkins-robot ServiceAccount with cluster-admin binding
- Stored token as Secret text in Jenkins credentials
- Referenced it via withCredentials block in the pipeline

---

## Pod vs Deployment

I asked whether to use a bare Pod or a Deployment. The challenge says
kind: Pod explicitly but I wanted to understand why. I asked:

> "The challenge specifies kind: Pod — is there a reason not to use a
> Deployment which handles restarts automatically?"

AI explained that for this challenge a bare Pod is correct because the
auto-checker looks for a Pod named myapp specifically. In production you
would always use a Deployment because it handles restarts, rolling
updates, and scaling. A bare Pod that crashes stays dead.

---

## Stretch Task — Liveness vs Readiness Probes

I picked liveness and readiness probes. Both hit the same endpoint but
I was not clear on what each one controls independently. I asked:

> "Both probes hit port 4444 — what does liveness control that
> readiness doesn't?"

Readiness controls whether the Pod receives traffic. If it fails,
Kubernetes removes the Pod from Service endpoints so no requests are
routed to it but the container keeps running. This handles startup
delay or temporary unreadiness.

Liveness controls whether the container should be restarted. If it
fails, Kubernetes kills and restarts the container. This handles a
hung or broken process that cannot recover on its own.

Readiness gates traffic. Liveness gates existence. They solve different
problems even when pointing at the same endpoint.

## What I pushed back on
My first instinct was to kubectl apply twice and let it handle updates.
AI pointed out that Pods are not updatable in place unlike Deployments.
The fix was kubectl delete --ignore-not-found before apply so the
pipeline is safe to re-run.
