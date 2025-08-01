#!/bin/bash

# =================================================================
# QUEUE MANAGEMENT SYSTEM - BACKEND ENTRYPOINT
# =================================================================

set -e

echo "🚀 Starting Queue Management Backend..."

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

# Function to wait for service
wait_for_service() {
    local host=$1
    local port=$2
    local service_name=$3
    local timeout=${4:-30}
    
    print_status "Waiting for $service_name to be ready..."
    
    for i in $(seq 1 $timeout); do
        if nc -z $host $port > /dev/null 2>&1; then
            print_success "$service_name is ready!"
            return 0
        fi
        echo -n "."
        sleep 1
    done
    
    print_error "$service_name is not ready after ${timeout}s"
    return 1
}

# Function to wait for database
wait_for_database() {
    print_status "Waiting for PostgreSQL database..."
    
    DB_HOST=$(echo $DATABASE_URL | cut -d'@' -f2 | cut -d':' -f1)
    DB_PORT=$(echo $DATABASE_URL | cut -d':' -f4 | cut -d'/' -f1)
    
    wait_for_service $DB_HOST $DB_PORT "PostgreSQL" 60
}

# Function to wait for Redis
wait_for_redis() {
    print_status "Waiting for Redis..."
    
    REDIS_HOST=$(echo $REDIS_URL | cut -d'@' -f2 | cut -d':' -f1)
    REDIS_PORT=$(echo $REDIS_URL | cut -d':' -f3)
    
    wait_for_service $REDIS_HOST $REDIS_PORT "Redis" 30
}

# Function to run database migrations
run_migrations() {
    print_status "Running database migrations..."
    
    # Check if alembic is configured
    if [ ! -f "alembic.ini" ]; then
        print_warning "Alembic not configured, initializing..."
        alembic init alembic
        
        # Update alembic.ini with database URL
        sed -i "s|sqlalchemy.url = driver://user:pass@localhost/dbname|sqlalchemy.url = ${DATABASE_URL}|g" alembic.ini
    fi
    
    # Run migrations
    alembic upgrade head || {
        print_warning "Migration failed, creating initial migration..."
        alembic revision --autogenerate -m "Initial migration"
        alembic upgrade head
    }
    
    print_success "Database migrations completed"
}

# Function to create initial data
create_initial_data() {
    print_status "Creating initial data..."
    
    python -c "
import asyncio
from app.core.database import engine, Base
from app.models import user, point, cashier, order

async def create_tables():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    print('✅ Database tables created successfully')

asyncio.run(create_tables())
" || print_warning "Initial data creation skipped"
}

# Function to install dependencies in development
install_dev_dependencies() {
    if [ "$ENVIRONMENT" = "development" ]; then
        print_status "Installing development dependencies..."
        pip install -r requirements-dev.txt 2>/dev/null || print_warning "No dev requirements found"
    fi
}

# Function to start the application
start_application() {
    print_status "Starting FastAPI application..."
    
    if [ "$ENVIRONMENT" = "production" ]; then
        print_status "Starting in PRODUCTION mode with Gunicorn..."
        exec gunicorn main:app \
            --workers 4 \
            --worker-class uvicorn.workers.UvicornWorker \
            --bind 0.0.0.0:8000 \
            --access-logfile - \
            --error-logfile - \
            --log-level info
    else
        print_status "Starting in DEVELOPMENT mode with Uvicorn..."
        exec uvicorn main:app \
            --host 0.0.0.0 \
            --port 8000 \
            --reload \
            --log-level debug
    fi
}

# Main execution flow
main() {
    print_status "Environment: $ENVIRONMENT"
    print_status "Debug mode: $DEBUG"
    
    # Install netcat for service checking
    apk add --no-cache netcat-openbsd curl > /dev/null 2>&1 || {
        apt-get update > /dev/null 2>&1 && apt-get install -y netcat-openbsd curl > /dev/null 2>&1
    } || print_warning "Could not install netcat/curl"
    
    # Wait for dependent services
    wait_for_database
    wait_for_redis
    
    # Install development dependencies if needed
    install_dev_dependencies
    
    # Setup database
    run_migrations
    create_initial_data
    
    # Create uploads directory
    mkdir -p uploads
    chmod 755 uploads
    
    print_success "Backend initialization completed!"
    print_status "API Documentation will be available at:"
    print_status "  • Swagger UI: http://localhost:8000/docs"
    print_status "  • ReDoc: http://localhost:8000/redoc"
    
    # Start the application
    start_application
}

# Handle signals for graceful shutdown
trap 'print_warning "Received shutdown signal, stopping..."; exit 0' SIGTERM SIGINT

# Execute main function
main "$@"