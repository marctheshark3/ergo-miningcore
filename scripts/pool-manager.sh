#!/bin/bash

# Comprehensive Pool Management Script for Ergo Mining Pool
# Provides unified interface for managing both solo and public pools

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
}

show_banner() {
    cat << 'EOF'
═══════════════════════════════════════════════════════════
  _____ ____   ____  _____ 
 | ____|  _ \ / ___|/ _ \ 
 |  _| | |_) | |  _| | | |
 | |___|  _ <| |_| | |_| |
 |_____|_| \_\\____|\___/ 
                          
    MINING POOL MANAGER
═══════════════════════════════════════════════════════════
EOF
}

show_usage() {
    cat << EOF
Usage: $0 <command> [options]

Comprehensive management tool for Ergo Mining Pool.

COMMANDS:
    start [solo|public]     Start the mining pool
    stop [solo|public]      Stop the mining pool  
    restart [solo|public]   Restart the mining pool
    status                  Show detailed status of all services
    logs [service]          Show logs for all services or specific service
    update                  Update and rebuild containers
    backup                  Backup database and configuration
    restore <backup_file>   Restore from backup
    ssl                     Manage SSL certificates
    health                  Run comprehensive health checks
    cleanup                 Clean up unused containers and volumes

SSL SUBCOMMANDS:
    ssl generate [domain]   Generate new SSL certificates
    ssl renew              Renew existing certificates
    ssl check              Check certificate status

EXAMPLES:
    $0 start public         # Start public pool
    $0 status               # Show all service status
    $0 logs miningcore      # Show miningcore logs
    $0 ssl generate example.com  # Generate SSL for domain
    $0 backup               # Create backup
    $0 health               # Run health checks
EOF
}

detect_mode() {
    if docker-compose -f "$PROJECT_ROOT/docker-compose.solo.yml" ps 2>/dev/null | grep -q "Up"; then
        echo "solo"
    elif docker-compose -f "$PROJECT_ROOT/docker-compose.yml" ps 2>/dev/null | grep -q "Up"; then
        echo "public"
    else
        echo ""
    fi
}

get_compose_file() {
    local mode=$1
    if [ "$mode" = "solo" ]; then
        echo "docker-compose.solo.yml"
    else
        echo "docker-compose.yml"
    fi
}

start_pool() {
    local mode=${1:-"public"}
    
    log_step "Starting Ergo Mining Pool in $mode mode..."
    
    local compose_file=$(get_compose_file "$mode")
    
    cd "$PROJECT_ROOT"
    
    # Check if already running
    if docker-compose -f "$compose_file" ps | grep -q "Up"; then
        log_warning "Pool is already running in $mode mode"
        return 0
    fi
    
    # Check Ergo node connectivity
    if ! curl -s -X POST \
        -H "Content-Type: application/json" \
        -H "api_key: hello" \
        -d '{"jsonrpc":"2.0","method":"info","params":[],"id":1}' \
        "http://127.0.0.1:9053" > /dev/null; then
        log_error "Cannot connect to Ergo node. Make sure it's running first."
        return 1
    fi
    
    # Start services
    docker-compose -f "$compose_file" up -d
    
    # Wait for health checks
    log_info "Waiting for services to become healthy..."
    sleep 10
    
    # Show status
    show_detailed_status "$mode"
    
    log_success "Pool started successfully!"
}

stop_pool() {
    local mode=${1:-$(detect_mode)}
    
    if [ -z "$mode" ]; then
        log_warning "No running pool detected"
        return 0
    fi
    
    log_step "Stopping Ergo Mining Pool ($mode mode)..."
    
    local compose_file=$(get_compose_file "$mode")
    
    cd "$PROJECT_ROOT"
    docker-compose -f "$compose_file" down
    
    log_success "Pool stopped successfully!"
}

restart_pool() {
    local mode=${1:-$(detect_mode)}
    
    if [ -z "$mode" ]; then
        mode="public"
    fi
    
    log_step "Restarting Ergo Mining Pool..."
    
    stop_pool "$mode"
    sleep 2
    start_pool "$mode"
}

