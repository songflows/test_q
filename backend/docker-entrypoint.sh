#!/bin/bash
set -e

# Функция для ожидания доступности базы данных
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
        echo "Database is unavailable - sleeping"
        sleep 2
    done
}

# Функция для ожидания доступности Redis
wait_for_redis() {
    echo "Waiting for Redis to be ready..."
    while ! python -c "
import redis
import os

try:
    r = redis.Redis.from_url(os.getenv('REDIS_URL'))
    r.ping()
    print('Redis is ready!')
except Exception as e:
    print(f'Redis not ready: {e}')
    exit(1)
" 2>/dev/null; do
        echo "Redis is unavailable - sleeping"
        sleep 2
    done
}

# Основная логика выбора команды
case "$1" in
    "dev")
        echo "Starting development server..."
        wait_for_db
        wait_for_redis
        # Применяем миграции
        alembic upgrade head
        # Запускаем сервер в режиме разработки с автоперезагрузкой
        exec uvicorn main:app --host 0.0.0.0 --port 8000 --reload
        ;;
    "prod")
        echo "Starting production server..."
        wait_for_db
        wait_for_redis
        # Применяем миграции
        alembic upgrade head
        # Запускаем сервер в продакшн режиме
        exec uvicorn main:app --host 0.0.0.0 --port 8000 --workers 4
        ;;
    "migrate")
        echo "Running database migrations..."
        wait_for_db
        exec alembic upgrade head
        ;;
    "migrate-create")
        echo "Creating new migration..."
        if [ -z "$2" ]; then
            echo "Usage: docker-compose run backend migrate-create <migration_name>"
            exit 1
        fi
        wait_for_db
        exec alembic revision --autogenerate -m "$2"
        ;;
    "shell")
        echo "Starting Python shell..."
        exec python -i -c "
import asyncio
from sqlalchemy import create_engine
from app.core.database import SessionLocal
from app.models import *
print('Database models imported. Use SessionLocal() for database session.')
"
        ;;
    "test")
        echo "Running tests..."
        wait_for_db
        wait_for_redis
        # Устанавливаем тестовую базу данных
        export DATABASE_URL="${DATABASE_URL}_test"
        # Применяем миграции для тестовой БД
        alembic upgrade head
        # Запускаем тесты
        exec python -m pytest "${@:2}"
        ;;
    "lint")
        echo "Running code linting..."
        exec python -m flake8 . --count --select=E9,F63,F7,F82 --show-source --statistics
        ;;
    "format")
        echo "Formatting code..."
        exec python -m black . --check
        ;;
    "format-fix")
        echo "Fixing code formatting..."
        exec python -m black .
        ;;
    "seed")
        echo "Seeding database with initial data..."
        wait_for_db
        wait_for_redis
        # Применяем миграции
        alembic upgrade head
        # Запускаем скрипт для наполнения БД данными
        exec python -c "
import asyncio
from app.core.database import SessionLocal
from app.services.seed_data import seed_database

async def main():
    db = SessionLocal()
    try:
        await seed_database(db)
        print('Database seeded successfully!')
    finally:
        await db.close()

asyncio.run(main())
"
        ;;
    "reset-db")
        echo "Resetting database..."
        wait_for_db
        # Сбрасываем все миграции
        alembic downgrade base
        # Применяем заново
        alembic upgrade head
        echo "Database reset completed!"
        ;;
    "install-deps")
        echo "Installing dependencies..."
        exec pip install -r requirements.txt
        ;;
    "bash")
        echo "Starting bash shell..."
        exec /bin/bash
        ;;
    *)
        echo "Available commands:"
        echo "  dev              - Start development server with auto-reload"
        echo "  prod             - Start production server"
        echo "  migrate          - Run database migrations"
        echo "  migrate-create   - Create new migration (requires migration name)"
        echo "  shell            - Start Python shell with models loaded"
        echo "  test             - Run tests"
        echo "  lint             - Run code linting"
        echo "  format           - Check code formatting"
        echo "  format-fix       - Fix code formatting"
        echo "  seed             - Seed database with initial data"
        echo "  reset-db         - Reset database (drop and recreate)"
        echo "  install-deps     - Install Python dependencies"
        echo "  bash             - Start bash shell"
        echo ""
        echo "Usage: docker-compose run backend <command>"
        echo "Example: docker-compose run backend dev"
        
        if [ $# -eq 0 ]; then
            echo "No command provided, starting development server by default..."
            exec "$0" dev
        else
            echo "Unknown command: $1"
            exit 1
        fi
        ;;
esac