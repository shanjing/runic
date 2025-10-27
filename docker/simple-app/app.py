from flask import Flask, request
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
import time, random

app = Flask(__name__)

# ---- Prometheus metrics ----
REQUEST_COUNT = Counter(
    "app_requests_total", "Total HTTP requests", ["method", "endpoint"]
)
REQUEST_LATENCY = Histogram(
    "app_request_latency_seconds", "Request latency (seconds)", ["endpoint"]
)
ERROR_COUNT = Counter("app_errors_total", "Total error responses")

# ---- Routes ----
@app.route("/")
def index():
    REQUEST_COUNT.labels(method=request.method, endpoint="/").inc()
    start = time.time()
    time.sleep(random.uniform(0.1, 0.3))  # simulate normal latency
    REQUEST_LATENCY.labels(endpoint="/").observe(time.time() - start)
    return "OK\n"


@app.route("/slow")
def slow():
    REQUEST_COUNT.labels(method=request.method, endpoint="/slow").inc()
    start = time.time()
    time.sleep(random.uniform(2.0, 4.0))  # simulate slow endpoint
    REQUEST_LATENCY.labels(endpoint="/slow").observe(time.time() - start)
    return "SLOW\n"


@app.route("/error")
def error():
    REQUEST_COUNT.labels(method=request.method, endpoint="/error").inc()
    ERROR_COUNT.inc()
    return "ERROR\n", 500


@app.route("/metrics")
def metrics():
    return generate_latest(), 200, {"Content-Type": CONTENT_TYPE_LATEST}


if __name__ == "__main__":
    # Important: use 0.0.0.0 for container networking
    app.run(host="0.0.0.0", port=8080)
