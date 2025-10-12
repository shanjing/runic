#!/bin/bash

# Kafka Console Consumer Script for Multi-Broker Cluster
# Usage: ./kafka-2brokers-consumer.sh <topic-name> [--from-beginning]

set -e

# Configuration - Update this variable to add/remove brokers
BOOTSTRAP_SERVERS="kafka1:29092,kafka2:29093"

TOPIC_NAME=${1:-"test-topic"}
FROM_BEGINNING=${2:-""}

echo "Starting Kafka Console Consumer - Multi-Broker Cluster..."
echo "Topic: $TOPIC_NAME"
echo "Bootstrap Servers: $BOOTSTRAP_SERVERS"
echo "From beginning: $([ -n "$FROM_BEGINNING" ] && echo "Yes" || echo "No")"
echo "Press Ctrl+C to exit."
echo "----------------------------------------"

docker run --rm -it \
  --network kafka_default \
  confluentinc/cp-kafka:7.4.0 \
  kafka-console-consumer \
  --bootstrap-server "$BOOTSTRAP_SERVERS" \
  --topic "$TOPIC_NAME" \
  --group "console-consumer-$(date +%s)" \
  $FROM_BEGINNING
