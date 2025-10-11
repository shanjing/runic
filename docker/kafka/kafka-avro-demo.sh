#!/bin/bash

# Kafka Avro Schema Registry Demo
# This script demonstrates Kafka with Avro schemas

set -e

TOPIC_NAME="avro-demo-$(date +%s)"
SCHEMA_REGISTRY_URL="http://localhost:8081"

echo "=========================================="
echo "Kafka Avro Schema Registry Demo"
echo "Topic: $TOPIC_NAME"
echo "Schema Registry: $SCHEMA_REGISTRY_URL"
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
echo "Note: This demo requires Schema Registry to be running."
echo "To add Schema Registry to your setup, add this to docker-compose.yml:"
echo ""
echo "  schema-registry:"
echo "    image: confluentinc/cp-schema-registry:7.4.0"
echo "    hostname: schema-registry"
echo "    depends_on:"
echo "      - kafka"
echo "    ports:"
echo "      - \"8081:8081\""
echo "    environment:"
echo "      SCHEMA_REGISTRY_HOST_NAME: schema-registry"
echo "      SCHEMA_REGISTRY_KAFKASTORE_BOOTSTRAP_SERVERS: 'kafka:29092'"
echo ""

echo "1. Creating topic for Avro messages:"
docker run --rm --network kafka_default confluentinc/cp-kafka:7.4.0 kafka-topics --bootstrap-server kafka:29092 --create --topic "$TOPIC_NAME" --partitions 1 --replication-factor 1

echo ""
echo "2. Example Avro schema (user.avsc):"
cat << 'EOF' > user.avsc
{
  "type": "record",
  "name": "User",
  "fields": [
    {"name": "id", "type": "int"},
    {"name": "name", "type": "string"},
    {"name": "email", "type": "string"},
    {"name": "age", "type": "int"}
  ]
}
EOF

echo ""
echo "3. To register schema with Schema Registry:"
echo "curl -X POST -H \"Content-Type: application/vnd.schemaregistry.v1+json\" \\"
echo "  --data '{\"schema\": \"$(cat user.avsc | tr -d '\n' | sed 's/"/\\"/g')\"}' \\"
echo "  http://localhost:8081/subjects/$TOPIC_NAME-value/versions"

echo ""
echo "4. To produce Avro messages (with Schema Registry running):"
echo "docker run --rm --network kafka_default \\"
echo "  -v \$(pwd)/user.avsc:/user.avsc \\"
echo "  confluentinc/cp-kafka-avro-console-producer:7.4.0 \\"
echo "  --bootstrap-server kafka:29092 \\"
echo "  --topic $TOPIC_NAME \\"
echo "  --property value.schema=@/user.avsc \\"
echo "  --property schema.registry.url=http://schema-registry:8081"

echo ""
echo "5. To consume Avro messages (with Schema Registry running):"
echo "docker run --rm --network kafka_default \\"
echo "  confluentinc/cp-kafka-avro-console-consumer:7.4.0 \\"
echo "  --bootstrap-server kafka:29092 \\"
echo "  --topic $TOPIC_NAME \\"
echo "  --from-beginning \\"
echo "  --property schema.registry.url=http://schema-registry:8081"

echo ""
echo "=========================================="
echo "Avro Demo setup completed!"
echo "To enable Avro support, restart docker-compose with Schema Registry"
echo "=========================================="

