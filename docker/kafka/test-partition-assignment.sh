#!/bin/bash

# Test Partition Assignment
# This script demonstrates how partition keys vs message_id affect partition assignment

set -e

TOPIC_NAME="partition-test-$(date +%s)"

echo "=========================================="
echo "Partition Assignment Test"
echo "Topic: $TOPIC_NAME"
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
    docker run --rm --network kafka_default confluentinc/cp-kafka:7.4.0 kafka-topics --bootstrap-server kafka:29092 --delete --topic "$TOPIC_NAME" > /dev/null 2>&1 || true
    echo "Cleanup complete!"
}

# Set trap to cleanup on exit
trap cleanup EXIT

# Wait for Kafka
wait_for_kafka

echo ""
echo "1. Creating test topic with 3 partitions:"
docker run --rm --network kafka_default confluentinc/cp-kafka:7.4.0 kafka-topics --bootstrap-server kafka:29092 --create --topic "$TOPIC_NAME" --partitions 3 --replication-factor 1

echo ""
echo "2. Testing partition assignment..."

echo ""
echo "Test 1: Same partition_key, different message_id"
echo "Sending 3 messages with partition_key='user_123' but different message_ids..."

# Same partition key, different message IDs
echo '{"message_id":"msg_001","partition_key":"user_123","data":"test1"}' | docker run --rm --network kafka_default confluentinc/cp-kafka:7.4.0 kafka-console-producer --bootstrap-server kafka:29092 --topic "$TOPIC_NAME" --property "parse.key=true" --property "key.separator=:" --property "key=user_123"
echo '{"message_id":"msg_002","partition_key":"user_123","data":"test2"}' | docker run --rm --network kafka_default confluentinc/cp-kafka:7.4.0 kafka-console-producer --bootstrap-server kafka:29092 --topic "$TOPIC_NAME" --property "parse.key=true" --property "key.separator=:" --property "key=user_123"
echo '{"message_id":"msg_003","partition_key":"user_123","data":"test3"}' | docker run --rm --network kafka_default confluentinc/cp-kafka:7.4.0 kafka-console-producer --bootstrap-server kafka:29092 --topic "$TOPIC_NAME" --property "parse.key=true" --property "key.separator=:" --property "key=user_123"

echo ""
echo "Test 2: Same message_id, different partition_key"
echo "Sending 3 messages with message_id='msg_004' but different partition_keys..."

# Same message ID, different partition keys
echo '{"message_id":"msg_004","partition_key":"user_456","data":"test4"}' | docker run --rm --network kafka_default confluentinc/cp-kafka:7.4.0 kafka-console-producer --bootstrap-server kafka:29092 --topic "$TOPIC_NAME" --property "parse.key=true" --property "key.separator=:" --property "key=user_456"
echo '{"message_id":"msg_004","partition_key":"user_789","data":"test5"}' | docker run --rm --network kafka_default confluentinc/cp-kafka:7.4.0 kafka-console-producer --bootstrap-server kafka:29092 --topic "$TOPIC_NAME" --property "parse.key=true" --property "key.separator=:" --property "key=user_789"
echo '{"message_id":"msg_004","partition_key":"user_012","data":"test6"}' | docker run --rm --network kafka_default confluentinc/cp-kafka:7.4.0 kafka-console-producer --bootstrap-server kafka:29092 --topic "$TOPIC_NAME" --property "parse.key=true" --property "key.separator=:" --property "key=user_012"

echo ""
echo "Test 3: No partition key (round-robin)"
echo "Sending 3 messages without partition keys..."

# No partition key (round-robin)
echo '{"message_id":"msg_005","data":"test7"}' | docker run --rm --network kafka_default confluentinc/cp-kafka:7.4.0 kafka-console-producer --bootstrap-server kafka:29092 --topic "$TOPIC_NAME"
echo '{"message_id":"msg_006","data":"test8"}' | docker run --rm --network kafka_default confluentinc/cp-kafka:7.4.0 kafka-console-producer --bootstrap-server kafka:29092 --topic "$TOPIC_NAME"
echo '{"message_id":"msg_007","data":"test9"}' | docker run --rm --network kafka_default confluentinc/cp-kafka:7.4.0 kafka-console-producer --bootstrap-server kafka:29092 --topic "$TOPIC_NAME"

echo ""
echo "3. Consuming messages to see partition assignment..."

# Start consumer to see messages
echo "Starting consumer to show partition assignment..."
docker run --rm --network kafka_default confluentinc/cp-kafka:7.4.0 kafka-console-consumer --bootstrap-server kafka:29092 --topic "$TOPIC_NAME" --from-beginning --property "print.partition=true" --property "print.offset=true" --property "print.timestamp=true" --max-messages 9

echo ""
echo "4. Key Findings:"
echo "================"
echo ""
echo "✅ Same partition_key → Same partition (guaranteed)"
echo "❌ Same message_id → NOT guaranteed same partition"
echo "🔄 No partition key → Round-robin assignment"
echo ""
echo "5. For Payment Processing:"
echo "========================="
echo ""
echo "✅ Use user_id as partition_key for:"
echo "   - Ensuring all payments from same user go to same partition"
echo "   - Maintaining order within user's payment stream"
echo "   - Enabling efficient user-specific processing"
echo ""
echo "❌ Don't rely on message_id for:"
echo "   - Partition assignment"
echo "   - Message ordering"
echo "   - Load balancing"
echo ""
echo "=========================================="
echo "Partition assignment test completed!"
echo "=========================================="



