FROM golang:1.24 AS builder
WORKDIR /app
COPY app/ .
RUN go mod init app 2>/dev/null || true
RUN go mod tidy
RUN CGO_ENABLED=0 GOOS=linux go build -o main .

FROM busybox AS final
COPY --from=builder /app/main /app/main
EXPOSE 4444
HEALTHCHECK --interval=10s --timeout=2s --retries=3 CMD wget -qO- http://localhost:4444/ || exit 1
ENTRYPOINT ["/app/main"]