show_detailed_status() {
    local mode=$(detect_mode)
    
    if [ -z "$mode" ]; then
        log_info "❌ No pools are currently running"
        return 0
    fi
    
    local compose_file=$(get_compose_file "$mode")
    
    echo ""
    log_info "📊 Pool Status: $mode mode"
    echo "════════════════════════════════════════"
    
    cd "$PROJECT_ROOT"
    docker-compose -f "$compose_file" ps
    
    echo ""
    log_info "🔗 Connection Information:"
    
    if [ "$mode" = "solo" ]; then
        echo "  • Solo Mining Ports:"
        echo "    - Low difficulty:  localhost:4074"
        echo "    - High difficulty: localhost:4075"
        echo "  • API: http://localhost:4000/api/pools"
    else
        echo "  • Public Pool Ports:"
        echo "    - Standard:  your-domain.com:4444 (non-SSL)"
        echo "    - Medium:    your-domain.com:5555 (non-SSL)"
        echo "    - High:      your-domain.com:7777 (SSL)"
        echo "    - Extreme:   your-domain.com:8888 (SSL)"
        echo "  • Web: https://your-domain.com"
        echo "  • API: https://your-domain.com/api/pools"
    fi
    
    # Show resource usage
    echo ""
    log_info "💾 Resource Usage:"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" $(docker-compose -f "$compose_file" ps -q) 2>/dev/null || echo "  Unable to fetch stats"
    
    # Show health status
    echo ""
    log_info "🏥 Health Status:"
    
    if command -v curl &> /dev/null; then
        local api_url
        if [ "$mode" = "solo" ]; then
            api_url="http://localhost:4000/api/pools"
        else
            api_url="http://localhost/api/pools"
        fi
        
        if curl -s "$api_url" > /dev/null; then
            echo "  ✅ API is responding"
        else
            echo "  ❌ API is not responding"
        fi
    fi
}

show_logs() {
    local service=$1
    local mode=$(detect_mode)
    
    if [ -z "$mode" ]; then
        log_error "No pools are currently running"
        return 1
    fi
    
    local compose_file=$(get_compose_file "$mode")
    
    cd "$PROJECT_ROOT"
    
    if [ -n "$service" ]; then
        log_info "Showing logs for service: $service"
        docker-compose -f "$compose_file" logs -f "$service"
    else
        log_info "Showing logs for all services"
        docker-compose -f "$compose_file" logs -f
    fi
}

update_containers() {
    local mode=$(detect_mode)
    
    log_step "Updating containers..."
    
    if [ -n "$mode" ]; then
        log_info "Stopping current pool..."
        stop_pool "$mode"
    fi
    
    cd "$PROJECT_ROOT"
    
    # Update both compose files
    for compose_file in "docker-compose.yml" "docker-compose.solo.yml"; do
        if [ -f "$compose_file" ]; then
            log_info "Updating $compose_file..."
            docker-compose -f "$compose_file" pull
            docker-compose -f "$compose_file" build --pull
        fi
    done
    
    if [ -n "$mode" ]; then
        log_info "Restarting pool in $mode mode..."
        start_pool "$mode"
    fi
    
    log_success "Update completed!"
}

backup_data() {
    local backup_dir="$PROJECT_ROOT/backups"
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local backup_file="$backup_dir/ergo_pool_backup_$timestamp.tar.gz"
    
    log_step "Creating backup..."
    
    mkdir -p "$backup_dir"
    
    cd "$PROJECT_ROOT"
    
    # Create backup
    tar -czf "$backup_file" \
        --exclude="logs/*.log" \
        --exclude="backups" \
        --exclude=".git" \
        config/ scripts/ ssl/ docker-compose*.yml .env* || true
    
    # Backup database if running
    local mode=$(detect_mode)
    if [ -n "$mode" ]; then
        local compose_file=$(get_compose_file "$mode")
        local postgres_container
        
        if [ "$mode" = "solo" ]; then
            postgres_container="ergo-miningcore-postgres-solo"
        else
            postgres_container="ergo-miningcore-postgres"
        fi
        
        if docker ps | grep -q "$postgres_container"; then
            log_info "Backing up database..."
            docker exec "$postgres_container" pg_dump -U miningcore miningcore > "$backup_dir/database_$timestamp.sql"
        fi
    fi
    
    log_success "Backup created: $backup_file"
}

