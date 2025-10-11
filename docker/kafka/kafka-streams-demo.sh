#!/bin/bash

# Kafka Streams Demo
# This script demonstrates Kafka Streams concepts with simple examples

set -e

INPUT_TOPIC="input-topic-$(date +%s)"
OUTPUT_TOPIC="output-topic-$(date +%s)"
WORD_COUNT_TOPIC="word-count-$(date +%s)"

echo "=========================================="
echo "Kafka Streams Demo"
echo "Input Topic: $INPUT_TOPIC"
echo "Output Topic: $OUTPUT_TOPIC"
echo "Word Count Topic: $WORD_COUNT_TOPIC"
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
    docker stop $(docker ps -q --filter "name=streams-") > /dev/null 2>&1 || true
    docker run --rm --network kafka_default confluentinc/cp-kafka:7.4.0 kafka-topics --bootstrap-server kafka:29092 --delete --topic "$INPUT_TOPIC" > /dev/null 2>&1 || true
    docker run --rm --network kafka_default confluentinc/cp-kafka:7.4.0 kafka-topics --bootstrap-server kafka:29092 --delete --topic "$OUTPUT_TOPIC" > /dev/null 2>&1 || true
    docker run --rm --network kafka_default confluentinc/cp-kafka:7.4.0 kafka-topics --bootstrap-server kafka:29092 --delete --topic "$WORD_COUNT_TOPIC" > /dev/null 2>&1 || true
    echo "Cleanup complete!"
}

# Set trap to cleanup on exit
trap cleanup EXIT

# Wait for Kafka
wait_for_kafka

echo ""
echo "1. Creating topics for streams demo:"
docker run --rm --network kafka_default confluentinc/cp-kafka:7.4.0 kafka-topics --bootstrap-server kafka:29092 --create --topic "$INPUT_TOPIC" --partitions 3 --replication-factor 1
docker run --rm --network kafka_default confluentinc/cp-kafka:7.4.0 kafka-topics --bootstrap-server kafka:29092 --create --topic "$OUTPUT_TOPIC" --partitions 3 --replication-factor 1
docker run --rm --network kafka_default confluentinc/cp-kafka:7.4.0 kafka-topics --bootstrap-server kafka:29092 --create --topic "$WORD_COUNT_TOPIC" --partitions 3 --replication-factor 1

echo ""
echo "2. Listing created topics:"
docker run --rm --network kafka_default confluentinc/cp-kafka:7.4.0 kafka-topics --bootstrap-server kafka:29092 --list

echo ""
echo "3. Starting consumers to monitor output topics..."

# Start consumers for output topics
docker run --rm --network kafka_default --name "streams-output-consumer" -d confluentinc/cp-kafka:7.4.0 kafka-console-consumer --bootstrap-server kafka:29092 --topic "$OUTPUT_TOPIC" --group "streams-output-group" --from-beginning
docker run --rm --network kafka_default --name "streams-wordcount-consumer" -d confluentinc/cp-kafka:7.4.0 kafka-console-consumer --bootstrap-server kafka:29092 --topic "$WORD_COUNT_TOPIC" --group "streams-wordcount-group" --from-beginning

echo ""
echo "4. Sending test messages to input topic:"
echo "hello world" | docker run --rm --network kafka_default confluentinc/cp-kafka:7.4.0 kafka-console-producer --bootstrap-server kafka:29092 --topic "$INPUT_TOPIC"
echo "kafka streams demo" | docker run --rm --network kafka_default confluentinc/cp-kafka:7.4.0 kafka-console-producer --bootstrap-server kafka:29092 --topic "$INPUT_TOPIC"
echo "hello kafka" | docker run --rm --network kafka_default confluentinc/cp-kafka:7.4.0 kafka-console-producer --bootstrap-server kafka:29092 --topic "$INPUT_TOPIC"
echo "streams processing" | docker run --rm --network kafka_default confluentinc/cp-kafka:7.4.0 kafka-console-producer --bootstrap-server kafka:29092 --topic "$INPUT_TOPIC"
echo "hello again" | docker run --rm --network kafka_default confluentinc/cp-kafka:7.4.0 kafka-console-producer --bootstrap-server kafka:29092 --topic "$INPUT_TOPIC"

echo ""
echo "5. Kafka Streams Concepts Demonstrated:"
echo ""
echo "   a) Input Topic ($INPUT_TOPIC):"
echo "      - Raw messages: 'hello world', 'kafka streams demo', etc."
echo ""
echo "   b) Stream Processing Examples:"
echo "      - Word Count: Count occurrences of each word"
echo "      - Text Transformation: Convert to uppercase"
echo "      - Filtering: Only process messages containing 'hello'"
echo "      - Windowing: Count words in time windows"
echo ""
echo "   c) Output Topics:"
echo "      - $OUTPUT_TOPIC: Transformed/processed messages"
echo "      - $WORD_COUNT_TOPIC: Word count results"
echo ""

echo "6. To implement actual Kafka Streams processing, you would:"
echo "   - Write Java/Scala code using Kafka Streams API"
echo "   - Define source topics, transformations, and sink topics"
echo "   - Deploy as a Kafka Streams application"
echo ""

echo "7. Example Streams Processing Logic (pseudo-code):"
echo ""
echo "   // Word Count Stream"
echo "   KStream<String, String> textLines = builder.stream(\"$INPUT_TOPIC\");"
echo "   KTable<String, Long> wordCounts = textLines"
echo "       .flatMapValues(value -> Arrays.asList(value.toLowerCase().split(\"\\W+\")))"
echo "       .groupBy((key, word) -> word)"
echo "       .count();"
echo "   wordCounts.toStream().to(\"$WORD_COUNT_TOPIC\");"
echo ""

echo "8. Checking consumer groups:"
docker run --rm --network kafka_default confluentinc/cp-kafka:7.4.0 kafka-consumer-groups --bootstrap-server kafka:29092 --list

echo ""
echo "=========================================="
echo "Kafka Streams Demo completed!"
echo "Key concepts demonstrated:"
echo "- Input/Output topic relationships"
echo "- Stream processing patterns"
echo "- Consumer group monitoring"
echo "=========================================="



