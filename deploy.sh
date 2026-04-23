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

# Docker Configuration
DOCKER_IMAGE="${APP_NAME}"
DOCKER_TAG="latest"
DOCKERFILE="${APP_NAME}/Dockerfile"
CONTAINER_NAME="${APP_NAME}-container"
VOLUMES_DIR="${APP_NAME}/volumes"  # Persistant data directory

# Logging function
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
    
    # Build and deploy with Docker if requested
    if [ "$ENVIRONMENT" = "docker" ]; then
        docker_deploy
    fi
}
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

# Function to create Dockerfile
create_dockerfile() {
    info "Creating Dockerfile..."
    
    if [ ! -f "$DOCKERFILE" ]; then
        cat > "$DOCKERFILE" << 'DOCKERFILE_EOF'
FROM node:20-alpine

WORKDIR /app

# Install dependencies
COPY package*.json ./
RUN npm install --production

# Copy application code
COPY . .

# Expose port
EXPOSE 3000

# Start application
CMD ["npm", "start"]
DOCKERFILE_EOF
        info "Dockerfile created successfully"
    else
        info "Dockerfile already exists"
    fi
}

# Function to build Docker image
build_docker_image() {
    info "Building Docker image..."
    
    if [ ! -f "$DOCKERFILE" ]; then
        error "Dockerfile not found. Please run './deploy.sh docker create' first."
        return 1
    fi
    
    # Build Docker image with tag
    docker build -t "${DOCKER_IMAGE}:${DOCKER_TAG}" -f "$DOCKERFILE" .
    info "Docker image built successfully"
}

# Function to run Docker container
run_docker_container() {
    info "Starting Docker container..."
    
    # Create volumes directory for persistent data
    if [ ! -d "$VOLUMES_DIR" ]; then
        mkdir -p "$VOLUMES_DIR"
        info "Created volumes directory"
    fi
    
    # Remove existing container if it exists
    if [ -n "$(docker ps -a -q -f name=^${CONTAINER_NAME}$)" ]; then
        info "Stopping and removing existing container..."
        docker stop "$CONTAINER_NAME" 2>/dev/null || true
        docker rm "$CONTAINER_NAME" 2>/dev/null || true
    fi
    
    # Create volume for persistent data
    docker volume create "${APP_NAME}_data" 2>/dev/null || true
    
    # Run container
    docker run -d \
        --name "$CONTAINER_NAME" \
        --rm \
        -p 3000:3000 \
        -v "${VOLUMES_DIR}:${VOLUMES_DIR}:rw" \
        -v "${APP_NAME}_data:/app/data" \
        -e NODE_ENV="production" \
        "${DOCKER_IMAGE}:${DOCKER_TAG}"
    
    info "Docker container started successfully"
}

# Function to stop Docker container
stop_docker_container() {
    info "Stopping Docker container..."
    
    if [ -n "$(docker ps -q -f name=^${CONTAINER_NAME}$)" ]; then
        docker stop "$CONTAINER_NAME"
        info "Container stopped"
    else
        warn "Container is not running"
    fi
}

# Function to remove Docker container
remove_docker_container() {
    info "Removing Docker container..."
    
    if [ -n "$(docker ps -a -q -f name=^${CONTAINER_NAME}$)" ]; then
        docker rm "$CONTAINER_NAME"
        info "Container removed"
    else
        warn "Container does not exist"
    fi
}

# Function to remove Docker image
remove_docker_image() {
    info "Removing Docker image..."
    
    docker rmi -f "${DOCKER_IMAGE}:${DOCKER_TAG}" 2>/dev/null || true
    info "Image removed"
}

# Function to show Docker status
docker_status() {
    info "Docker Status:"
    
    if [ -f "$DOCKERFILE" ]; then
        echo -e "${GREEN}Dockerfile:${NC} Exists"
    else
        echo -e "${RED}Dockerfile:${NC} Not Found"
    fi
    
    if [ -n "$(docker images -q -f name=^${DOCKER_IMAGE}:${DOCKER_TAG}$)" ]; then
        echo -e "${GREEN}Docker Image:${NC} Built"
        docker images -q -f name=^${DOCKER_IMAGE}:${DOCKER_TAG}$ | xargs docker image inspect -f '{{.Size}}'
    else
        echo -e "${RED}Docker Image:${NC} Not Built"
    fi
    
    if [ -n "$(docker ps -q -f name=^${CONTAINER_NAME}$)" ]; then
        echo -e "${GREEN}Container:${NC} Running"
        docker ps -q -f name=^${CONTAINER_NAME}$ | xargs docker inspect -f '{{.State.Status}}'
    else
        echo -e "${RED}Container:${NC} Not Running"
    fi
}

