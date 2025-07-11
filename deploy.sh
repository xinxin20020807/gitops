#!/bin/bash

# GitOps ArgoCD Deployment Script
# This script helps deploy the ArgoCD GitOps configuration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if kubectl is available
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed or not in PATH"
        exit 1
    fi
    print_success "kubectl is available"
}

# Function to check if cluster is accessible
check_cluster() {
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Cannot connect to Kubernetes cluster"
        exit 1
    fi
    print_success "Kubernetes cluster is accessible"
}

# Function to install ArgoCD
install_argocd() {
    print_status "Installing ArgoCD..."
    
    # Create argocd namespace
    kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
    
    # Install ArgoCD
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    
    print_status "Waiting for ArgoCD to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
    kubectl wait --for=condition=available --timeout=300s deployment/argocd-application-controller -n argocd
    kubectl wait --for=condition=available --timeout=300s deployment/argocd-repo-server -n argocd
    
    print_success "ArgoCD installed successfully"
}

# Function to get ArgoCD admin password
get_argocd_password() {
    print_status "Getting ArgoCD admin password..."
    local password
    password=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
    echo
    print_success "ArgoCD Admin Credentials:"
    echo "  Username: admin"
    echo "  Password: $password"
    echo
    print_warning "Please save these credentials securely!"
    echo
}

# Function to deploy project configuration
deploy_project() {
    print_status "Deploying ArgoCD project configuration..."
    kubectl apply -f argocd/projects/myapp-project.yaml
    print_success "Project configuration deployed"
}

# Function to deploy applications
deploy_applications() {
    local method=$1
    
    if [ "$method" = "applicationset" ]; then
        print_status "Deploying applications using ApplicationSet..."
        kubectl apply -f argocd/applicationsets/myapp-unified-applicationset.yaml
        print_success "ApplicationSet deployed"
    else
        print_status "Deploying individual applications..."
        kubectl apply -f argocd/applications/dev-app.yaml
        kubectl apply -f argocd/applications/prod-app.yaml
        print_success "Individual applications deployed"
    fi
}

# Function to check application status
check_app_status() {
    print_status "Checking application status..."
    echo
    kubectl get applications -n argocd
    echo
}

# Function to setup port forwarding
setup_port_forward() {
    print_status "Setting up port forwarding for ArgoCD UI..."
    print_warning "ArgoCD UI will be available at: https://localhost:8080"
    print_warning "Press Ctrl+C to stop port forwarding"
    kubectl port-forward svc/argocd-server -n argocd 8080:443
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [COMMAND]"
    echo
    echo "Commands:"
    echo "  install           Install ArgoCD and deploy all configurations"
    echo "  install-argocd    Install ArgoCD only"
    echo "  deploy-project    Deploy project configuration"
    echo "  deploy-apps       Deploy applications (individual)"
    echo "  deploy-appset     Deploy applications (ApplicationSet)"
    echo "  status            Check application status"
    echo "  password          Get ArgoCD admin password"
    echo "  ui                Open ArgoCD UI (port-forward)"
    echo "  help              Show this help message"
    echo
    echo "Examples:"
    echo "  $0 install                    # Full installation"
    echo "  $0 deploy-appset             # Deploy using ApplicationSet"
    echo "  $0 ui                        # Access ArgoCD UI"
}

# Main function
main() {
    local command=${1:-help}
    
    case $command in
        "install")
            check_kubectl
            check_cluster
            install_argocd
            get_argocd_password
            deploy_project
            deploy_applications "applicationset"
            check_app_status
            print_success "Installation completed successfully!"
            print_status "Run '$0 ui' to access ArgoCD UI"
            ;;
        "install-argocd")
            check_kubectl
            check_cluster
            install_argocd
            get_argocd_password
            ;;
        "deploy-project")
            check_kubectl
            check_cluster
            deploy_project
            ;;
        "deploy-apps")
            check_kubectl
            check_cluster
            deploy_applications "individual"
            check_app_status
            ;;
        "deploy-appset")
            check_kubectl
            check_cluster
            deploy_applications "applicationset"
            check_app_status
            ;;
        "status")
            check_kubectl
            check_cluster
            check_app_status
            ;;
        "password")
            check_kubectl
            check_cluster
            get_argocd_password
            ;;
        "ui")
            check_kubectl
            check_cluster
            setup_port_forward
            ;;
        "help")
            show_usage
            ;;
        *)
            print_error "Unknown command: $command"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"