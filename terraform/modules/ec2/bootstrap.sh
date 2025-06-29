#!/bin/bash

# Kubernetes Bootstrap Script for Runic Dev Environment
# This script installs a single-node Kubernetes cluster with containerd and flannel CNI

set -e

echo "🚀 Starting Kubernetes bootstrap process..."

# Update system packages
echo "📦 Updating system packages..."
sudo apt-get update
sudo apt-get upgrade -y

# Install required packages
echo "🔧 Installing required packages..."
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

# Enable IPv4 forwarding
echo "🌐 Enabling IPv4 forwarding..."
echo 'net.ipv4.ip_forward=1' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Load required kernel modules for Flannel
echo "🔧 Loading kernel modules for Flannel..."
sudo modprobe br_netfilter
echo 'br_netfilter' | sudo tee -a /etc/modules-load.d/k8s.conf

# Configure bridge netfilter
echo "🌉 Configuring bridge netfilter..."
echo 'net.bridge.bridge-nf-call-iptables=1' | sudo tee -a /etc/sysctl.conf
echo 'net.bridge.bridge-nf-call-ip6tables=1' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Install containerd
echo "🐳 Installing containerd..."
sudo apt-get install -y containerd

# Configure containerd
echo "⚙️ Configuring containerd..."
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml

# Enable systemd cgroup driver
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

# Restart containerd
sudo systemctl restart containerd
sudo systemctl enable containerd

# Add Kubernetes repository
echo "📚 Adding Kubernetes repository..."
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Update package list
sudo apt-get update

# Install Kubernetes components
echo "⚙️ Installing Kubernetes components..."
sudo apt-get install -y kubelet=1.29.7-1.1 kubeadm=1.29.7-1.1 kubectl=1.29.7-1.1
sudo apt-mark hold kubelet kubeadm kubectl

# Configure kubelet to use containerd
echo "🔧 Configuring kubelet..."
sudo mkdir -p /etc/default
echo 'KUBELET_EXTRA_ARGS=--container-runtime-endpoint=unix:///run/containerd/containerd.sock' | sudo tee /etc/default/kubelet

# Initialize Kubernetes cluster
echo "🎯 Initializing Kubernetes cluster..."
PRIVATE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

echo "🌐 Using Private IP: $PRIVATE_IP for etcd binding"
echo "🌐 Using Public IP: $PUBLIC_IP for API server access"

sudo kubeadm init \
  --pod-network-cidr=10.244.0.0/16 \
  --apiserver-advertise-address=$PRIVATE_IP \
  --apiserver-cert-extra-sans=$PUBLIC_IP,$PRIVATE_IP \
  --node-name=$(hostname) \
  --ignore-preflight-errors=all

# Configure kubectl for current user
echo "🔑 Configuring kubectl..."
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Also create kubeconfig for ubuntu user specifically
echo "🔑 Creating kubeconfig for ubuntu user..."
sudo mkdir -p /home/ubuntu/.kube
sudo cp -i /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
sudo chown ubuntu:ubuntu /home/ubuntu/.kube/config
sudo chmod 600 /home/ubuntu/.kube/config

# Create remote kubeconfig with public IP for external access
echo "🔑 Creating remote kubeconfig with public IP..."
sudo cp -i /etc/kubernetes/admin.conf /home/ubuntu/.kube/config-remote
sudo sed -i "s/$PRIVATE_IP/$PUBLIC_IP/g" /home/ubuntu/.kube/config-remote
sudo chown ubuntu:ubuntu /home/ubuntu/.kube/config-remote
sudo chmod 600 /home/ubuntu/.kube/config-remote

# Verify kubeconfig was created
echo "✅ Verifying kubeconfig creation..."
ls -la /home/ubuntu/.kube/

# Add kubectl alias for ubuntu user
echo "🔧 Adding kubectl alias for ubuntu user..."
echo 'alias k=kubectl' >> /home/ubuntu/.bashrc
echo 'alias k=kubectl' >> /home/ubuntu/.profile

