# PROMPTS.md — Challenge 3: Docker Build and Deploy

## How I Used This Session

Same approach as the previous challenge — I identified what was breaking,
formed a theory, then checked it with the AI. Where I had a decision to
make I asked for the tradeoffs rather than just the answer.

---

## Dockerfile Design — Multi-stage from the Start

I knew I needed a Dockerfile and had a choice between starting simple
with a single stage or going multi-stage immediately. I asked:

> "Is it worth going multi-stage from the start or should I get the core
> working first with a single stage golang:1.24 image?"

AI pointed out that single-stage golang:1.24 lands around 800MB and the
stretch task auto-checker requires under 50MB anyway, so multi-stage was
the right starting point rather than an optimization to add later.

## What I decided
- Build stage on golang:1.24, final stage on scratch
- CGO_ENABLED=0 GOOS=linux to produce a fully static binary
- Static binary required because scratch has no libc

## CGO_ENABLED=0 Requirement

I knew CGO_ENABLED=0 was needed but wanted to understand why specifically
for scratch. I asked:

> "Would the binary actually fail at runtime without CGO_ENABLED=0 or
> would it just be larger?"

AI explained that without it the Go binary dynamically links against
glibc at runtime. scratch has no glibc so the binary would fail
immediately with a missing shared library error, not just be larger.

---

## HEALTHCHECK Directive

I wanted to add the HEALTHCHECK stretch on top of the multi-stage build.
My initial assumption was that distroless/base-debian12 would have wget
since it is a Debian-based image. I asked:

> "Does distroless/base-debian12 include wget or do I need to install it?"

AI confirmed distroless intentionally strips all package managers and
most tools — wget is not included. I pushed back:

> "So if distroless has no wget and scratch has nothing, what base image
> actually has wget without bloating the image significantly?"

AI suggested busybox — it is around 5MB, includes wget built in, and is
designed exactly for minimal container use cases.

## What I decided
Switched final stage from scratch to busybox. Slightly larger than
scratch but still well under 50MB and actually has the tools needed
for the HEALTHCHECK to run.

## What I pushed back on
My first instinct was to copy the wget binary from the builder stage into
scratch. AI confirmed this is possible but complex — you would need to
copy all the shared libraries wget depends on as well. busybox is a
cleaner solution for the same outcome.

---

## HEALTHCHECK and Kubernetes

The stretch task asked me to surface what an orchestrator does with a
HEALTHCHECK signal. I asked:

> "What does Kubernetes actually do when a container's healthcheck fails
> compared to what Docker does?"

Docker marks the container unhealthy in docker inspect but takes no
automatic action — it is informational only.

Kubernetes livenessProbe (the equivalent) actively restarts the container
when the probe fails and removes the pod from Service endpoints so it
stops receiving traffic until it recovers. The difference is Docker
reports the problem, Kubernetes acts on it.

---

## Deploy Stage Idempotency

I noticed docker run would fail on a second pipeline run because the
container name myapp would already exist. I asked:

> "What is the standard pattern for making docker run idempotent when
> using a fixed container name?"

AI confirmed docker rm -f myapp 2>/dev/null || true before docker run
is the standard approach. The 2>/dev/null silences the error on a fresh
VM where the container does not exist yet.
