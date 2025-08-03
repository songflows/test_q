#!/bin/bash
set -e

# Функция для ожидания готовности базы данных
wait_for_db() {
    echo "Waiting for database to be ready..."
    while ! python -c "
import asyncpg
import asyncio
import os

async def check_db():
    try:
        conn = await asyncpg.connect(os.getenv('DATABASE_URL'))
        await conn.close()
        print('Database is ready!')
        return True
    except Exception as e:
        print(f'Database not ready: {e}')
        return False

if not asyncio.run(check_db()):
    exit(1)
" 2>/dev/null; do
        echo "Database is unavailable - sleeping..."
        sleep 2
    done
}

# Функция для ожидания готовности Redis
wait_for_redis() {
    echo "Waiting for Redis to be ready..."
    while ! python -c "
import redis
import os

try:
    r = redis.from_url(os.getenv('REDIS_URL', 'redis://redis:6379'))
    r.ping()
    print('Redis is ready!')
except Exception as e:
    print(f'Redis not ready: {e}')
    exit(1)
" 2>/dev/null; do
        echo "Redis is unavailable - sleeping..."
        sleep 2
    done
}

# Функция для запуска миграций
run_migrations() {
    echo "Running database migrations..."
    if [ -f "alembic.ini" ]; then
        alembic upgrade head
    else
        echo "No alembic.ini found, skipping migrations"
    fi
}

# Функция для создания таблиц
create_tables() {
    echo "Creating database tables..."
    python -c "
import asyncio
from app.core.database import create_tables
asyncio.run(create_tables())
"
}

# Основная логика выбора команды
case "$1" in
    "server")
        echo "Starting FastAPI server..."
        wait_for_db
        wait_for_redis
        create_tables
        exec uvicorn main:app --host 0.0.0.0 --port 8000
        ;;
    "server-dev")
        echo "Starting FastAPI server in development mode..."
        wait_for_db
        wait_for_redis
        create_tables
        exec uvicorn main:app --host 0.0.0.0 --port 8000 --reload
        ;;
    "migrate")
        echo "Running database migrations..."
        wait_for_db
        run_migrations
        ;;
    "create-tables")
        echo "Creating database tables..."
        wait_for_db
        create_tables
        ;;
    "shell")
        echo "Starting Python shell..."
        exec python
        ;;
    "bash")
        echo "Starting bash shell..."
        exec /bin/bash
        ;;
    "test")
        echo "Running tests..."
        wait_for_db
        wait_for_redis
        if [ -f "pytest.ini" ] || [ -f "pyproject.toml" ]; then
            exec pytest "${@:2}"
        else
            echo "No test configuration found"
            exit 1
        fi
        ;;
    "worker")
        echo "Starting background worker..."
        wait_for_db
        wait_for_redis
        # Здесь можно добавить команду для запуска Celery worker или другого worker'а
        echo "Worker functionality not implemented yet"
        ;;
    "scheduler")
        echo "Starting scheduler..."
        wait_for_db
        wait_for_redis
        # Здесь можно добавить команду для запуска Celery beat или другого scheduler'а
        echo "Scheduler functionality not implemented yet"
        ;;
    "manage")
        echo "Running management command: ${@:2}"
        wait_for_db
        wait_for_redis
        exec python -m app.cli "${@:2}"
        ;;
    *)
        echo "Available commands:"
        echo "  server          - Start production server"
        echo "  server-dev      - Start development server with reload"
        echo "  migrate         - Run database migrations"
        echo "  create-tables   - Create database tables"
        echo "  shell           - Start Python shell"
        echo "  bash            - Start bash shell"
        echo "  test            - Run tests"
        echo "  worker          - Start background worker"
        echo "  scheduler       - Start scheduler"
        echo "  manage          - Run management command"
        echo ""
        echo "Usage: docker-entrypoint.sh [command] [args...]"
        exit 1
        ;;
esac