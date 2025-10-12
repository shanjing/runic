#!/bin/bash

# Test Script for Multi-Broker Kafka Cluster
# This script demonstrates the multi-broker cluster functionality

set -e

# Configuration - Update this variable to add/remove brokers
BOOTSTRAP_SERVERS="kafka1:29092,kafka2:29093"

TOPIC_NAME="test-multibroker-$(date +%s)"
GROUP_NAME="test-group-$(date +%s)"

echo "=========================================="
echo "Multi-Broker Kafka Cluster Test"
echo "Topic: $TOPIC_NAME"
echo "Group: $GROUP_NAME"
echo "Bootstrap Servers: $BOOTSTRAP_SERVERS"
echo "=========================================="

# Function to wait for Kafka to be ready
wait_for_kafka() {
    echo "Waiting for Kafka cluster to be ready..."
    until docker run --rm --network kafka_default confluentinc/cp-kafka:7.4.0 kafka-topics --bootstrap-server "$BOOTSTRAP_SERVERS" --list > /dev/null 2>&1; do
        sleep 2
    done
    echo "Kafka cluster is ready!"
}

# Function to cleanup
cleanup() {
    echo "Cleaning up..."
    docker stop $(docker ps -q --filter "name=consumer-") > /dev/null 2>&1 || true
    docker run --rm --network kafka_default confluentinc/cp-kafka:7.4.0 kafka-topics --bootstrap-server "$BOOTSTRAP_SERVERS" --delete --topic "$TOPIC_NAME" > /dev/null 2>&1 || true
    echo "Cleanup complete!"
}

# Set trap to cleanup on exit
trap cleanup EXIT

# Wait for Kafka
wait_for_kafka

echo ""
echo "1. Creating topic with 2 partitions and replication factor 2:"
docker run --rm --network kafka_default confluentinc/cp-kafka:7.4.0 kafka-topics --bootstrap-server "$BOOTSTRAP_SERVERS" --create --topic "$TOPIC_NAME" --partitions 2 --replication-factor 2

echo ""
echo "2. Describing topic to see partition distribution:"
docker run --rm --network kafka_default confluentinc/cp-kafka:7.4.0 kafka-topics --bootstrap-server "$BOOTSTRAP_SERVERS" --describe --topic "$TOPIC_NAME"

echo ""
echo "3. Starting consumer to monitor messages..."
docker run --rm --network kafka_default --name "consumer-multibroker" -d confluentinc/cp-kafka:7.4.0 kafka-console-consumer --bootstrap-server "$BOOTSTRAP_SERVERS" --topic "$TOPIC_NAME" --group "$GROUP_NAME" --from-beginning

echo ""
echo "4. Sending test messages to demonstrate load balancing..."

# Send messages with different partition keys
echo "Message A-1" | docker run --rm --network kafka_default confluentinc/cp-kafka:7.4.0 kafka-console-producer --bootstrap-server "$BOOTSTRAP_SERVERS" --topic "$TOPIC_NAME" --property "parse.key=true" --property "key.separator=:" --property "key=key1"
echo "Message A-2" | docker run --rm --network kafka_default confluentinc/cp-kafka:7.4.0 kafka-console-producer --bootstrap-server "$BOOTSTRAP_SERVERS" --topic "$TOPIC_NAME" --property "parse.key=true" --property "key.separator=:" --property "key=key1"
echo "Message B-1" | docker run --rm --network kafka_default confluentinc/cp-kafka:7.4.0 kafka-console-producer --bootstrap-server "$BOOTSTRAP_SERVERS" --topic "$TOPIC_NAME" --property "parse.key=true" --property "key.separator=:" --property "key=key2"
echo "Message B-2" | docker run --rm --network kafka_default confluentinc/cp-kafka:7.4.0 kafka-console-producer --bootstrap-server "$BOOTSTRAP_SERVERS" --topic "$TOPIC_NAME" --property "parse.key=true" --property "key.separator=:" --property "key=key2"
echo "Message C-1" | docker run --rm --network kafka_default confluentinc/cp-kafka:7.4.0 kafka-console-producer --bootstrap-server "$BOOTSTRAP_SERVERS" --topic "$TOPIC_NAME" --property "parse.key=true" --property "key.separator=:" --property "key=key3"

echo ""
echo "5. Waiting for messages to be processed..."
sleep 5

echo ""
echo "6. Checking consumer group:"
docker run --rm --network kafka_default confluentinc/cp-kafka:7.4.0 kafka-consumer-groups --bootstrap-server "$BOOTSTRAP_SERVERS" --describe --group "$GROUP_NAME"

echo ""
echo "7. Cluster Information:"
echo "   - Broker 1: kafka1:29092 (localhost:9092)"
echo "   - Broker 2: kafka2:29093 (localhost:9093)"
echo "   - Zookeeper: zookeeper:2181 (localhost:2181)"
echo "   - Kafka UI: http://localhost:8080"

echo ""
echo "8. Key Benefits of Multi-Broker Cluster:"
echo "   - Fault tolerance: If one broker fails, others continue"
echo "   - Replication: Each partition has multiple replicas"
echo "   - Load distribution: Messages distributed across brokers"
echo "   - Higher availability: Cluster remains operational with broker failures"
echo "   - Scalability: Easy to add/remove brokers by updating BOOTSTRAP_SERVERS"

echo ""
echo "=========================================="
echo "Multi-Broker Cluster Test completed!"
echo "Check Kafka UI at http://localhost:8080"
echo "=========================================="
