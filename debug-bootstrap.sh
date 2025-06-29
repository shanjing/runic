#!/bin/bash

# Debug Bootstrap Script - Test kubeconfig creation
set -e

echo "🔍 Debugging kubeconfig creation..."

# Check if we're running as root
echo "👤 Current user: $(whoami)"
echo "🏠 Current home: $HOME"

# Check if admin.conf exists
if [ -f "/etc/kubernetes/admin.conf" ]; then
    echo "✅ /etc/kubernetes/admin.conf exists"
    ls -la /etc/kubernetes/admin.conf
else
    echo "❌ /etc/kubernetes/admin.conf does not exist"
    echo "📋 Checking /etc/kubernetes/ directory:"
    ls -la /etc/kubernetes/ || echo "Directory does not exist"
    exit 1
fi

# Test creating kubeconfig for root
echo "🔑 Testing kubeconfig creation for root..."
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
chmod 600 $HOME/.kube/config
echo "✅ Root kubeconfig created"
ls -la $HOME/.kube/

# Test creating kubeconfig for ubuntu
echo "🔑 Testing kubeconfig creation for ubuntu..."
mkdir -p /home/ubuntu/.kube
cp -i /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
chown ubuntu:ubuntu /home/ubuntu/.kube/config
chmod 600 /home/ubuntu/.kube/config
echo "✅ Ubuntu kubeconfig created"
ls -la /home/ubuntu/.kube/

# Test kubectl as root
echo "🧪 Testing kubectl as root..."
kubectl get nodes 2>/dev/null || echo "❌ kubectl failed for root"

# Test kubectl as ubuntu
echo "🧪 Testing kubectl as ubuntu..."
sudo -u ubuntu kubectl get nodes 2>/dev/null || echo "❌ kubectl failed for ubuntu"

echo "�� Debug complete!" 