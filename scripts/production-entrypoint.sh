#!/bin/bash

# =================================================================
# QUEUE MANAGEMENT SYSTEM - PRODUCTION ENTRYPOINT
# =================================================================

set -e

echo "🚀 Starting Queue Management System in PRODUCTION mode..."

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Validate production environment
validate_production_env() {
    print_status "Validating production environment..."
    
    local errors=0
    
    # Check required environment variables
    if [ -z "$SECRET_KEY" ] || [ "$SECRET_KEY" = "your-super-secret-key-change-in-production" ]; then
        print_error "SECRET_KEY must be set to a secure value in production!"
        errors=$((errors + 1))
    fi
    
    if [ -z "$DATABASE_URL" ]; then
        print_error "DATABASE_URL must be set!"
        errors=$((errors + 1))
    fi
    
    if [ "$DEBUG" = "true" ]; then
        print_warning "DEBUG is enabled in production!"
    fi
    
    if [ -z "$ALLOWED_HOSTS" ] || [ "$ALLOWED_HOSTS" = '["*"]' ]; then
        print_warning "ALLOWED_HOSTS should be restricted in production!"
    fi
    
    # Check SSL configuration
    if [ -z "$SSL_CERT_PATH" ] && [ -z "$SSL_KEY_PATH" ]; then
        print_warning "SSL certificates not configured - using HTTP only"
    fi
    
    if [ $errors -gt 0 ]; then
        print_error "Production validation failed with $errors errors!"
        exit 1
    fi
    
    print_success "Production environment validation passed"
}

# Wait for services with timeout
wait_for_services() {
    print_status "Waiting for required services..."
    
    local max_attempts=60
    local attempt=0
    
    # Wait for database
    while ! nc -z db 5432 > /dev/null 2>&1; do
        attempt=$((attempt + 1))
        if [ $attempt -ge $max_attempts ]; then
            print_error "Database not available after $max_attempts attempts"
            exit 1
        fi
        echo -n "."
        sleep 1
    done
    print_success "Database is ready"
    
    # Wait for Redis
    attempt=0
    while ! nc -z redis 6379 > /dev/null 2>&1; do
        attempt=$((attempt + 1))
        if [ $attempt -ge $max_attempts ]; then
            print_error "Redis not available after $max_attempts attempts"
            exit 1
        fi
        echo -n "."
        sleep 1
    done
    print_success "Redis is ready"
}

# Run database migrations
run_migrations() {
    print_status "Running database migrations..."
    
    # Check if alembic is configured
    if [ ! -f "alembic.ini" ]; then
        print_error "Alembic configuration not found!"
        exit 1
    fi
    
    # Run migrations with retry
    local max_retries=3
    local retry=0
    
    while [ $retry -lt $max_retries ]; do
        if alembic upgrade head; then
            print_success "Database migrations completed"
            return 0
        else
            retry=$((retry + 1))
            print_warning "Migration attempt $retry failed, retrying..."
            sleep 5
        fi
    done
    
    print_error "Database migrations failed after $max_retries attempts"
    exit 1
}

# Optimize for production
optimize_for_production() {
    print_status "Applying production optimizations..."
    
    # Set optimal Python settings
    export PYTHONUNBUFFERED=1
    export PYTHONDONTWRITEBYTECODE=1
    
    # Set optimal logging level
    export LOG_LEVEL=${LOG_LEVEL:-INFO}
    
    # Disable development features
    export DEBUG=false
    export RELOAD=false
    
    print_success "Production optimizations applied"
}

