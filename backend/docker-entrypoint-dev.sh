#!/bin/bash

# =================================================================
# QUEUE MANAGEMENT SYSTEM - DEVELOPMENT ENTRYPOINT
# =================================================================

set -e

echo "🚀 Starting Queue Management Backend in DEVELOPMENT mode..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
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

print_dev() {
    echo -e "${PURPLE}[DEV]${NC} $1"
}

print_debug() {
    echo -e "${CYAN}[DEBUG]${NC} $1"
}

# Banner
show_banner() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    QUEUE MANAGEMENT SYSTEM                  ║"
    echo "║                      DEVELOPMENT MODE                       ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Development environment check
check_dev_environment() {
    print_dev "Checking development environment..."
    
    # Check if we're in development mode
    if [ "$ENVIRONMENT" != "development" ]; then
        print_warning "ENVIRONMENT is not set to 'development'. Setting it now..."
        export ENVIRONMENT=development
    fi
    
    # Enable debug mode
    export DEBUG=true
    
    # Check for development tools
    local tools=("pytest" "black" "flake8" "isort")
    for tool in "${tools[@]}"; do
        if command -v $tool > /dev/null; then
            print_debug "$tool is available"
        else
            print_warning "$tool is not installed"
        fi
    done
    
    print_success "Development environment checked"
}

# Install development dependencies
install_dev_tools() {
    print_dev "Installing development tools..."
    
    # Install pre-commit hooks if available
    if [ -f ".pre-commit-config.yaml" ]; then
        print_dev "Installing pre-commit hooks..."
        pre-commit install || print_warning "Pre-commit installation failed"
    fi
    
    # Install additional development packages
    pip install --no-cache-dir \
        ipython \
        jupyter \
        matplotlib \
        pandas \
        requests-toolbelt \
        debugpy \
        2>/dev/null || print_warning "Some dev packages failed to install"
    
    print_success "Development tools installed"
}

