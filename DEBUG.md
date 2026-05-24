# DEBUG.md – GLIBC_2.34 error on Ubuntu 18.04

## Scenario

Binary built on iximiuz playground (Ubuntu 24.04) fails on Ubuntu 18.04 with:
`./main: /lib/x86_64-linux-gnu/libc.so.6: version 'GLIBC_2.34' not found`

## Two ranked hypotheses

1. **CGO is enabled** (more likely). Go's `net` package uses CGO by default, which links against the build machine's glibc version (2.34). Ubuntu 18.04 has older glibc (2.27) and can't run it.

2. **Binary is dynamically linked** (less likely). Maybe `go build` produced a dynamically linked binary despite `file` saying "statically linked". But the error is a version mismatch, not missing library, so this is probably wrong.

## Verification steps

**For hypothesis 1:** On the build machine, run `go env CGO_ENABLED`. If it prints `1`, CGO is on. Then `ldd ./main` – if it shows `libc.so.6`, that's the dependency.

**For hypothesis 2:** On the Ubuntu 18.04 VM, run `readelf -d ./main | grep NEEDED`. If it shows `libc.so.6`, it's dynamically linked.

## Fix

Rebuild with `CGO_ENABLED=0 go build -o main main.go`. This forces a pure Go binary with no glibc dependency.

## One‑sentence lesson

Go binaries are not fully static by default because CGO links to the build machine's glibc, and glibc is not backward-compatible across major versions.