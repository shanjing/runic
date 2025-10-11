#!/bin/bash

# Deploy Nexus Infrastructure Script
# This script automates the deployment of the State Coordination Service

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
HELM_CHART_DIR="${PROJECT_ROOT}/kubernetes/helm/charts/nexus"
NAMESPACE="coordination-system"
DRY_RUN=false
SKIP_TERRAFORM=false
SKIP_HELM=false

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

Deploy Nexus infrastructure to AWS EKS

OPTIONS:
    -e, --environment ENV       Environment name (default: nexus)
    -r, --region REGION         AWS region (default: us-west-2)
    -d, --dry-run              Perform dry run without actual deployment
    --skip-terraform           Skip Terraform deployment
    --skip-helm                Skip Helm deployment
    -h, --help                 Show this help message

EXAMPLES:
    # Deploy everything
    $0

    # Deploy to different region
    $0 --region us-east-1

    # Dry run
    $0 --dry-run

    # Skip Terraform, only deploy Helm
    $0 --skip-terraform

EOF
    exit 0
}

check_prerequisites() {
    log "Checking prerequisites..."
    
    local missing_tools=()
    
    command -v aws >/dev/null 2>&1 || missing_tools+=("aws")
    command -v terraform >/dev/null 2>&1 || missing_tools+=("terraform")
    command -v kubectl >/dev/null 2>&1 || missing_tools+=("kubectl")
    command -v helm >/dev/null 2>&1 || missing_tools+=("helm")
    command -v jq >/dev/null 2>&1 || missing_tools+=("jq")
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        error "Missing required tools: ${missing_tools[*]}"
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity >/dev/null 2>&1; then
        error "AWS credentials not configured"
    fi
    
    log "All prerequisites met"
}

deploy_terraform() {
    if [ "$SKIP_TERRAFORM" = true ]; then
        log "Skipping Terraform deployment"
        return
    fi
    
    log "Deploying Terraform infrastructure..."
    
    if [ ! -d "$TERRAFORM_DIR" ]; then
        error "Terraform directory not found: $TERRAFORM_DIR"
    fi
    
    cd "$TERRAFORM_DIR"
    
    log "Initializing Terraform..."
    terraform init
    
    log "Planning Terraform changes..."
    terraform plan -out=tfplan
    
    if [ "$DRY_RUN" = true ]; then
        warn "Dry run mode - skipping Terraform apply"
        return
    fi
    
    log "Applying Terraform changes..."
    terraform apply tfplan
    
    log "Terraform deployment completed"
}

configure_kubectl() {
    log "Configuring kubectl..."
    
    local cluster_name
    cluster_name=$(cd "$TERRAFORM_DIR" && terraform output -raw eks_cluster_name 2>/dev/null || echo "")
    
    if [ -z "$cluster_name" ]; then
        error "Could not get EKS cluster name from Terraform output"
    fi
    
    log "Updating kubeconfig for cluster: $cluster_name"
    aws eks update-kubeconfig --region "$AWS_REGION" --name "$cluster_name"
    
    # Test connection
    if ! kubectl get nodes >/dev/null 2>&1; then
        error "Failed to connect to Kubernetes cluster"
    fi
    
    log "kubectl configured successfully"
}

get_terraform_outputs() {
    log "Retrieving Terraform outputs..."
    
    cd "$TERRAFORM_DIR"
    
    # Get RDS credentials ARN
    local rds_secret_arn
    rds_secret_arn=$(terraform output -raw rds_credentials_secret_arn 2>/dev/null || echo "")
    
    if [ -n "$rds_secret_arn" ]; then
        log "Fetching RDS credentials from AWS Secrets Manager..."
        local rds_credentials
        rds_credentials=$(aws secretsmanager get-secret-value \
            --secret-id "$rds_secret_arn" \
            --query SecretString \
            --output text 2>/dev/null || echo "")
        
        if [ -n "$rds_credentials" ]; then
            export DB_HOST=$(echo "$rds_credentials" | jq -r '.host')
            export DB_PORT=$(echo "$rds_credentials" | jq -r '.port')
            export DB_NAME=$(echo "$rds_credentials" | jq -r '.dbname')
            export DB_USER=$(echo "$rds_credentials" | jq -r '.username')
            export DB_PASSWORD=$(echo "$rds_credentials" | jq -r '.password')
            log "RDS credentials retrieved successfully"
        fi
    fi
    
    # Get service account role ARN
    local sa_role_arn
    sa_role_arn=$(terraform output -raw nexus_service_account_role_arn 2>/dev/null || echo "")
    
    if [ -n "$sa_role_arn" ]; then
        export SA_ROLE_ARN="$sa_role_arn"
        log "Service account role ARN: $sa_role_arn"
    fi
}

