#!/bin/bash

# Kafka Cluster Configuration
# Update this file to configure your Kafka cluster

# Bootstrap Servers Configuration
# Format: "broker1:port1,broker2:port2,broker3:port3"
# Examples:
#   - Single broker: "kafka:29092"
#   - 2 brokers: "kafka1:29092,kafka2:29093"
#   - 3 brokers: "kafka1:29092,kafka2:29093,kafka3:29094"
#   - 5 brokers: "kafka1:29092,kafka2:29093,kafka3:29094,kafka4:29095,kafka5:29096"

export KAFKA_BOOTSTRAP_SERVERS="kafka1:29092,kafka2:29093"

# Default Replication Factor
# Should be <= number of brokers for fault tolerance
export KAFKA_DEFAULT_REPLICATION_FACTOR=2

# Default Number of Partitions
export KAFKA_DEFAULT_PARTITIONS=2

# Network Configuration
export KAFKA_DOCKER_NETWORK="kafka_default"

# Kafka Version
export KAFKA_VERSION="confluentinc/cp-kafka:7.4.0"

# Kafka UI Configuration
export KAFKA_UI_PORT=8080

# JMX Ports (for monitoring)
export KAFKA_JMX_PORTS="9101,9102"

echo "Kafka Cluster Configuration:"
echo "  Bootstrap Servers: $KAFKA_BOOTSTRAP_SERVERS"
echo "  Replication Factor: $KAFKA_DEFAULT_REPLICATION_FACTOR"
echo "  Default Partitions: $KAFKA_DEFAULT_PARTITIONS"
echo "  Docker Network: $KAFKA_DOCKER_NETWORK"
echo "  Kafka Version: $KAFKA_VERSION"
echo "  Kafka UI Port: $KAFKA_UI_PORT"
echo "  JMX Ports: $KAFKA_JMX_PORTS"