manage_ssl() {
    local action=$1
    local domain=$2
    
    case $action in
        generate)
            log_step "Generating SSL certificates..."
            "$SCRIPT_DIR/generate-ssl.sh" "${domain:-localhost}"
            ;;
        renew)
            log_step "Renewing SSL certificates..."
            "$SCRIPT_DIR/renew-certs.sh"
            ;;
        check)
            local cert_file="$PROJECT_ROOT/ssl/live/your-domain.com/cert.pem"
            if [ -f "$cert_file" ]; then
                local days_left=$(openssl x509 -in "$cert_file" -noout -dates | grep notAfter | sed 's/notAfter=//' | xargs -I {} date -d {} +%s)
                local current_date=$(date +%s)
                local days_to_expiry=$(( (days_left - current_date) / 86400 ))
                
                log_info "SSL Certificate Status:"
                echo "  File: $cert_file"
                echo "  Days until expiry: $days_to_expiry"
                
                if [ $days_to_expiry -lt 30 ]; then
                    log_warning "Certificate expires soon!"
                else
                    log_success "Certificate is valid"
                fi
            else
                log_error "No SSL certificates found"
            fi
            ;;
        *)
            log_error "Unknown SSL action: $action"
            log_info "Available actions: generate, renew, check"
            ;;
    esac
}

health_check() {
    log_step "Running comprehensive health checks..."
    
    echo ""
    log_info "🔧 System Health:"
    
    # Check Docker
    if docker info &> /dev/null; then
        echo "  ✅ Docker daemon is running"
    else
        echo "  ❌ Docker daemon is not running"
        return 1
    fi
    
    # Check Ergo node
    if curl -s -X POST \
        -H "Content-Type: application/json" \
        -H "api_key: hello" \
        -d '{"jsonrpc":"2.0","method":"info","params":[],"id":1}' \
        "http://127.0.0.1:9053" > /dev/null; then
        echo "  ✅ Ergo node is accessible"
    else
        echo "  ❌ Ergo node is not accessible"
    fi
    
    # Check ports
    echo ""
    log_info "📡 Port Status:"
    local common_ports=(4444 5555 7777 8888 4074 4075 80 443)
    for port in "${common_ports[@]}"; do
        if ss -tulpn | grep -q ":$port "; then
            echo "  ✅ Port $port is in use"
        else
            echo "  ⭕ Port $port is available"
        fi
    done
    
    # Show pool status if running
    local mode=$(detect_mode)
    if [ -n "$mode" ]; then
        echo ""
        show_detailed_status
    fi
}

cleanup_system() {
    log_step "Cleaning up Docker resources..."
    
    # Remove stopped containers
    docker container prune -f
    
    # Remove unused images
    docker image prune -f
    
    # Remove unused volumes (be careful!)
    read -p "Remove unused volumes? This may delete data! (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker volume prune -f
    fi
    
    log_success "Cleanup completed!"
}

# Main execution
main() {
    if [ $# -eq 0 ]; then
        show_banner
        show_usage
        exit 0
    fi
    
    local command=$1
    shift
    
    cd "$PROJECT_ROOT"
    
    case $command in
        start)
            start_pool "$@"
            ;;
        stop)
            stop_pool "$@"
            ;;
        restart)
            restart_pool "$@"
            ;;
        status)
            show_detailed_status
            ;;
        logs)
            show_logs "$@"
            ;;
        update)
            update_containers
            ;;
        backup)
            backup_data
            ;;
        ssl)
            manage_ssl "$@"
            ;;
        health)
            health_check
            ;;
        cleanup)
            cleanup_system
            ;;
        *)
            log_error "Unknown command: $command"
            show_usage
            exit 1
            ;;
    esac
}

# Execute main function
main "$@"
