#!/bin/bash

# =================================================================
# QUEUE MANAGEMENT SYSTEM - TEST ENTRYPOINT
# =================================================================

set -e

echo "🧪 Starting Queue Management Tests..."

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

# Wait for services
wait_for_services() {
    print_status "Waiting for required services..."
    
    # Wait for database
    while ! nc -z db 5432 > /dev/null 2>&1; do
        echo -n "."
        sleep 1
    done
    print_success "Database is ready"
    
    # Wait for Redis
    while ! nc -z redis 6379 > /dev/null 2>&1; do
        echo -n "."
        sleep 1
    done
    print_success "Redis is ready"
}

# Setup test database
setup_test_db() {
    print_status "Setting up test database..."
    
    # Create test database
    createdb -h db -U postgres queue_app_test 2>/dev/null || {
        print_warning "Test database already exists"
    }
    
    # Export test database URL
    export DATABASE_URL="postgresql://postgres:postgres@db:5432/queue_app_test"
    export REDIS_URL="redis://redis:6379/1"  # Use different Redis DB for tests
    
    print_success "Test database setup completed"
}

# Run migrations for test database
run_test_migrations() {
    print_status "Running test database migrations..."
    
    # Update alembic.ini for test database
    if [ -f "alembic.ini" ]; then
        sed -i "s|sqlalchemy.url = .*|sqlalchemy.url = ${DATABASE_URL}|g" alembic.ini
    fi
    
    # Run migrations
    alembic upgrade head || {
        print_warning "Migrations failed, creating tables directly..."
        python -c "
import asyncio
from app.core.database import engine, Base
from app.models import user, point, cashier, order

async def create_tables():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

asyncio.run(create_tables())
"
    }
    
    print_success "Test migrations completed"
}

# Run code quality checks
run_quality_checks() {
    print_status "Running code quality checks..."
    
    # Run linting
    print_status "Running flake8..."
    flake8 app/ --max-line-length=100 --exclude=__pycache__,migrations || {
        print_warning "Linting issues found"
    }
    
    # Run type checking
    if command -v mypy > /dev/null; then
        print_status "Running mypy..."
        mypy app/ --ignore-missing-imports || {
            print_warning "Type checking issues found"
        }
    fi
    
    # Check imports
    print_status "Checking import order..."
    isort app/ --check-only --diff || {
        print_warning "Import order issues found"
        print_status "Running isort to fix imports..."
        isort app/
    }
    
    # Check code formatting
    print_status "Checking code formatting..."
    black app/ --check || {
        print_warning "Code formatting issues found"
        print_status "Running black to format code..."
        black app/
    }
    
    print_success "Code quality checks completed"
}

# Run tests
run_tests() {
    print_status "Running tests..."
    
    # Test options
    TEST_OPTIONS=""
    
    # Add coverage if requested
    if [ "$WITH_COVERAGE" = "true" ]; then
        TEST_OPTIONS="--cov=app --cov-report=html --cov-report=term"
    fi
    
    # Add verbose output if requested
    if [ "$VERBOSE" = "true" ]; then
        TEST_OPTIONS="$TEST_OPTIONS -v"
    fi
    
    # Run specific test if provided
    if [ -n "$TEST_PATH" ]; then
        TEST_OPTIONS="$TEST_OPTIONS $TEST_PATH"
    fi
    
    # Run pytest
    pytest $TEST_OPTIONS || {
        print_error "Tests failed!"
        exit 1
    }
    
    print_success "All tests passed!"
}

# Generate test report
generate_report() {
    if [ "$WITH_COVERAGE" = "true" ]; then
        print_status "Generating test report..."
        
        # Coverage report
        coverage xml || print_warning "Failed to generate XML coverage report"
        coverage json || print_warning "Failed to generate JSON coverage report"
        
        # Show coverage summary
        coverage report --show-missing
        
        print_success "Test report generated in htmlcov/"
    fi
}

# Cleanup
cleanup() {
    print_status "Cleaning up test environment..."
    
    # Drop test database
    dropdb -h db -U postgres queue_app_test 2>/dev/null || {
        print_warning "Could not drop test database"
    }
    
    print_success "Cleanup completed"
}

# Main execution
main() {
    print_status "Test environment: ${ENVIRONMENT:-test}"
    
    # Set test environment variables
    export ENVIRONMENT=test
    export DEBUG=false
    
    # Install netcat for service checking
    apk add --no-cache netcat-openbsd > /dev/null 2>&1 || {
        apt-get update > /dev/null 2>&1 && apt-get install -y netcat-openbsd > /dev/null 2>&1
    } || print_warning "Could not install netcat"
    
    # Wait for services
    wait_for_services
    
    # Setup test environment
    setup_test_db
    run_test_migrations
    
    # Run quality checks if requested
    if [ "$SKIP_QUALITY" != "true" ]; then
        run_quality_checks
    fi
    
    # Run tests
    run_tests
    
    # Generate reports
    generate_report
    
    # Cleanup unless KEEP_DB is set
    if [ "$KEEP_DB" != "true" ]; then
        cleanup
    fi
    
    print_success "Test suite completed successfully! 🎉"
}

# Handle signals for cleanup
trap cleanup SIGTERM SIGINT

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --coverage)
            export WITH_COVERAGE=true
            shift
            ;;
        --verbose)
            export VERBOSE=true
            shift
            ;;
        --skip-quality)
            export SKIP_QUALITY=true
            shift
            ;;
        --keep-db)
            export KEEP_DB=true
            shift
            ;;
        --path)
            export TEST_PATH="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--coverage] [--verbose] [--skip-quality] [--keep-db] [--path <test_path>]"
            exit 1
            ;;
    esac
done

# Execute main function
main "$@"