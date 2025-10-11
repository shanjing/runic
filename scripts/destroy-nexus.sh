#!/bin/bash

# Destroy Nexus Infrastructure Script
# This script safely destroys the Nexus infrastructure

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# Default values
ENVIRONMENT="${ENVIRONMENT:-nexus}"
AWS_REGION="${AWS_REGION:-us-west-2}"
TERRAFORM_DIR="${PROJECT_ROOT}/terraform/envs/${ENVIRONMENT}"
NAMESPACE="coordination-system"
FORCE=false
SKIP_CONFIRMATION=false

# Functions
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

Destroy Nexus infrastructure from AWS EKS

OPTIONS:
    -e, --environment ENV       Environment name (default: nexus)
    -r, --region REGION         AWS region (default: us-west-2)
    -f, --force                Force destruction without confirmation
    -y, --yes                  Skip confirmation prompts
    -h, --help                 Show this help message

EXAMPLES:
    # Destroy with confirmation
    $0

    # Force destroy
    $0 --force --yes

    # Destroy specific environment
    $0 --environment prod

⚠️  WARNING: This will permanently delete all resources!

EOF
    exit 0
}

confirm() {
    if [ "$SKIP_CONFIRMATION" = true ]; then
        return 0
    fi
    
    local prompt="$1"
    local response
    
    read -p "$(echo -e ${YELLOW}$prompt ${NC})" response
    
    case "$response" in
        [yY][eE][sS]|[yY]) 
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

check_prerequisites() {
    log "Checking prerequisites..."
    
    command -v aws >/dev/null 2>&1 || error "aws CLI not found"
    command -v terraform >/dev/null 2>&1 || error "terraform not found"
    command -v kubectl >/dev/null 2>&1 || error "kubectl not found"
    command -v helm >/dev/null 2>&1 || error "helm not found"
    
    if ! aws sts get-caller-identity >/dev/null 2>&1; then
        error "AWS credentials not configured"
    fi
    
    log "All prerequisites met"
}

configure_kubectl() {
    log "Configuring kubectl..."
    
    local cluster_name
    cluster_name=$(cd "$TERRAFORM_DIR" && terraform output -raw eks_cluster_name 2>/dev/null || echo "")
    
    if [ -z "$cluster_name" ]; then
        warn "Could not get EKS cluster name from Terraform output"
        return 1
    fi
    
    aws eks update-kubeconfig --region "$AWS_REGION" --name "$cluster_name" 2>/dev/null || true
}

uninstall_helm() {
    log "Uninstalling Helm release..."
    
    if ! helm list -n "$NAMESPACE" 2>/dev/null | grep -q "^nexus"; then
        warn "Helm release 'nexus' not found in namespace $NAMESPACE"
        return 0
    fi
    
    if ! confirm "Uninstall Helm release 'nexus'? [y/N]: "; then
        warn "Skipping Helm uninstall"
        return 0
    fi
    
    helm uninstall nexus -n "$NAMESPACE" || warn "Failed to uninstall Helm release"
    
    log "Helm release uninstalled"
}

delete_pvcs() {
    log "Checking for PVCs..."
    
    if ! kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
        warn "Namespace $NAMESPACE not found"
        return 0
    fi
    
    local pvcs
    pvcs=$(kubectl get pvc -n "$NAMESPACE" -l app=nexus -o name 2>/dev/null || echo "")
    
    if [ -z "$pvcs" ]; then
        log "No PVCs found"
        return 0
    fi
    
    log "Found PVCs:"
    kubectl get pvc -n "$NAMESPACE" -l app=nexus
    
    if ! confirm "Delete all PVCs (this will delete all data)? [y/N]: "; then
        warn "Skipping PVC deletion"
        return 0
    fi
    
    kubectl delete pvc -n "$NAMESPACE" -l app=nexus || warn "Failed to delete PVCs"
    
    log "PVCs deleted"
}

