#!/bin/bash
#
# StockMarket App Deployment Script
# This script handles deployment of the stockmarket application
#

set -e  # Exit on error

# Configuration
APP_NAME="stockmarket"
DEPLOY_DIR="${APP_NAME}"
LOG_FILE="${DEPLOY_DIR}/deploy.log"
GIT_USER=$(git config user.name)
GIT_EMAIL=$(git config user.email)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

info() {
    log "${GREEN}[INFO]${NC} $1"
}

warn() {
    log "${YELLOW}[WARN]${NC} $1"
}

error() {
    log "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    warn "This script should be run as root or with sudo for certain operations"
fi

# Function to build the app
build_app() {
    info "Building application..."
    cd "$DEPLOY_DIR"
    
    # Check if package.json exists
    if [ ! -f "package.json" ]; then
        error "package.json not found in $DEPLOY_DIR"
        return 1
    fi
    
    # Install dependencies
    info "Installing dependencies..."
    npm install
    
    # Build if needed
    if [ -f "package.json" ]; then
        if grep -q '"scripts"' package.json && grep -q '"build"' package.json; then
            npm run build
        else
            info "No build script found, skipping build step"
        fi
    fi
}

# Function to run tests (optional)
run_tests() {
    info "Running tests (if configured)..."
    if [ -f "package.json" ] && grep -q '"test"' package.json; then
        npm test
    else
        info "No test script found or tests not required"
    fi
}

# Function to deploy to different environments
deploy() {
    local ENVIRONMENT="${1:-production}"
    
    case "$ENVIRONMENT" in
        production|prod)
            info "Deploying to production environment..."
            # Production deployment steps
            # Build and install
            build_app
            run_tests
            
            # Set environment variables
            if [ -f ".env.example" ]; then
                cp .env.example .env
                info "Created .env from .env.example"
            fi
            
            # Start the application
            info "Starting application..."
            npm start &>/dev/null &
            echo $! > "${DEPLOY_DIR}/pid"
            info "Application started with PID $(cat ${DEPLOY_DIR}/pid)"
            
            ;;
        staging)
            info "Deploying to staging environment..."
            build_app
            npm start &>/dev/null &
            echo $! > "${DEPLOY_DIR}/pid"
            ;;
        development|dev)
            info "Deploying to development environment..."
            build_app
            npm start &>/dev/null &
            echo $! > "${DEPLOY_DIR}/pid"
            ;;
        *)
            error "Unknown environment: $ENVIRONMENT"
            return 1
            ;;
    esac
}

# Function to create deployment commit
create_commit() {
    local COMMIT_MESSAGE="${1:-'Update: Deployment'""}"
    
    info "Creating commit..."
    cd "$DEPLOY_DIR"
    
    # Create commit if there are changes
    if [ -n "$(git status --porcelain)" ]; then
        git add .
        git commit -m "$COMMIT_MESSAGE"
        info "Commit created successfully"
    else
        info "No changes to commit"
    fi
}

# Function to push to repository
push() {
    local REMOTE="${1:-origin}"
    local BRANCH="${2:-main}"
    
    info "Pushing to ${REMOTE}/${BRANCH}..."
    cd "$DEPLOY_DIR"
    
    # Check if there are commits to push
    local LATEST_COMMIT=$(git rev-parse HEAD)
    local REMOTE_LATEST=$(git ls-remote --heads "$REMOTE" "${BRANCH}" | cut -d' ' -f1)
    
    if [ "$LATEST_COMMIT" = "$REMOTE_LATEST" ]; then
        info "Branch is already up to date with remote"
        return 0
    fi
    
    git push "$REMOTE" "${BRANCH}"
    info "Push successful"
}

# Function to rollback deployment
rollback() {
    local VERSION="${1:-}"
    
    info "Rolling back deployment..."
    cd "$DEPLOY_DIR"
    
    if [ -n "$VERSION" ]; then
        # Rollback to specific version
        git reset --hard "$VERSION"
        git clean -fd
        info "Rolled back to version $VERSION"
    else
        warn "No version specified. Consider specifying a version to rollback to."
        return 1
    fi
}

# Function to display deployment status
status() {
    info "Deployment Status:"
    cd "$DEPLOY_DIR"
    
    echo -e "${GREEN}Build:${NC} $(if [ -d "node_modules" ]; then echo "Installed"; else echo "Not Installed"; fi)"
    echo "Git Branch: $(git branch --show-current)"
    echo "Git Commit: $(git rev-parse HEAD)"
    
    if [ -f "pid" ]; then
        echo -e "Process Status:${NC} Running (PID: $(cat pid))"
        kill -0 $(cat pid) 2>/dev/null && echo "Process is alive" || echo "Process has stopped"
    else
        echo -e "Process Status:${NC} Not Running"
    fi
}

# Function to cleanup
cleanup() {
    info "Cleaning up..."
    cd "$DEPLOY_DIR"
    
    # Stop running process if exists
    if [ -f "pid" ]; then
        kill $(cat pid) 2>/dev/null || true
        rm -f pid
        info "Process stopped"
    fi
    
    # Remove untracked files (optional - set to true/false)
    if [ "$1" = "--force" ]; then
        git clean -fdx
        info "Cleaned all untracked files"
    fi
}

# Main script execution
main() {
    local COMMAND="${1:-help}"
    shift || true
    
    case "$COMMAND" in
        build)
            build_app
            ;;
        test)
            run_tests
            ;;
        deploy)
            local ENV="${2:-production}"
            deploy "$ENV"
            ;;
        commit)
            local MSG="${2:-'Update: Deployment'}"
            create_commit "$MSG"
            ;;
        push)
            local REMOTE="${2:-origin}"
            local BRANCH="${3:-main}"
            push "$REMOTE" "$BRANCH"
            ;;
        rollback)
            local VERSION="$2"
            rollback "$VERSION"
            ;;
        status)
            status
            ;;
        clean|cleanup)
            local FORCE="${2:-}"
            cleanup "$FORCE"
            ;;
        help|--help|-h)
            info "StockMarket Deployment Script"
            echo ""
            echo "Usage: $0 <command> [options]"
            echo ""
            echo "Commands:"
            echo "  build                    Build the application and install dependencies"
            echo "  test                     Run tests (if configured)"
            echo "  deploy [environment]     Deploy to environment (prod|staging|dev) (default: prod)"
            echo "  commit [message]         Create commit with given message"
            echo "  push [remote] [branch]   Push to repository (default: origin/main)"
            echo "  rollback [version]       Rollback to specific git commit/version"
            echo "  status                   Show deployment status"
            echo "  clean                    Remove untracked files"
            echo "  clean --force           Remove all untracked files and directories"
            echo ""
            echo "Examples:"
            echo "  $0 build"
            echo "  $0 deploy staging"
            echo "  $0 commit 'Update: Fix deployment script'"
            echo "  $0 push origin main"
            echo "  $0 status"
            ;;
        *)
            error "Unknown command: $COMMAND"
            info "Use '$0 help' for usage information"
            ;;
    esac
}

# Run main function with all arguments
main "$@"