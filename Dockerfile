# ---------- Build Stage ----------
FROM golang:1.25.1-alpine AS builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -p 1 -o muchtodo ./cmd/api/main.go

# ---------- Runtime Stage ----------
FROM alpine:latest

RUN addgroup -S appgroup && adduser -S appuser -G appgroup

RUN apk add --no-cache ca-certificates curl

WORKDIR /app

COPY --from=builder /app/muchtodo .

USER appuser

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
CMD curl -f http://localhost:8080/health || exit 1

CMD ["./muchtodo"]