# Add kubectl auto-completion
echo "🔧 Adding kubectl auto-completion..."
echo 'source <(kubectl completion bash)' >> /home/ubuntu/.bashrc
echo 'source <(kubectl completion bash)' >> /home/ubuntu/.profile

# Add k alias completion
echo 'complete -o default -F __start_kubectl k' >> /home/ubuntu/.bashrc
echo 'complete -o default -F __start_kubectl k' >> /home/ubuntu/.profile

chown ubuntu:ubuntu /home/ubuntu/.bashrc /home/ubuntu/.profile

# Install Flannel CNI
echo "🌐 Installing Flannel CNI..."
sudo -u ubuntu kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

# Wait for Flannel to be ready with better error handling
echo "⏳ Waiting for Flannel to be ready..."
echo "📋 Checking Flannel pods status..."

# Function to check Flannel readiness
check_flannel_ready() {
    # Check if Flannel pods exist
    if ! sudo -u ubuntu kubectl get pods -n kube-flannel --no-headers 2>/dev/null | grep -q "kube-flannel-ds"; then
        echo "⚠️  Flannel pods not found yet, waiting..."
        return 1
    fi
    
    # Check if pods are running
    if sudo -u ubuntu kubectl get pods -n kube-flannel --no-headers 2>/dev/null | grep -v "Running" | grep -q "kube-flannel-ds"; then
        echo "⚠️  Some Flannel pods not running yet, waiting..."
        return 1
    fi
    
    # Try the original wait command
    if sudo -u ubuntu kubectl wait --for=condition=ready pod -l app=flannel -n kube-flannel --timeout=60s 2>/dev/null; then
        echo "✅ Flannel pods are ready!"
        return 0
    fi
    
    echo "⚠️  Wait command failed, checking pod status manually..."
    return 1
}

# Retry logic for Flannel readiness
max_attempts=10
attempt=1
while [ $attempt -le $max_attempts ]; do
    echo "🔄 Attempt $attempt/$max_attempts to check Flannel readiness..."
    
    if check_flannel_ready; then
        break
    fi
    
    if [ $attempt -eq $max_attempts ]; then
        echo "⚠️  Flannel readiness check failed after $max_attempts attempts"
        echo "📋 Current Flannel pod status:"
        sudo -u ubuntu kubectl get pods -n kube-flannel
        echo "📋 Flannel pod logs (first pod):"
        sudo -u ubuntu kubectl logs -n kube-flannel $(sudo -u ubuntu kubectl get pods -n kube-flannel -o jsonpath='{.items[0].metadata.name}' 2>/dev/null) --tail=20 2>/dev/null || echo "Could not get logs"
        echo "⚠️  Continuing anyway - Flannel may still work..."
        break
    fi
    
    echo "⏳ Waiting 30 seconds before retry..."
    sleep 30
    attempt=$((attempt + 1))
done

# Final verification
echo "📋 Final Flannel status check:"
sudo -u ubuntu kubectl get pods -n kube-flannel

# Remove taint from control plane node to allow scheduling of regular pods
# This is required for single-node clusters so that the control plane can run workloads
sudo -u ubuntu kubectl taint nodes --all node-role.kubernetes.io/control-plane-

# Verify cluster status
echo "✅ Verifying cluster status..."
sudo -u ubuntu kubectl get nodes
sudo -u ubuntu kubectl get pods --all-namespaces

# Create a simple test deployment
echo "🧪 Creating test deployment..."
sudo -u ubuntu kubectl create deployment nginx --image=nginx:alpine
sudo -u ubuntu kubectl expose deployment nginx --port=80 --type=NodePort

echo "🎉 Kubernetes cluster setup complete!"
echo "📊 Cluster Status:"
sudo -u ubuntu kubectl get nodes
echo ""
echo "🌐 Test deployment:"
sudo -u ubuntu kubectl get pods
echo ""
echo "🔗 To access nginx: sudo -u ubuntu kubectl get svc nginx"
echo "📝 To check logs: sudo -u ubuntu kubectl logs -l app=nginx"

