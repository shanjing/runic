#!/bin/bash

# Kafka Console Producer Script for Multi-Broker Cluster
# Usage: ./kafka-2brokers-producer.sh <topic-name>

set -e

# Configuration - Update this variable to add/remove brokers
BOOTSTRAP_SERVERS="kafka1:29092,kafka2:29093"

TOPIC_NAME=${1:-"test-topic"}

echo "Starting Kafka Console Producer - Multi-Broker Cluster..."
echo "Topic: $TOPIC_NAME"
echo "Bootstrap Servers: $BOOTSTRAP_SERVERS"
echo "Type your messages and press Enter. Use Ctrl+C to exit."
echo "----------------------------------------"

docker run --rm -it \
  --network kafka_default \
  confluentinc/cp-kafka:7.4.0 \
  kafka-console-producer \
  --bootstrap-server "$BOOTSTRAP_SERVERS" \
  --topic "$TOPIC_NAME"
