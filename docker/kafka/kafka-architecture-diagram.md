# Kafka Cluster Logical Architecture

## 2-Broker Cluster Setup (Production Ready)

## 2-Broker Cluster Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        KAFKA CLUSTER (2 Brokers)                           │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐         │
│  │   ZOOKEEPER     │    │   KAFKA UI      │    │   MONITORING    │         │
│  │   (Port 2181)   │    │   (Port 8080)   │    │   (Port 9101/2) │         │
│  │                 │    │                 │    │                 │         │
│  │ • Coordination  │    │ • Web Interface │    │ • JMX Metrics   │         │
│  │ • Leader Election│    │ • Topic Mgmt    │    │ • Performance   │         │
│  │ • Metadata      │    │ • Message Browse│    │ • Health Check  │         │
│  │ • Configuration │    │ • Consumer Mgmt │    │ • Alerts        │         │
│  └─────────────────┘    └─────────────────┘    └─────────────────┘         │
│           │                       │                       │                 │
│           └───────────────────────┼───────────────────────┘                 │
│                                   │                                         │
│  ┌─────────────────────────────────┼─────────────────────────────────────────┐
│  │                         KAFKA BROKERS                                    │
│  │                                                                           │
│  ┌─────────────────┐    ┌─────────────────┐                                │
│  │   BROKER 1      │    │   BROKER 2      │                                │
│  │   (Leader)      │    │   (Follower)    │                                │
│  │   Port 9092     │    │   Port 9093     │                                │
│  │   JMX: 9101     │    │   JMX: 9102     │                                │
│  │                 │    │                 │                                │
│  │ • Topic A (P0)  │    │ • Topic A (P1)  │                                │
│  │ • Topic B (P0)  │    │ • Topic B (P1)  │                                │
│  │ • Topic C (P0)  │    │ • Topic C (P1)  │                                │
│  │ • Replicas      │    │ • Replicas      │                                │
│  │ • Leader        │    │ • Follower      │                                │
│  └─────────────────┘    └─────────────────┘                                │
│           │                       │                                         │
│           └───────────────────────┼─────────────────────────────────────────┘
│                                   │                                         │
│  ┌─────────────────────────────────┼─────────────────────────────────────────┐
│  │                      BOOTSTRAP SERVERS                                   │
│  │                                                                           │
│  │  • Primary: kafka1:29092,kafka2:29093                                    │
│  │  • External: localhost:9092,localhost:9093                               │
│  │  • Monitoring: localhost:9101,localhost:9102                             │
│  └─────────────────────────────────┴─────────────────────────────────────────┘
│
└─────────────────────────────────────────────────────────────────────────────┘

                    │
                    ▼
        ┌─────────────────────────────────────────┐
        │           CLIENT CONNECTIONS            │
        │                                         │
        │  ┌─────────────┐  ┌─────────────┐      │
        │  │  PRODUCERS  │  │  CONSUMERS  │      │
        │  │             │  │             │      │
        │  │ • Apps      │  │ • Apps      │      │
        │  │ • Services  │  │ • Services  │      │
        │  │ • Streams   │  │ • Streams   │      │
        │  └─────────────┘  └─────────────┘      │
        │                                         │
        │  ┌─────────────┐  ┌─────────────┐      │
        │  │ ADMIN TOOLS │  │ MONITORING  │      │
        │  │             │  │             │      │
        │  │ • CLI       │  │ • Prometheus│      │
        │  │ • UI        │  │ • Grafana   │      │
        │  │ • Scripts   │  │ • Alerts    │      │
        │  └─────────────┘  └─────────────┘      │
        └─────────────────────────────────────────┘
```

                    │
                    ▼
        ┌─────────────────────────────────────────┐
        │           CLIENT CONNECTIONS            │
        │                                         │
        │  ┌─────────────┐  ┌─────────────┐      │
        │  │  PRODUCERS  │  │  CONSUMERS  │      │
        │  │             │  │             │      │
        │  │ • Apps      │  │ • Apps      │      │
        │  │ • Services  │  │ • Services  │      │
        │  │ • Streams   │  │ • Streams   │      │
        │  └─────────────┘  └─────────────┘      │
        │                                         │
        │  ┌─────────────┐  ┌─────────────┐      │
        │  │ ADMIN TOOLS │  │ MONITORING  │      │
        │  │             │  │             │      │
        │  │ • CLI       │  │ • Prometheus│      │
        │  │ • UI        │  │ • Grafana   │      │
        │  │ • Scripts   │  │ • Alerts    │      │
        │  └─────────────┘  └─────────────┘      │
        └─────────────────────────────────────────┘

```

## Key Components Explained

### **Zookeeper (Coordination Layer)**

- **Purpose**: Cluster coordination, leader election, metadata storage
- **Nodes**: 3 nodes for quorum (minimum for production)
- **Port**: 2181 (client), 2888 (peer), 3888 (leader election)

### **Kafka Brokers (Data Layer)**

- **Purpose**: Message storage, topic management, partition handling
- **Nodes**: 3+ nodes for fault tolerance
- **Port**: 9092 (client), 9101 (JMX monitoring)
- **Replication**: Each partition replicated across multiple brokers

### **Bootstrap Servers**

- **Purpose**: Client discovery and connection points
- **Format**: `broker1:9092,broker2:9092,broker3:9092`
- **Load Balancing**: Clients automatically distribute across brokers

### **Client Connections**

- **Producers**: Send messages to topics
- **Consumers**: Read messages from topics
- **Admin Tools**: Manage topics, partitions, configurations
- **Monitoring**: Track cluster health and performance

## Scaling Considerations

### **Horizontal Scaling**

- Add more brokers for increased throughput
- Add more partitions for parallel processing
- Add more consumers for higher consumption rates

### **Vertical Scaling**

- Increase broker resources (CPU, memory, disk)
- Optimize JVM settings
- Use faster storage (SSD, NVMe)

### **High Availability**

- Minimum 3 Zookeeper nodes
- Minimum 3 Kafka brokers
- Replication factor of 3 for critical topics
- Cross-zone/region deployment for disaster recovery
```
