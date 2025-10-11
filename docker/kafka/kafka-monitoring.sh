#!/bin/bash

# Kafka Monitoring and Metrics Demo
# This script demonstrates how to monitor Kafka cluster health

set -e

echo "=========================================="
echo "Kafka Monitoring and Metrics Demo"
echo "=========================================="

# Function to wait for Kafka to be ready
wait_for_kafka() {
    echo "Waiting for Kafka to be ready..."
    until docker run --rm --network kafka_default confluentinc/cp-kafka:7.4.0 kafka-topics --bootstrap-server kafka:29092 --list > /dev/null 2>&1; do
        sleep 2
    done
    echo "Kafka is ready!"
}

# Wait for Kafka
wait_for_kafka

echo ""
echo "1. Basic Cluster Health Check:"
echo "================================"

echo ""
echo "a) List all topics:"
docker run --rm --network kafka_default confluentinc/cp-kafka:7.4.0 kafka-topics --bootstrap-server kafka:29092 --list

echo ""
echo "b) Describe broker configuration:"
docker run --rm --network kafka_default confluentinc/cp-kafka:7.4.0 kafka-broker-api-versions --bootstrap-server kafka:29092

echo ""
echo "2. Consumer Group Monitoring:"
echo "=============================="

echo ""
echo "a) List all consumer groups:"
docker run --rm --network kafka_default confluentinc/cp-kafka:7.4.0 kafka-consumer-groups --bootstrap-server kafka:29092 --list

echo ""
echo "3. Topic Monitoring:"
echo "===================="

echo ""
echo "a) Get detailed topic information:"
if [ "$(docker run --rm --network kafka_default confluentinc/cp-kafka:7.4.0 kafka-topics --bootstrap-server kafka:29092 --list | wc -l)" -gt 0 ]; then
    FIRST_TOPIC=$(docker run --rm --network kafka_default confluentinc/cp-kafka:7.4.0 kafka-topics --bootstrap-server kafka:29092 --list | head -1)
    echo "Describing topic: $FIRST_TOPIC"
    docker run --rm --network kafka_default confluentinc/cp-kafka:7.4.0 kafka-topics --bootstrap-server kafka:29092 --describe --topic "$FIRST_TOPIC"
else
    echo "No topics found to describe"
fi

echo ""
echo "4. Log Monitoring:"
echo "=================="

echo ""
echo "a) Kafka broker logs:"
echo "docker logs kafka --tail 20"

echo ""
echo "b) Zookeeper logs:"
echo "docker logs zookeeper --tail 20"

echo ""
echo "5. JMX Metrics (if enabled):"
echo "============================"

echo ""
echo "Kafka exposes JMX metrics on port 9101"
echo "You can connect using JConsole or other JMX tools:"
echo "  Host: localhost"
echo "  Port: 9101"
echo ""

echo "6. Key Metrics to Monitor:"
echo "=========================="

echo ""
echo "a) Broker Metrics:"
echo "   - Under-replicated partitions"
echo "   - Offline partitions"
echo "   - Active controller count"
echo "   - Request queue size"
echo ""

echo "b) Topic Metrics:"
echo "   - Messages per second"
echo "   - Bytes in/out per second"
echo "   - Replication lag"
echo "   - Consumer lag"
echo ""

echo "c) Consumer Group Metrics:"
echo "   - Consumer lag per partition"
echo "   - Consumer group status"
echo "   - Rebalancing events"
echo ""

echo "7. Monitoring Tools:"
echo "===================="

echo ""
echo "a) Built-in Tools:"
echo "   - kafka-topics: Topic management and monitoring"
echo "   - kafka-consumer-groups: Consumer group monitoring"
echo "   - kafka-broker-api-versions: API compatibility"
echo ""

echo "b) External Tools:"
echo "   - Prometheus + Grafana"
echo "   - Confluent Control Center"
echo "   - Kafka Manager (CMAK)"
echo "   - Burrow (Consumer lag monitoring)"
echo ""

echo "8. Health Check Commands:"
echo "========================="

echo ""
echo "Quick health check script:"
cat << 'EOF'
#!/bin/bash
echo "=== Kafka Health Check ==="

# Check if Kafka is responding
echo "1. Kafka connectivity:"
docker run --rm --network kafka_default confluentinc/cp-kafka:7.4.0 kafka-topics --bootstrap-server kafka:29092 --list > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "   ✓ Kafka is responding"
else
    echo "   ✗ Kafka is not responding"
    exit 1
fi

# Check topics
echo "2. Topics:"
TOPIC_COUNT=$(docker run --rm --network kafka_default confluentinc/cp-kafka:7.4.0 kafka-topics --bootstrap-server kafka:29092 --list | wc -l)
echo "   Found $TOPIC_COUNT topics"

# Check consumer groups
echo "3. Consumer Groups:"
GROUP_COUNT=$(docker run --rm --network kafka_default confluentinc/cp-kafka:7.4.0 kafka-consumer-groups --bootstrap-server kafka:29092 --list | wc -l)
echo "   Found $GROUP_COUNT consumer groups"

# Check container status
echo "4. Container Status:"
docker ps --filter "name=kafka" --format "table {{.Names}}\t{{.Status}}"

echo "=== Health Check Complete ==="
EOF

echo ""
echo "9. Alerting Setup:"
echo "=================="

echo ""
echo "Common alerting scenarios:"
echo "  - Consumer lag > threshold"
echo "  - Under-replicated partitions > 0"
echo "  - Offline partitions > 0"
echo "  - Broker down"
echo "  - Disk space low"
echo ""

echo "=========================================="
echo "Monitoring Demo completed!"
echo "Key monitoring areas:"
echo "- Cluster health and connectivity"
echo "- Topic and partition status"
echo "- Consumer group lag"
echo "- Performance metrics"
echo "=========================================="



