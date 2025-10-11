#!/bin/bash

# Kafka Topics Management Script for Multi-Broker Cluster
# Usage: ./kafka-2brokers-topics.sh <command> [options]

set -e

# Configuration - Update this variable to add/remove brokers
BOOTSTRAP_SERVERS="kafka1:29092,kafka2:29093"

COMMAND=${1:-"list"}
TOPIC_NAME=${2:-""}
PARTITIONS=${3:-"2"}
REPLICATION_FACTOR=${4:-"2"}

echo "Kafka Topics Management - Multi-Broker Cluster"
echo "Command: $COMMAND"
echo "Bootstrap Servers: $BOOTSTRAP_SERVERS"
echo "----------------------------------------"

case $COMMAND in
  "list")
    echo "Listing all topics:"
    docker run --rm --network kafka_default confluentinc/cp-kafka:7.4.0 kafka-topics --bootstrap-server "$BOOTSTRAP_SERVERS" --list
    ;;
  "create")
    if [ -z "$TOPIC_NAME" ]; then
      echo "Error: Topic name required for create command"
      echo "Usage: ./kafka-2brokers-topics.sh create <topic-name> [partitions] [replication-factor]"
      exit 1
    fi
    echo "Creating topic: $TOPIC_NAME"
    echo "Partitions: $PARTITIONS"
    echo "Replication Factor: $REPLICATION_FACTOR"
    docker run --rm --network kafka_default confluentinc/cp-kafka:7.4.0 kafka-topics --bootstrap-server "$BOOTSTRAP_SERVERS" --create --topic "$TOPIC_NAME" --partitions "$PARTITIONS" --replication-factor "$REPLICATION_FACTOR"
    ;;
  "describe")
    if [ -z "$TOPIC_NAME" ]; then
      echo "Error: Topic name required for describe command"
      echo "Usage: ./kafka-2brokers-topics.sh describe <topic-name>"
      exit 1
    fi
    echo "Describing topic: $TOPIC_NAME"
    docker run --rm --network kafka_default confluentinc/cp-kafka:7.4.0 kafka-topics --bootstrap-server "$BOOTSTRAP_SERVERS" --describe --topic "$TOPIC_NAME"
    ;;
  "delete")
    if [ -z "$TOPIC_NAME" ]; then
      echo "Error: Topic name required for delete command"
      echo "Usage: ./kafka-2brokers-topics.sh delete <topic-name>"
      exit 1
    fi
    echo "Deleting topic: $TOPIC_NAME"
    docker run --rm --network kafka_default confluentinc/cp-kafka:7.4.0 kafka-topics --bootstrap-server "$BOOTSTRAP_SERVERS" --delete --topic "$TOPIC_NAME"
    ;;
  *)
    echo "Available commands:"
    echo "  list                                    - List all topics"
    echo "  create <topic-name> [partitions] [rf]   - Create a new topic"
    echo "  describe <topic-name>                   - Describe topic details"
    echo "  delete <topic-name>                     - Delete a topic"
    echo ""
    echo "Examples:"
    echo "  ./kafka-2brokers-topics.sh list"
    echo "  ./kafka-2brokers-topics.sh create my-topic 4 2"
    echo "  ./kafka-2brokers-topics.sh describe my-topic"
    echo "  ./kafka-2brokers-topics.sh delete my-topic"
    echo ""
    echo "Note: Default replication factor is 2 for fault tolerance"
    ;;
esac