# Wait for cluster to be fully ready before installing Metrics Server
echo "⏳ Waiting for cluster to be fully ready..."
echo "📋 Checking kube-system pods..."

# Function to check cluster readiness
check_cluster_ready() {
    # Check DNS pods
    if ! sudo -u ubuntu kubectl wait --for=condition=ready pod -l k8s-app=kube-dns -n kube-system --timeout=60s 2>/dev/null; then
        echo "⚠️  DNS pods not ready yet..."
        return 1
    fi
    
    # Check if Flannel pods are running (final check)
    if ! sudo -u ubuntu kubectl get pods -n kube-flannel --no-headers 2>/dev/null | grep -q "Running"; then
        echo "⚠️  Flannel pods not running yet..."
        return 1
    fi
    
    echo "✅ Cluster is ready!"
    return 0
}

# Retry logic for cluster readiness
max_attempts=5
attempt=1
while [ $attempt -le $max_attempts ]; do
    echo "🔄 Attempt $attempt/$max_attempts to check cluster readiness..."
    
    if check_cluster_ready; then
        break
    fi
    
    if [ $attempt -eq $max_attempts ]; then
        echo "⚠️  Cluster readiness check failed after $max_attempts attempts"
        echo "📋 Current cluster status:"
        sudo -u ubuntu kubectl get pods --all-namespaces
        echo "⚠️  Continuing with Metrics Server installation anyway..."
        break
    fi
    
    echo "⏳ Waiting 60 seconds before retry..."
    sleep 60
    attempt=$((attempt + 1))
done

# Install Metrics Server with error handling
echo "📊 Installing Metrics Server..."
if ! sudo -u ubuntu kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml; then
    echo "❌ Failed to apply Metrics Server manifest"
    echo "📋 Checking if Metrics Server already exists..."
    sudo -u ubuntu kubectl get deployment metrics-server -n kube-system 2>/dev/null || echo "Metrics Server deployment not found"
else
    echo "✅ Metrics Server manifest applied successfully"
fi

# Patch Metrics Server to work with self-signed certificates
echo "🔧 Patching Metrics Server for self-signed certificates..."
if ! sudo -u ubuntu kubectl patch deployment metrics-server -n kube-system --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'; then
    echo "❌ Failed to patch Metrics Server"
    echo "📋 Checking current Metrics Server args..."
    sudo -u ubuntu kubectl get deployment metrics-server -n kube-system -o jsonpath='{.spec.template.spec.containers[0].args}' 2>/dev/null || echo "Could not get args"
else
    echo "✅ Metrics Server patched successfully"
fi

# Wait for Metrics Server to be ready with retry logic
echo "⏳ Waiting for Metrics Server to be ready..."
max_attempts=10
attempt=1
while [ $attempt -le $max_attempts ]; do
    echo "🔄 Attempt $attempt/$max_attempts to check Metrics Server readiness..."
    
    if sudo -u ubuntu kubectl wait --for=condition=available deployment/metrics-server -n kube-system --timeout=60s 2>/dev/null; then
        echo "✅ Metrics Server is ready!"
        break
    fi
    
    if [ $attempt -eq $max_attempts ]; then
        echo "⚠️  Metrics Server readiness check failed after $max_attempts attempts"
        echo "📋 Current Metrics Server status:"
        sudo -u ubuntu kubectl get pods -n kube-system | grep metrics
        echo "📋 Metrics Server logs:"
        sudo -u ubuntu kubectl logs -n kube-system deployment/metrics-server --tail=20 2>/dev/null || echo "Could not get logs"
        echo "⚠️  Metrics Server may not be fully functional, but continuing..."
        break
    fi
    
    echo "⏳ Waiting 30 seconds before retry..."
    sleep 30
    attempt=$((attempt + 1))
done

echo "✅ Metrics Server installation process complete!"
echo "📈 You can now use: kubectl top nodes and kubectl top pods" 