deploy_helm() {
    if [ "$SKIP_HELM" = true ]; then
        log "Skipping Helm deployment"
        return
    fi
    
    log "Deploying Helm chart..."
    
    if [ ! -d "$HELM_CHART_DIR" ]; then
        error "Helm chart directory not found: $HELM_CHART_DIR"
    fi
    
    # Create namespace if it doesn't exist
    if ! kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
        log "Creating namespace: $NAMESPACE"
        kubectl create namespace "$NAMESPACE"
    fi
    
    # Prepare Helm values
    local helm_args=(
        "nexus"
        "$HELM_CHART_DIR"
        "--namespace" "$NAMESPACE"
        "--create-namespace"
    )
    
    # Add dynamic values from Terraform
    if [ -n "$DB_HOST" ]; then
        helm_args+=("--set" "secrets.database.host=$DB_HOST")
    fi
    
    if [ -n "$DB_PORT" ]; then
        helm_args+=("--set" "secrets.database.port=$DB_PORT")
    fi
    
    if [ -n "$DB_NAME" ]; then
        helm_args+=("--set" "secrets.database.name=$DB_NAME")
    fi
    
    if [ -n "$DB_USER" ]; then
        helm_args+=("--set" "secrets.database.user=$DB_USER")
    fi
    
    if [ -n "$DB_PASSWORD" ]; then
        helm_args+=("--set" "secrets.database.password=$DB_PASSWORD")
    fi
    
    if [ -n "$SA_ROLE_ARN" ]; then
        helm_args+=("--set" "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn=$SA_ROLE_ARN")
    fi
    
    if [ "$DRY_RUN" = true ]; then
        warn "Dry run mode - showing Helm template"
        helm template "${helm_args[@]}"
        return
    fi
    
    # Check if release exists
    if helm list -n "$NAMESPACE" | grep -q "^nexus"; then
        log "Upgrading existing Helm release..."
        helm upgrade "${helm_args[@]}"
    else
        log "Installing new Helm release..."
        helm install "${helm_args[@]}"
    fi
    
    log "Helm deployment completed"
}

wait_for_pods() {
    log "Waiting for pods to be ready..."
    
    kubectl wait --for=condition=ready pod \
        -l app=nexus \
        -n "$NAMESPACE" \
        --timeout=300s || warn "Timeout waiting for pods"
    
    log "Pod status:"
    kubectl get pods -n "$NAMESPACE" -l app=nexus
}

verify_deployment() {
    log "Verifying deployment..."
    
    # Check StatefulSet
    log "StatefulSet status:"
    kubectl get statefulset -n "$NAMESPACE"
    
    # Check Services
    log "Service status:"
    kubectl get svc -n "$NAMESPACE"
    
    # Check Ingress
    log "Ingress status:"
    kubectl get ingress -n "$NAMESPACE"
    
    # Test health endpoint
    log "Testing health endpoint..."
    local api_pod
    api_pod=$(kubectl get pod -n "$NAMESPACE" -l app=nexus -o jsonpath='{.items[0].metadata.name}')
    
    if [ -n "$api_pod" ]; then
        kubectl exec -n "$NAMESPACE" "$api_pod" -- \
            wget -q -O- http://localhost:8080/health/ready || warn "Health check failed"
    fi
    
    log "Deployment verification completed"
}

print_summary() {
    log "======================================"
    log "Nexus Deployment Summary"
    log "======================================"
    log "Environment: $ENVIRONMENT"
    log "Region: $AWS_REGION"
    log "Namespace: $NAMESPACE"
    
    if [ -n "$DB_HOST" ]; then
        log "Database: $DB_HOST"
    fi
    
    log ""
    log "Next steps:"
    log "1. Check pod logs: kubectl logs -f statefulset/nexus-cluster -n $NAMESPACE"
    log "2. Port-forward API: kubectl port-forward svc/nexus-api 8080:8080 -n $NAMESPACE"
    log "3. View resources: kubectl get all -n $NAMESPACE"
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
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        --skip-terraform)
            SKIP_TERRAFORM=true
            shift
            ;;
        --skip-helm)
            SKIP_HELM=true
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
    log "Starting Nexus deployment..."
    log "Environment: $ENVIRONMENT"
    log "Region: $AWS_REGION"
    
    if [ "$DRY_RUN" = true ]; then
        warn "Running in DRY RUN mode"
    fi
    
    check_prerequisites
    deploy_terraform
    
    if [ "$SKIP_TERRAFORM" = false ]; then
        configure_kubectl
        get_terraform_outputs
    fi
    
    deploy_helm
    
    if [ "$DRY_RUN" = false ]; then
        wait_for_pods
        verify_deployment
    fi
    
    print_summary
    
    log "Nexus deployment completed successfully!"
}

# Run main function
main

