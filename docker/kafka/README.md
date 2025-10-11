# Local Kafka Setup

This directory contains Docker Compose configuration for running a multi-broker Kafka cluster locally on macOS.

## Services

- **Zookeeper** (Port 2181) - Required for Kafka coordination
- **Kafka Brokers** (Ports 9092, 9093) - Multi-broker Kafka cluster
- **Kafka UI** (Port 8080) - Web interface for managing Kafka topics, messages, and clusters

## Quick Start

1. **Start the 2-broker Kafka cluster:**

   ```bash
   cd docker/kafka
   docker compose up -d
   ```

2. **Access Kafka UI:**

   - Open your browser and go to: http://localhost:8080
   - You can view topics, messages, and manage your Kafka cluster

3. **Connect to Kafka:**
   - Bootstrap servers: `localhost:9092,localhost:9093`
   - Zookeeper: `localhost:2181`

## Stop Services

```bash
docker compose down
```

## Stop and Remove Data

```bash
docker compose down -v
```

## Configuration Details

### Kafka Cluster Configuration

- **Broker 1**: ID 1, Port 9092, JMX 9101
- **Broker 2**: ID 2, Port 9093, JMX 9102
- **Replication Factor**: 2 (fault tolerant)
- **Auto-create topics**: Enabled
- **Delete topics**: Enabled
- **Bootstrap Servers**: kafka1:29092,kafka2:29093

### Kafka UI Features

- Topic management
- Message browsing
- Consumer group monitoring
- Schema registry support
- Cluster health monitoring

## Development Workflow

1. Start the local Kafka cluster
2. Develop and test your Kafka applications
3. Use the UI to monitor topics and messages
4. Stop the cluster when done

## Testing Scripts

This directory includes several scripts to help you test and manage your Kafka cluster:

### Basic Operations

- **`kafka-topics.sh`** - Manage topics with replication
- **`kafka-producer.sh`** - Send messages to cluster
- **`kafka-consumer.sh`** - Consume messages from cluster
- **`test-kafka.sh`** - Test multi-broker cluster functionality
- **`kafka-config.sh`** - Cluster configuration management

### Configuration

All scripts use a centralized configuration approach. To add/remove brokers:

1. **Update the BOOTSTRAP_SERVERS variable** in each script:

   ```bash
   BOOTSTRAP_SERVERS="kafka1:29092,kafka2:29093,kafka3:29094"
   ```

2. **Or use the configuration file**:
   ```bash
   source kafka-config.sh
   ```

**Examples:**

- **Single broker**: `"kafka:29092"`
- **2 brokers**: `"kafka1:29092,kafka2:29093"`
- **3 brokers**: `"kafka1:29092,kafka2:29093,kafka3:29094"`
- **5 brokers**: `"kafka1:29092,kafka2:29093,kafka3:29094,kafka4:29095,kafka5:29096"`

### Advanced Demos

- **`kafka-partitions-demo.sh`** - Demonstrate partitions and consumer group behavior
- **`kafka-avro-demo.sh`** - Show Avro schema registry integration
- **`kafka-streams-demo.sh`** - Demonstrate Kafka Streams concepts
- **`kafka-connect-demo.sh`** - Show Kafka Connect framework
- **`kafka-monitoring.sh`** - Demonstrate monitoring and metrics

### Usage Examples

````bash
# List all topics
./kafka-topics.sh list

# Create a new topic
./kafka-topics.sh create my-topic 3 2

# Send messages to a topic
./kafka-producer.sh my-topic

# Consume messages from a topic
./kafka-consumer.sh my-topic --from-beginning

# Run comprehensive test
./test-kafka.sh

# Run advanced demos
./kafka-partitions-demo.sh    # Partitions and consumer groups
./kafka-streams-demo.sh       # Stream processing concepts
./kafka-monitoring.sh         # Monitoring and metrics

### Quick Test
Run the comprehensive test script to verify everything is working:
```bash
./test-kafka.sh
````

## Next Steps

This 2-broker cluster provides fault tolerance and high availability. For production deployment, this setup can be extended to a multi-node cluster deployed on EC2 using Terraform in the `terraform/` directory.
