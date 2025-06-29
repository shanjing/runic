#!/bin/bash

# Test Bootstrap Script for Runic Dev Environment
# This script tests the Kubernetes bootstrap process manually

set -e

echo "🧪 Testing Kubernetes bootstrap process..."

# Check if we're running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root (use sudo)"
    exit 1
fi

# Check current Kubernetes status
echo "📊 Current Kubernetes status:"
if command -v kubectl &> /dev/null; then
    echo "✅ kubectl is installed"
    kubectl version --client 2>/dev/null || echo "❌ kubectl version check failed"
else
    echo "❌ kubectl is not installed"
fi

# Check if kubeadm is available
if command -v kubeadm &> /dev/null; then
    echo "✅ kubeadm is installed"
    kubeadm version 2>/dev/null || echo "❌ kubeadm version check failed"
else
    echo "❌ kubeadm is not installed"
fi

# Check containerd status
echo "🐳 Containerd status:"
systemctl status containerd --no-pager -l || echo "❌ containerd not running"

# Check kubelet status
echo "🔧 Kubelet status:"
systemctl status kubelet --no-pager -l || echo "❌ kubelet not running"

# Check if cluster is already initialized
if [ -f "/etc/kubernetes/admin.conf" ]; then
    echo "✅ Kubernetes admin.conf exists"
    echo "📋 Cluster info:"
    kubeadm config view 2>/dev/null || echo "❌ Could not view kubeadm config"
else
    echo "❌ Kubernetes admin.conf does not exist"
fi

# Check kubeconfig for ubuntu user
echo "🔑 Checking kubeconfig for ubuntu user:"
if [ -f "/home/ubuntu/.kube/config" ]; then
    echo "✅ /home/ubuntu/.kube/config exists"
    ls -la /home/ubuntu/.kube/
else
    echo "❌ /home/ubuntu/.kube/config does not exist"
fi

# Test kubeconfig creation
echo "🧪 Testing kubeconfig creation..."
if [ -f "/etc/kubernetes/admin.conf" ]; then
    echo "Creating test kubeconfig..."
    mkdir -p /home/ubuntu/.kube
    cp -i /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
    chown ubuntu:ubuntu /home/ubuntu/.kube/config
    chmod 600 /home/ubuntu/.kube/config
    echo "✅ Test kubeconfig created"
    ls -la /home/ubuntu/.kube/
else
    echo "❌ Cannot create kubeconfig - admin.conf not found"
fi

# Test kubectl as ubuntu user
echo "🧪 Testing kubectl as ubuntu user..."
if [ -f "/home/ubuntu/.kube/config" ]; then
    echo "Running: sudo -u ubuntu kubectl get nodes"
    sudo -u ubuntu kubectl get nodes 2>/dev/null || echo "❌ kubectl failed for ubuntu user"
else
    echo "❌ Cannot test kubectl - kubeconfig not found"
fi

echo "🧪 Bootstrap test complete!" 