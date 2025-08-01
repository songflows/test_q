#!/bin/bash

# =================================================================
# QUEUE MANAGEMENT SYSTEM - DATABASE INITIALIZATION SCRIPT
# =================================================================

set -e

echo "🗄️ Initializing Queue Management Database..."

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
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

# Wait for database to be ready
wait_for_db() {
    print_status "Waiting for database to be ready..."
    
    while ! pg_isready -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" > /dev/null 2>&1; do
        echo -n "."
        sleep 1
    done
    
    print_success "Database is ready!"
}

# Create database if it doesn't exist
create_database() {
    print_status "Creating database if it doesn't exist..."
    
    createdb -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" "$POSTGRES_DB" 2>/dev/null || {
        print_status "Database already exists or creation failed"
    }
}

# Run SQL initialization
run_init_sql() {
    if [ -f "/docker-entrypoint-initdb.d/init.sql" ]; then
        print_status "Running initialization SQL..."
        psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f /docker-entrypoint-initdb.d/init.sql
        print_success "Initialization SQL completed"
    fi
}

# Create sample data for development
create_sample_data() {
    if [ "$ENVIRONMENT" = "development" ]; then
        print_status "Creating sample data for development..."
        
        psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" <<EOF
-- Sample users
INSERT INTO users (email, full_name, hashed_password, auth_provider, is_active, is_verified) 
VALUES 
    ('admin@example.com', 'Admin User', '\$2b\$12\$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj1RpDX8G.Dy', 'email', true, true),
    ('user@example.com', 'Test User', '\$2b\$12\$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj1RpDX8G.Dy', 'email', true, true)
ON CONFLICT (email) DO NOTHING;

-- Sample points
INSERT INTO points (owner_id, name, description, address, latitude, longitude, status, accepts_online_orders, accepts_scheduled_orders)
VALUES 
    (1, 'Главный офис', 'Центральный офис обслуживания', 'ул. Пушкина, д. 1', 55.7558, 37.6176, 'active', true, true),
    (1, 'Филиал №2', 'Дополнительный офис', 'ул. Ленина, д. 10', 55.7558, 37.6176, 'active', true, false)
ON CONFLICT DO NOTHING;

-- Sample order statuses
INSERT INTO order_statuses (point_id, name, description, color, order_index, is_final)
VALUES 
    (1, 'В очереди', 'Ожидание обслуживания', '#FFA500', 0, false),
    (1, 'Обслуживается', 'Клиент у кассира', '#007AFF', 1, false),
    (1, 'Завершено', 'Обслуживание завершено', '#34C759', 2, true),
    (1, 'Отменено', 'Заказ отменен', '#FF3B30', 3, true)
ON CONFLICT DO NOTHING;

EOF
        
        print_success "Sample data created"
    fi
}

# Main execution
main() {
    # Set default values
    POSTGRES_HOST=${POSTGRES_HOST:-db}
    POSTGRES_PORT=${POSTGRES_PORT:-5432}
    POSTGRES_USER=${POSTGRES_USER:-postgres}
    POSTGRES_DB=${POSTGRES_DB:-queue_app}
    ENVIRONMENT=${ENVIRONMENT:-development}
    
    print_status "Database initialization started"
    print_status "Host: $POSTGRES_HOST:$POSTGRES_PORT"
    print_status "Database: $POSTGRES_DB"
    print_status "Environment: $ENVIRONMENT"
    
    wait_for_db
    create_database
    run_init_sql
    create_sample_data
    
    print_success "Database initialization completed!"
}

# Run main function
main "$@"