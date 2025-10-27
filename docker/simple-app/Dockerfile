FROM python:3.11-slim

WORKDIR /app
COPY app.py .

# Install dependencies
RUN pip install --no-cache-dir flask prometheus_client

EXPOSE 8080
CMD ["python", "app.py"]
