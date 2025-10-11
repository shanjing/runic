#!/bin/bash

# Payment Message Demo
# This script demonstrates real-time payment processing with the defined message format

set -e

TOPIC_NAME="payment"
GROUP_NAME="payment-processor-$(date +%s)"

echo "=========================================="
echo "Payment Message Processing Demo"
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
    docker stop $(docker ps -q --filter "name=payment-consumer-") > /dev/null 2>&1 || true
    echo "Cleanup complete!"
}

# Set trap to cleanup on exit
trap cleanup EXIT

# Wait for Kafka
wait_for_kafka

echo ""
echo "1. Starting payment processor consumer..."
docker run --rm --network kafka_default --name "payment-consumer-1" -d confluentinc/cp-kafka:7.4.0 kafka-console-consumer --bootstrap-server kafka:29092 --topic "$TOPIC_NAME" --group "$GROUP_NAME" --from-beginning

echo ""
echo "2. Sending sample payment messages..."

# Sample payment message 1: P2P Transfer
echo '{"message_id":"pay_1234567890_abcdef","transaction_id":"txn_20241201_001234","timestamp":"2024-12-01T10:30:45.123Z","payment_type":"P2P_TRANSFER","status":"PENDING","sender":{"user_id":"user_12345","account_id":"acc_67890","phone":"+1234567890","email":"alice@example.com"},"recipient":{"user_id":"user_67890","account_id":"acc_12345","phone":"+0987654321","email":"bob@example.com"},"amount":{"value":100.50,"currency":"USD","fees":0.50,"total":101.00},"metadata":{"memo":"Lunch payment","category":"FOOD","tags":["personal"],"reference":"LUNCH-001"},"security":{"signature":"sha256_hash_123","encryption_key_id":"key_20241201_001","verification_code":"123456"},"routing":{"partition_key":"user_12345","priority":"NORMAL","ttl_seconds":300}}' | docker run --rm --network kafka_default confluentinc/cp-kafka:7.4.0 kafka-console-producer --bootstrap-server kafka:29092 --topic "$TOPIC_NAME" --property "parse.key=true" --property "key.separator=:"

# Sample payment message 2: Payment Request
echo '{"message_id":"pay_1234567891_ghijkl","transaction_id":"txn_20241201_001235","timestamp":"2024-12-01T10:31:15.456Z","payment_type":"REQUEST_PAYMENT","status":"PENDING","sender":{"user_id":"user_67890","account_id":"acc_12345","phone":"+0987654321","email":"bob@example.com"},"recipient":{"user_id":"user_12345","account_id":"acc_67890","phone":"+1234567890","email":"alice@example.com"},"amount":{"value":25.00,"currency":"USD","fees":0.25,"total":25.25},"metadata":{"memo":"Coffee payment","category":"FOOD","tags":["urgent"],"reference":"COFFEE-002"},"security":{"signature":"sha256_hash_456","encryption_key_id":"key_20241201_001","verification_code":"654321"},"routing":{"partition_key":"user_67890","priority":"HIGH","ttl_seconds":180}}' | docker run --rm --network kafka_default confluentinc/cp-kafka:7.4.0 kafka-console-producer --bootstrap-server kafka:29092 --topic "$TOPIC_NAME" --property "parse.key=true" --property "key.separator=:"

# Sample payment message 3: Payment Confirmation
echo '{"message_id":"pay_1234567892_mnopqr","transaction_id":"txn_20241201_001236","timestamp":"2024-12-01T10:32:00.789Z","payment_type":"PAYMENT_CONFIRMATION","status":"COMPLETED","sender":{"user_id":"user_12345","account_id":"acc_67890","phone":"+1234567890","email":"alice@example.com"},"recipient":{"user_id":"user_67890","account_id":"acc_12345","phone":"+0987654321","email":"bob@example.com"},"amount":{"value":100.50,"currency":"USD","fees":0.50,"total":101.00},"metadata":{"memo":"Lunch payment confirmed","category":"FOOD","tags":["personal","completed"],"reference":"LUNCH-001"},"security":{"signature":"sha256_hash_789","encryption_key_id":"key_20241201_001","verification_code":"789012"},"routing":{"partition_key":"user_12345","priority":"NORMAL","ttl_seconds":300}}' | docker run --rm --network kafka_default confluentinc/cp-kafka:7.4.0 kafka-console-producer --bootstrap-server kafka:29092 --topic "$TOPIC_NAME" --property "parse.key=true" --property "key.separator=:"

echo ""
echo "3. Payment Message Format Explained:"
echo "===================================="
echo ""
echo "Key Components:"
echo "  • message_id: Unique identifier for tracking"
echo "  • transaction_id: Business transaction ID"
echo "  • payment_type: P2P_TRANSFER, REQUEST_PAYMENT, etc."
echo "  • status: PENDING, PROCESSING, COMPLETED, etc."
echo "  • sender/recipient: User and account details"
echo "  • amount: Payment value, currency, fees"
echo "  • metadata: Memo, category, tags, reference"
echo "  • security: Digital signature, encryption, 2FA"
echo "  • routing: Partition key, priority, TTL"
echo ""

echo "4. Real-time Processing Benefits:"
echo "================================="
echo ""
echo "  • Partition Key: Ensures related payments go to same partition"
echo "  • Priority Levels: URGENT payments processed first"
echo "  • TTL: Automatic message expiration"
echo "  • Status Tracking: Real-time payment status updates"
echo "  • Security: Digital signatures and encryption"
echo ""

echo "5. Processing Workflow:"
echo "======================="
echo ""
echo "  1. Payment Initiated → PENDING status"
echo "  2. Fraud Check → PROCESSING status"
echo "  3. Balance Verification → PROCESSING status"
echo "  4. Funds Transfer → COMPLETED status"
echo "  5. Notification Sent → COMPLETED status"
echo ""

echo "6. Consumer Group Benefits:"
echo "==========================="
echo ""
echo "  • Multiple processors can handle payments in parallel"
echo "  • Automatic load balancing across partitions"
echo "  • Fault tolerance - if one processor fails, others continue"
echo "  • Scalability - add more processors as needed"
echo ""

echo "7. Checking consumer group:"
docker run --rm --network kafka_default confluentinc/cp-kafka:7.4.0 kafka-consumer-groups --bootstrap-server kafka:29092 --describe --group "$GROUP_NAME"

echo ""
echo "=========================================="
echo "Payment Demo completed!"
echo "Key learnings:"
echo "- Structured message format for payments"
echo "- Real-time processing with Kafka"
echo "- Partition key strategy for ordering"
echo "- Consumer group for scalability"
echo "=========================================="