# Setup development database with sample data
setup_dev_database() {
    print_dev "Setting up development database with sample data..."
    
    # Wait for database
    local max_attempts=30
    local attempt=0
    
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
    
    # Run migrations
    print_dev "Running development migrations..."
    alembic upgrade head || {
        print_dev "Creating initial migration..."
        alembic revision --autogenerate -m "Initial development migration"
        alembic upgrade head
    }
    
    # Create sample data
    print_dev "Creating sample development data..."
    python -c "
import asyncio
import bcrypt
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import AsyncSessionLocal, engine, Base
from app.models.user import User, AuthProviderEnum
from app.models.point import Point, PointStatusEnum
from app.models.cashier import Cashier, CashierStatusEnum
from app.models.order import OrderStatus

async def create_sample_data():
    # Create tables
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    
    async with AsyncSessionLocal() as session:
        # Check if data already exists
        result = await session.execute('SELECT COUNT(*) FROM users')
        user_count = result.scalar()
        
        if user_count > 0:
            print('📊 Sample data already exists, skipping...')
            return
        
        print('👥 Creating sample users...')
        
        # Hash password for demo users
        password_hash = bcrypt.hashpw('demo123'.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
        
        # Create demo users
        admin_user = User(
            email='admin@demo.com',
            full_name='Admin User',
            hashed_password=password_hash,
            auth_provider=AuthProviderEnum.EMAIL,
            is_active=True,
            is_verified=True
        )
        session.add(admin_user)
        
        regular_user = User(
            email='user@demo.com', 
            full_name='Demo User',
            hashed_password=password_hash,
            auth_provider=AuthProviderEnum.EMAIL,
            is_active=True,
            is_verified=True
        )
        session.add(regular_user)
        
        await session.commit()
        await session.refresh(admin_user)
        
        print('🏢 Creating sample points...')
        
        # Create demo points
        main_office = Point(
            owner_id=admin_user.id,
            name='Главный офис',
            description='Центральный офис обслуживания клиентов',
            detailed_description='Полный спектр услуг для физических и юридических лиц',
            address='ул. Пушкина, д. 1, Москва',
            latitude=55.7558,
            longitude=37.6176,
            status=PointStatusEnum.ACTIVE,
            accepts_online_orders=True,
            accepts_scheduled_orders=True,
            working_hours={
                'monday': {'start': '09:00', 'end': '18:00', 'is_closed': False},
                'tuesday': {'start': '09:00', 'end': '18:00', 'is_closed': False},
                'wednesday': {'start': '09:00', 'end': '18:00', 'is_closed': False},
                'thursday': {'start': '09:00', 'end': '18:00', 'is_closed': False},
                'friday': {'start': '09:00', 'end': '18:00', 'is_closed': False},
                'saturday': {'start': '10:00', 'end': '16:00', 'is_closed': False},
                'sunday': {'start': '00:00', 'end': '00:00', 'is_closed': True}
            }
        )
        session.add(main_office)
        
        branch_office = Point(
            owner_id=admin_user.id,
            name='Филиал №2',
            description='Дополнительный офис в центре города',
            address='ул. Ленина, д. 10, Москва',
            latitude=55.7500,
            longitude=37.6200,
            status=PointStatusEnum.ACTIVE,
            accepts_online_orders=True,
            accepts_scheduled_orders=False
        )
        session.add(branch_office)
        
        await session.commit()
        await session.refresh(main_office)
        await session.refresh(branch_office)
        
        print('👨‍💼 Creating sample cashiers...')
        
        # Create cashiers
        cashier1 = Cashier(
            point_id=main_office.id,
            number='001',
            name='Касса №1',
            status=CashierStatusEnum.AVAILABLE
        )
        session.add(cashier1)
        
        cashier2 = Cashier(
            point_id=main_office.id,
            number='002', 
            name='Касса №2',
            status=CashierStatusEnum.AVAILABLE
        )
        session.add(cashier2)
        
        cashier3 = Cashier(
            point_id=branch_office.id,
            number='001',
            name='Касса №1',
            status=CashierStatusEnum.AVAILABLE
        )
        session.add(cashier3)
        
        await session.commit()
        
        print('📋 Creating order statuses...')
        
        # Create order statuses for main office
        statuses = [
            ('В очереди', 'Ожидание обслуживания', '#FFA500', 0, False),
            ('Обслуживается', 'Клиент у кассира', '#007AFF', 1, False),
            ('В работе', 'Заявка обрабатывается', '#FF9500', 2, False),
            ('Сборка', 'Подготовка документов', '#32ADE6', 3, False),
            ('Завершено', 'Обслуживание завершено', '#34C759', 4, True),
            ('Отменено', 'Заказ отменен', '#FF3B30', 5, True)
        ]
        
        for name, desc, color, order_idx, is_final in statuses:
            status = OrderStatus(
                point_id=main_office.id,
                name=name,
                description=desc,
                color=color,
                order_index=order_idx,
                is_final=is_final
            )
            session.add(status)
        
        # Create basic statuses for branch office
        basic_statuses = [
            ('В очереди', 'Ожидание', '#FFA500', 0, False),
            ('Обслуживается', 'У кассира', '#007AFF', 1, False),
            ('Завершено', 'Готово', '#34C759', 2, True)
        ]
        
        for name, desc, color, order_idx, is_final in basic_statuses:
            status = OrderStatus(
                point_id=branch_office.id,
                name=name,
                description=desc,
                color=color,
                order_index=order_idx,
                is_final=is_final
            )
            session.add(status)
        
        await session.commit()
        
        print('✅ Sample development data created successfully!')
        print('📧 Demo login credentials:')
        print('   Admin: admin@demo.com / demo123')
        print('   User:  user@demo.com / demo123')

asyncio.run(create_sample_data())
" || print_warning "Sample data creation failed"
    
    print_success "Development database setup completed"
}

# Setup development file watchers
setup_file_watchers() {
    print_dev "Setting up file watchers for development..."
    
    # Create directory for file watchers
    mkdir -p /tmp/watchers
    
    # Setup code formatting watcher (if tools are available)
    if command -v inotifywait > /dev/null; then
        print_dev "Setting up automatic code formatting..."
        (
            while inotifywait -r -e modify app/ 2>/dev/null; do
                black app/ --quiet 2>/dev/null || true
                isort app/ --quiet 2>/dev/null || true
            done
        ) &
        echo $! > /tmp/watchers/formatter.pid
    fi
    
    print_success "File watchers configured"
}

# Print development information
print_dev_info() {
    print_dev "Development Environment Information:"
    print_debug "Python version: $(python --version)"
    print_debug "FastAPI available: $(python -c 'import fastapi; print(fastapi.__version__)' 2>/dev/null || echo 'Not available')"
    print_debug "Working directory: $(pwd)"
    print_debug "Environment: $ENVIRONMENT"
    print_debug "Debug mode: $DEBUG"
    
    print_dev "Available endpoints:"
    print_debug "  • API Documentation: http://localhost:8000/docs"
    print_debug "  • Alternative Docs: http://localhost:8000/redoc"
    print_debug "  • Health Check: http://localhost:8000/health"
    print_debug "  • OpenAPI Schema: http://localhost:8000/openapi.json"
    
    if [ -f "pytest.ini" ] || [ -f "pyproject.toml" ]; then
        print_dev "Testing available:"
        print_debug "  • Run tests: pytest"
        print_debug "  • With coverage: pytest --cov=app"
        print_debug "  • Watch mode: pytest -f"
    fi
}

# Start development server with hot reload
start_dev_server() {
    print_dev "Starting development server with hot reload..."
    
    # Add current directory to Python path
    export PYTHONPATH="/app:$PYTHONPATH"
    
    # Start with uvicorn in development mode
    exec uvicorn main:app \
        --host 0.0.0.0 \
        --port 8000 \
        --reload \
        --reload-dir /app \
        --log-level debug \
        --access-log \
        --use-colors
}

# Main execution
main() {
    show_banner
    
    print_status "Starting development setup..."
    
    # Install system dependencies
    apk add --no-cache inotify-tools netcat-openbsd curl > /dev/null 2>&1 || {
        apt-get update > /dev/null 2>&1 && apt-get install -y inotify-tools netcat-openbsd curl > /dev/null 2>&1
    } || print_warning "Could not install system dependencies"
    
    # Setup development environment
    check_dev_environment
    install_dev_tools
    setup_dev_database
    setup_file_watchers
    
    print_success "Development setup completed!"
    print_dev_info
    
    # Start the development server
    start_dev_server
}

# Handle cleanup on exit
cleanup() {
    print_warning "Cleaning up development environment..."
    
    # Kill file watchers
    if [ -f "/tmp/watchers/formatter.pid" ]; then
        kill $(cat /tmp/watchers/formatter.pid) 2>/dev/null || true
        rm -f /tmp/watchers/formatter.pid
    fi
    
    print_success "Development cleanup completed"
    exit 0
}

# Setup signal handlers
trap cleanup SIGTERM SIGINT

# Execute main function
main "$@"