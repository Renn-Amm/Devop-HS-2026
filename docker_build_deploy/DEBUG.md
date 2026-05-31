# DEBUG.md — Challenge 3: Docker Build and Deploy

## Scenario

Built the image on Apple Silicon (ARM64) with plain docker build, pushed
it green. On the docker VM (x86_64) the pull succeeds but docker run
immediately exits with:
`exec /app/main: exec format error`

## My Initial Theory

My first thought was that the binary was corrupted during the push or the
registry mangled it somehow. I checked the logs and the pull completed
cleanly with no errors. I asked:

> "The container dies immediately with exec format error but the pull
> succeeded — could the registry have corrupted the binary during push?"

AI pushed back on this — exec format error is not a corruption signal.
It is the kernel's way of saying it cannot execute this binary because
the CPU instruction set does not match. That pointed directly at the
build machine architecture rather than anything to do with the registry.

## Hypotheses

### Hypothesis 1 — Binary compiled for ARM64, running on x86_64 (most likely)

The build machine was Apple Silicon (ARM64). Without explicit platform
flags, docker build compiles for the host CPU. The Go binary inside the
image is ARM64 and the x86_64 kernel cannot execute it.

Verification:
```bash
docker run --rm --entrypoint file ttl.sh/renn-amm:2h /app/main
```
If output says `ELF 64-bit LSB executable, ARM aarch64` the binary is
the wrong architecture for the VM.

### Hypothesis 2 — Docker pulled the ARM image manifest variant

The registry stores separate manifests per architecture. Without a
platform flag on docker pull, Docker may have resolved to the ARM
variant of the base image, making the entire image ARM.

Verification:
```bash
docker inspect ttl.sh/renn-amm:2h | grep Architecture
```
If it shows `arm64` instead of `amd64` the manifest resolved to the
wrong platform.

## Fix

Build explicitly for the target platform using buildx:
```bash
docker buildx build \
    --platform linux/amd64 \
    -t ttl.sh/renn-amm:2h \
    --push .
```

Or force the architecture in the Dockerfile Go build step:
```dockerfile
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o main .
```

Both force the output to x86_64 regardless of the build machine.

## Lesson

"The image is built" only promises the image exists in the registry —
it makes no guarantee that the binary inside matches the CPU architecture
of the machine that will actually run it.