delete_namespace() {
    log "Checking namespace..."
    
    if ! kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
        warn "Namespace $NAMESPACE not found"
        return 0
    fi
    
    if ! confirm "Delete namespace $NAMESPACE? [y/N]: "; then
        warn "Skipping namespace deletion"
        return 0
    fi
    
    kubectl delete namespace "$NAMESPACE" || warn "Failed to delete namespace"
    
    log "Namespace deleted"
}

disable_rds_deletion_protection() {
    log "Checking RDS deletion protection..."
    
    cd "$TERRAFORM_DIR"
    
    local db_identifier
    db_identifier=$(terraform output -raw rds_address 2>/dev/null | cut -d'.' -f1 || echo "")
    
    if [ -z "$db_identifier" ]; then
        warn "Could not determine RDS identifier"
        return 0
    fi
    
    log "Disabling deletion protection for RDS instance: $db_identifier"
    
    aws rds modify-db-instance \
        --db-instance-identifier "$db_identifier" \
        --no-deletion-protection \
        --apply-immediately \
        --region "$AWS_REGION" 2>/dev/null || warn "Failed to disable RDS deletion protection"
    
    log "Waiting for RDS modification to complete..."
    sleep 10
}

destroy_terraform() {
    log "Destroying Terraform infrastructure..."
    
    if [ ! -d "$TERRAFORM_DIR" ]; then
        error "Terraform directory not found: $TERRAFORM_DIR"
    fi
    
    cd "$TERRAFORM_DIR"
    
    if [ ! -f "terraform.tfstate" ] && [ ! -f ".terraform/terraform.tfstate" ]; then
        warn "No Terraform state found. Infrastructure may already be destroyed."
        return 0
    fi
    
    log "Planning Terraform destroy..."
    terraform plan -destroy
    
    if ! confirm "Proceed with Terraform destroy (this will delete ALL infrastructure)? [y/N]: "; then
        error "Terraform destroy cancelled by user"
    fi
    
    log "Destroying Terraform resources..."
    terraform destroy -auto-approve
    
    log "Terraform destruction completed"
}

print_summary() {
    log "======================================"
    log "Nexus Destruction Summary"
    log "======================================"
    log "Environment: $ENVIRONMENT"
    log "Region: $AWS_REGION"
    log ""
    log "The following resources have been destroyed:"
    log "- Helm release"
    log "- Kubernetes PVCs and data"
    log "- Kubernetes namespace"
    log "- EKS cluster"
    log "- RDS database"
    log "- VPC and networking"
    log "- All associated AWS resources"
    log "======================================"
    warn "All data has been permanently deleted!"
    log "======================================"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -r|--region)
            AWS_REGION="$2"
            shift 2
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        -y|--yes)
            SKIP_CONFIRMATION=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            error "Unknown option: $1"
            ;;
    esac
done

# Main execution
main() {
    warn "======================================"
    warn "⚠️  WARNING: DESTRUCTIVE OPERATION  ⚠️"
    warn "======================================"
    warn "This will permanently delete:"
    warn "- All Nexus data and configurations"
    warn "- EKS cluster and nodes"
    warn "- RDS database and backups"
    warn "- VPC and networking"
    warn "======================================"
    
    if [ "$FORCE" = false ] && [ "$SKIP_CONFIRMATION" = false ]; then
        if ! confirm "Are you ABSOLUTELY SURE you want to proceed? Type 'yes' to confirm: "; then
            log "Destruction cancelled"
            exit 0
        fi
    fi
    
    log "Starting Nexus destruction..."
    log "Environment: $ENVIRONMENT"
    log "Region: $AWS_REGION"
    
    check_prerequisites
    
    # Try to configure kubectl (may fail if cluster is already gone)
    configure_kubectl || warn "Could not configure kubectl"
    
    # Kubernetes cleanup
    uninstall_helm || warn "Helm uninstall had issues"
    delete_pvcs || warn "PVC deletion had issues"
    delete_namespace || warn "Namespace deletion had issues"
    
    # Disable RDS deletion protection
    disable_rds_deletion_protection || warn "Could not disable RDS deletion protection"
    
    # Terraform cleanup
    destroy_terraform
    
    print_summary
    
    log "Nexus destruction completed"
}

# Run main function
main

