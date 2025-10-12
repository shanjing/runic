#!/bin/bash

# Kafka Partitions and Consumer Groups Demo
# This script demonstrates how partitions work with multiple consumers

set -e

TOPIC_NAME="partition-demo-$(date +%s)"
GROUP_NAME="partition-group-$(date +%s)"

echo "=========================================="
echo "Kafka Partitions Demo"
echo "Topic: $TOPIC_NAME"
echo "Group: $GROUP_NAME"
echo "=========================================="

# Function to wait for Kafka to be ready
wait_for_kafka() {
    echo "Waiting for Kafka to be ready..."
    until docker run --rm --network kafka_default confluentinc/cp-kafka:7.4.0 kafka-topics --bootstrap-server kafka:29092 --list > /dev/null 2>&1; do
        sleep 2
    done
    echo "Kafka is ready!"
}

# Function to cleanup
cleanup() {
    echo "Cleaning up..."
    docker stop $(docker ps -q --filter "name=consumer-") > /dev/null 2>&1 || true
    docker run --rm --network kafka_default confluentinc/cp-kafka:7.4.0 kafka-topics --bootstrap-server kafka:29092 --delete --topic "$TOPIC_NAME" > /dev/null 2>&1 || true
    echo "Cleanup complete!"
}

# Set trap to cleanup on exit
trap cleanup EXIT

# Wait for Kafka
wait_for_kafka

echo ""
echo "1. Creating topic with 3 partitions:"
docker run --rm --network kafka_default confluentinc/cp-kafka:7.4.0 kafka-topics --bootstrap-server kafka:29092 --create --topic "$TOPIC_NAME" --partitions 3 --replication-factor 1

echo ""
echo "2. Describing topic to see partitions:"
docker run --rm --network kafka_default confluentinc/cp-kafka:7.4.0 kafka-topics --bootstrap-server kafka:29092 --describe --topic "$TOPIC_NAME"

echo ""
echo "3. Starting 3 consumers in the same consumer group..."
echo "   This will demonstrate partition assignment and load balancing"

# Start 3 consumers in the same group
docker run --rm --network kafka_default --name "consumer-1" -d confluentinc/cp-kafka:7.4.0 kafka-console-consumer --bootstrap-server kafka:29092 --topic "$TOPIC_NAME" --group "$GROUP_NAME" --from-beginning
docker run --rm --network kafka_default --name "consumer-2" -d confluentinc/cp-kafka:7.4.0 kafka-console-consumer --bootstrap-server kafka:29092 --topic "$TOPIC_NAME" --group "$GROUP_NAME" --from-beginning
docker run --rm --network kafka_default --name "consumer-3" -d confluentinc/cp-kafka:7.4.0 kafka-console-consumer --bootstrap-server kafka:29092 --topic "$TOPIC_NAME" --group "$GROUP_NAME" --from-beginning

echo ""
echo "4. Sending messages with partition keys (same key goes to same partition):"
echo "   Sending 15 messages with keys A, B, C (5 each)"

for i in {1..5}; do
    echo "Message A-$i" | docker run --rm --network kafka_default confluentinc/cp-kafka:7.4.0 kafka-console-producer --bootstrap-server kafka:29092 --topic "$TOPIC_NAME" --property "parse.key=true" --property "key.separator=:"
done

for i in {1..5}; do
    echo "Message B-$i" | docker run --rm --network kafka_default confluentinc/cp-kafka:7.4.0 kafka-console-producer --bootstrap-server kafka:29092 --topic "$TOPIC_NAME" --property "parse.key=true" --property "key.separator=:"
done

for i in {1..5}; do
    echo "Message C-$i" | docker run --rm --network kafka_default confluentinc/cp-kafka:7.4.0 kafka-console-producer --bootstrap-server kafka:29092 --topic "$TOPIC_NAME" --property "parse.key=true" --property "key.separator=:"
done

echo ""
echo "5. Waiting for messages to be processed..."
sleep 10

echo ""
echo "6. Checking consumer group assignment:"
docker run --rm --network kafka_default confluentinc/cp-kafka:7.4.0 kafka-consumer-groups --bootstrap-server kafka:29092 --describe --group "$GROUP_NAME"

echo ""
echo "7. Stopping one consumer to see rebalancing..."
docker stop consumer-1

echo ""
echo "8. Sending more messages after rebalancing:"
for i in {6..10}; do
    echo "Message D-$i" | docker run --rm --network kafka_default confluentinc/cp-kafka:7.4.0 kafka-console-producer --bootstrap-server kafka:29092 --topic "$TOPIC_NAME" --property "parse.key=true" --property "key.separator=:"
done

echo ""
echo "9. Waiting for rebalancing..."
sleep 5

echo ""
echo "10. Checking consumer group after rebalancing:"
docker run --rm --network kafka_default confluentinc/cp-kafka:7.4.0 kafka-consumer-groups --bootstrap-server kafka:29092 --describe --group "$GROUP_NAME"

echo ""
echo "=========================================="
echo "Partitions Demo completed!"
echo "Key learnings:"
echo "- Messages with same key go to same partition"
echo "- Consumers in same group share partitions"
echo "- When consumer leaves, partitions are rebalanced"
echo "=========================================="

