FROM golang:1.24 AS builder
WORKDIR /app
COPY app/ .
RUN go mod init app 2>/dev/null || true
RUN go mod tidy
RUN CGO_ENABLED=0 GOOS=linux go build -o main .

FROM scratch
COPY --from=builder /app/main /app/main
EXPOSE 4444
ENTRYPOINT ["/app/main"]