# Health check endpoint
setup_health_check() {
    print_status "Setting up health check..."
    
    # Create health check script
    cat > /tmp/health-check.py << 'EOF'
import asyncio
import sys
import httpx
from sqlalchemy.ext.asyncio import create_async_engine
import redis.asyncio as redis

async def check_health():
    try:
        # Check database
        engine = create_async_engine("${DATABASE_URL}")
        async with engine.begin() as conn:
            await conn.execute("SELECT 1")
        await engine.dispose()
        
        # Check Redis
        redis_client = redis.from_url("${REDIS_URL}")
        await redis_client.ping()
        await redis_client.close()
        
        # Check API
        async with httpx.AsyncClient() as client:
            response = await client.get("http://localhost:8000/health", timeout=5.0)
            if response.status_code != 200:
                sys.exit(1)
        
        print("✅ All services healthy")
        sys.exit(0)
        
    except Exception as e:
        print(f"❌ Health check failed: {e}")
        sys.exit(1)

asyncio.run(check_health())
EOF
    
    chmod +x /tmp/health-check.py
    print_success "Health check configured"
}

# Setup monitoring
setup_monitoring() {
    print_status "Setting up monitoring..."
    
    # Create monitoring directory
    mkdir -p /app/monitoring
    
    # Setup log rotation
    if command -v logrotate > /dev/null; then
        cat > /etc/logrotate.d/queue-app << 'EOF'
/app/logs/*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 644 appuser appgroup
}
EOF
    fi
    
    print_success "Monitoring configured"
}

# Graceful shutdown handler
graceful_shutdown() {
    print_warning "Received shutdown signal..."
    
    # Kill gunicorn gracefully
    if [ -n "$GUNICORN_PID" ]; then
        print_status "Stopping Gunicorn (PID: $GUNICORN_PID)..."
        kill -TERM "$GUNICORN_PID"
        wait "$GUNICORN_PID"
    fi
    
    print_success "Graceful shutdown completed"
    exit 0
}

# Start application with Gunicorn
start_application() {
    print_status "Starting application with Gunicorn..."
    
    # Gunicorn configuration
    local workers=${WORKERS:-4}
    local worker_connections=${WORKER_CONNECTIONS:-1000}
    local max_requests=${MAX_REQUESTS:-1000}
    local max_requests_jitter=${MAX_REQUESTS_JITTER:-100}
    local timeout=${TIMEOUT:-30}
    local keepalive=${KEEPALIVE:-2}
    
    print_status "Configuration:"
    print_status "  Workers: $workers"
    print_status "  Worker connections: $worker_connections"
    print_status "  Max requests per worker: $max_requests"
    print_status "  Timeout: ${timeout}s"
    
    # Start Gunicorn
    exec gunicorn main:app \
        --workers "$workers" \
        --worker-class uvicorn.workers.UvicornWorker \
        --worker-connections "$worker_connections" \
        --max-requests "$max_requests" \
        --max-requests-jitter "$max_requests_jitter" \
        --timeout "$timeout" \
        --keepalive "$keepalive" \
        --bind 0.0.0.0:8000 \
        --access-logfile - \
        --error-logfile - \
        --log-level info \
        --capture-output \
        --enable-stdio-inheritance \
        --preload &
    
    GUNICORN_PID=$!
    print_success "Application started (PID: $GUNICORN_PID)"
    
    # Wait for application to start
    sleep 5
    
    # Verify application is running
    if ! python /tmp/health-check.py; then
        print_error "Application health check failed!"
        exit 1
    fi
    
    print_success "Application is healthy and ready to serve requests! 🎉"
    
    # Wait for Gunicorn process
    wait "$GUNICORN_PID"
}

# Main execution
main() {
    print_status "Environment: PRODUCTION"
    print_status "Starting Queue Management System..."
    
    # Set production environment
    export ENVIRONMENT=production
    
    # Install required tools
    apk add --no-cache netcat-openbsd curl > /dev/null 2>&1 || {
        apt-get update > /dev/null 2>&1 && apt-get install -y netcat-openbsd curl > /dev/null 2>&1
    }
    
    # Validate environment
    validate_production_env
    
    # Wait for dependencies
    wait_for_services
    
    # Apply optimizations
    optimize_for_production
    
    # Setup application
    run_migrations
    setup_health_check
    setup_monitoring
    
    # Setup signal handlers
    trap graceful_shutdown SIGTERM SIGINT
    
    print_success "Production setup completed!"
    print_status "Starting application server..."
    
    # Start the application
    start_application
}

# Execute main function
main "$@"