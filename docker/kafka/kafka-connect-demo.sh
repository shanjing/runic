#!/bin/bash

# Kafka Connect Demo
# This script demonstrates Kafka Connect concepts

set -e

TOPIC_NAME="connect-demo-$(date +%s)"

echo "=========================================="
echo "Kafka Connect Demo"
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
echo "1. Creating topic for Connect demo:"
docker run --rm --network kafka_default confluentinc/cp-kafka:7.4.0 kafka-topics --bootstrap-server kafka:29092 --create --topic "$TOPIC_NAME" --partitions 1 --replication-factor 1

echo ""
echo "2. Kafka Connect Concepts:"
echo ""
echo "   Kafka Connect is a framework for connecting Kafka with external systems:"
echo "   - Sources: Import data from external systems INTO Kafka"
echo "   - Sinks: Export data FROM Kafka to external systems"
echo ""

echo "3. To add Kafka Connect to your setup, add this to docker-compose.yml:"
echo ""
echo "  kafka-connect:"
echo "    image: confluentinc/cp-kafka-connect:7.4.0"
echo "    hostname: kafka-connect"
echo "    depends_on:"
echo "      - kafka"
echo "    ports:"
echo "      - \"8083:8083\""
echo "    environment:"
echo "      CONNECT_BOOTSTRAP_SERVERS: 'kafka:29092'"
echo "      CONNECT_REST_ADVERTISED_HOST_NAME: kafka-connect"
echo "      CONNECT_REST_PORT: 8083"
echo "      CONNECT_GROUP_ID: kafka-connect-group"
echo "      CONNECT_CONFIG_STORAGE_TOPIC: connect-configs"
echo "      CONNECT_OFFSET_STORAGE_TOPIC: connect-offsets"
echo "      CONNECT_STATUS_STORAGE_TOPIC: connect-status"
echo "      CONNECT_KEY_CONVERTER: org.apache.kafka.connect.storage.StringConverter"
echo "      CONNECT_VALUE_CONVERTER: org.apache.kafka.connect.storage.StringConverter"
echo "      CONNECT_INTERNAL_KEY_CONVERTER: org.apache.kafka.connect.storage.StringConverter"
echo "      CONNECT_INTERNAL_VALUE_CONVERTER: org.apache.kafka.connect.storage.StringConverter"
echo "      CONNECT_LOG4J_ROOT_LOGLEVEL: INFO"
echo "      CONNECT_LOG4J_LOGGERS: org.apache.kafka.connect.runtime.rest=WARN,org.reflections=ERROR"
echo "      CONNECT_PLUGIN_PATH: '/usr/share/java,/usr/share/confluent-hub-components'"
echo ""

echo "4. Example Source Connectors:"
echo ""
echo "   a) File Source Connector:"
echo "      - Reads from files and sends to Kafka topics"
echo "      - Useful for importing log files, CSV data, etc."
echo ""
echo "   b) JDBC Source Connector:"
echo "      - Reads from databases (MySQL, PostgreSQL, etc.)"
echo "      - Can perform change data capture (CDC)"
echo ""
echo "   c) HTTP Source Connector:"
echo "      - Polls HTTP endpoints and sends data to Kafka"
echo "      - Useful for REST APIs"
echo ""

echo "5. Example Sink Connectors:"
echo ""
echo "   a) File Sink Connector:"
echo "      - Writes Kafka messages to files"
echo "      - Useful for data export and backup"
echo ""
echo "   b) JDBC Sink Connector:"
echo "      - Writes Kafka messages to databases"
echo "      - Useful for data warehousing"
echo ""
echo "   c) Elasticsearch Sink Connector:"
echo "      - Indexes Kafka messages in Elasticsearch"
echo "      - Useful for search and analytics"
echo ""

echo "6. Example File Source Connector Configuration:"
echo ""
cat << 'EOF' > file-source-connector.json
{
  "name": "file-source-connector",
  "config": {
    "connector.class": "org.apache.kafka.connect.file.FileStreamSourceConnector",
    "tasks.max": "1",
    "file": "/tmp/test.txt",
    "topic": "file-topic"
  }
}
EOF

echo "7. To create a connector (with Kafka Connect running):"
echo "curl -X POST -H \"Content-Type: application/json\" \\"
echo "  --data @file-source-connector.json \\"
echo "  http://localhost:8083/connectors"
echo ""

echo "8. To list connectors:"
echo "curl -X GET http://localhost:8083/connectors"
echo ""

echo "9. To check connector status:"
echo "curl -X GET http://localhost:8083/connectors/file-source-connector/status"
echo ""

echo "10. To delete a connector:"
echo "curl -X DELETE http://localhost:8083/connectors/file-source-connector"
echo ""

echo "=========================================="
echo "Kafka Connect Demo completed!"
echo "Key concepts demonstrated:"
echo "- Source and Sink connectors"
echo "- Connector configuration"
echo "- REST API for connector management"
echo "=========================================="



