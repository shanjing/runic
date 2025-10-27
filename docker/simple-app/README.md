# Simple App (Prometheus Demo)

A minimal Flask app exposing Prometheus metrics for testing Grafana dashboards and EKS monitoring.

## Build & Push
```bash
cd docker/simple-app
docker build -t shanjing/simple-app:dev-v1.0.0 .
docker push shanjing/simple-app:dev-v1.0.0

## Local Test
docker run -p 8080:8080 shanjing/simple-app:dev-v1.0.0
curl localhost:8080/
curl localhost:8080/slow
curl localhost:8080/error
curl localhost:8080/metrics | grep app_