# Function to deploy with Docker
docker_deploy() {
    local ENVIRONMENT="${1:-production}"
    
    info "Deploying with Docker to $ENVIRONMENT environment..."
    
    # Create Dockerfile if it doesn't exist
    create_dockerfile
    
    # Build Docker image
    build_docker_image
    
    # Deploy container
    run_docker_container
    
    info "Docker deployment completed successfully"
}

# Function to rollback Docker deployment
docker_rollback() {
    local VERSION="${1:-}"
    
    info "Rolling back Docker deployment..."
    
    # Stop and remove container
    stop_docker_container
    remove_docker_container
    
    if [ -n "$VERSION" ]; then
        # Clone from specific version
        info "Restoring from version $VERSION..."
        git fetch origin "$VERSION"
        git reset --hard origin/$VERSION
    else
        warn "No version specified for rollback"
    fi
    
    info "Docker rollback completed"
}

# Function to clean Docker
docker_clean() {
    info "Cleaning Docker resources..."
    
    # Stop and remove container
    stop_docker_container
    remove_docker_container
    
    # Remove image
    remove_docker_image
    
    # Remove volume (optional - set to true/false)
    if [ "$1" = "--force" ]; then
        docker volume rm "${APP_NAME}_data" 2>/dev/null || true
        info "Volume removed"
    fi
    
    info "Docker cleanup completed"
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
        docker)
            local SUBCOMMAND="${2:-status}"
            case "$SUBCOMMAND" in
                create)
                    create_dockerfile
                    ;;
                build)
                    build_docker_image
                    ;;
                run)
                    run_docker_container
                    ;;
                stop)
                    stop_docker_container
                    ;;
                remove)
                    remove_docker_container
                    ;;
                clean)
                    docker_clean
                    ;;
                status)
                    docker_status
                    ;;
                deploy)
                    docker_deploy
                    ;;
                rollback)
                    docker_rollback "$3"
                    ;;
                *)
                    error "Unknown Docker subcommand: $SUBCOMMAND"
                    info "Use './deploy.sh docker help' for usage information"
                    ;;
            esac
            ;;
        docker-deploy)
            docker_deploy
            ;;
        docker-rollback)
            docker_rollback "$2"
            ;;
        help|--help|-h)
            info "StockMarket Deployment Script with Docker support"
            echo ""
            echo "Usage: $0 <command> [options]"
            echo ""
            echo "Commands:"
            echo "  build                    Build the application and install dependencies"
            echo "  test                     Run tests (if configured)"
            echo "  deploy [environment]     Deploy to environment (prod|staging|dev|docker)"
            echo "                             (default: prod)"
            echo "  commit [message]         Create commit with given message"
            echo "  push [remote] [branch]   Push to repository (default: origin/main)"
            echo "  rollback [version]       Rollback to specific git commit/version"
            echo "  status                   Show deployment status"
            echo "  clean                    Remove untracked files"
            echo "  clean --force           Remove all untracked files and directories"
            echo ""
            echo "Docker Commands:"
            echo "  docker create           Create Dockerfile"
            echo "  docker build            Build Docker image"
            echo "  docker run              Run Docker container"
            echo "  docker stop             Stop running container"
            echo "  docker remove           Remove container"
            echo "  docker clean            Clean Docker resources"
            echo "  docker status           Show Docker status"
            echo "  docker deploy           Deploy application with Docker"
            echo "  docker rollback [ver]   Rollback to specific version"
            echo ""
            echo "Examples:"
            echo "  $0 build"
            echo "  $0 deploy staging"
            echo "  $0 docker create"
            echo "  $0 docker build"
            echo "  $0 docker-deploy"
            echo "  $0 docker status"
            ;;
        *)
            error "Unknown command: $COMMAND"
            info "Use '$0 help' for usage information"
            ;;
    esac
}

# Run main function with all arguments
main "$@"
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