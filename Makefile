# =================================================================
# QUEUE MANAGEMENT SYSTEM - MAKEFILE
# =================================================================

.PHONY: help build up down logs shell test clean dev prod

# Variables
COMPOSE_FILE = docker-compose.yml
COMPOSE_DEV = --profile development
COMPOSE_PROD = --profile production
SERVICE_BACKEND = backend
SERVICE_DB = db
SERVICE_REDIS = redis

# Default target
help: ## Show this help message
	@echo "Queue Management System - Available commands:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# =================================================================
# DEVELOPMENT COMMANDS
# =================================================================

dev: ## Start development environment
	@echo "🚀 Starting development environment..."
	docker-compose $(COMPOSE_DEV) up -d

dev-build: ## Build and start development environment
	@echo "🔨 Building and starting development environment..."
	docker-compose $(COMPOSE_DEV) up -d --build

dev-logs: ## Show development logs
	docker-compose $(COMPOSE_DEV) logs -f

dev-shell: ## Access backend shell in development
	docker-compose exec $(SERVICE_BACKEND) /bin/bash

# =================================================================
# PRODUCTION COMMANDS
# =================================================================

prod: ## Start production environment
	@echo "🚀 Starting production environment..."
	docker-compose $(COMPOSE_PROD) up -d

prod-build: ## Build and start production environment
	@echo "🔨 Building and starting production environment..."
	docker-compose $(COMPOSE_PROD) up -d --build

prod-logs: ## Show production logs
	docker-compose $(COMPOSE_PROD) logs -f

# =================================================================
# GENERAL COMMANDS
# =================================================================

build: ## Build all services
	@echo "🔨 Building all services..."
	docker-compose build

up: ## Start all services
	@echo "🚀 Starting all services..."
	docker-compose up -d

down: ## Stop all services
	@echo "🛑 Stopping all services..."
	docker-compose down

restart: ## Restart all services
	@echo "🔄 Restarting all services..."
	docker-compose restart

logs: ## Show logs from all services
	docker-compose logs -f

# =================================================================
# DATABASE COMMANDS
# =================================================================

db-shell: ## Access database shell
	docker-compose exec $(SERVICE_DB) psql -U postgres -d queue_app

db-backup: ## Create database backup
	@echo "💾 Creating database backup..."
	docker-compose exec $(SERVICE_DB) pg_dump -U postgres queue_app > backup_$(shell date +%Y%m%d_%H%M%S).sql

db-restore: ## Restore database from backup (use BACKUP_FILE=filename)
	@echo "🔄 Restoring database from $(BACKUP_FILE)..."
	docker-compose exec -T $(SERVICE_DB) psql -U postgres -d queue_app < $(BACKUP_FILE)

migrate: ## Run database migrations
	docker-compose exec $(SERVICE_BACKEND) alembic upgrade head

migration: ## Create new migration (use MESSAGE="description")
	docker-compose exec $(SERVICE_BACKEND) alembic revision --autogenerate -m "$(MESSAGE)"

# =================================================================
# REDIS COMMANDS
# =================================================================

redis-shell: ## Access Redis shell
	docker-compose exec $(SERVICE_REDIS) redis-cli

redis-monitor: ## Monitor Redis commands
	docker-compose exec $(SERVICE_REDIS) redis-cli monitor

redis-flush: ## Flush all Redis data
	docker-compose exec $(SERVICE_REDIS) redis-cli flushall

# =================================================================
# TESTING COMMANDS
# =================================================================

test: ## Run backend tests
	docker-compose exec $(SERVICE_BACKEND) pytest

test-cov: ## Run tests with coverage
	docker-compose exec $(SERVICE_BACKEND) pytest --cov=app --cov-report=html

test-watch: ## Run tests in watch mode
	docker-compose exec $(SERVICE_BACKEND) pytest -f

# =================================================================
# CODE QUALITY COMMANDS
# =================================================================

lint: ## Run linting
	docker-compose exec $(SERVICE_BACKEND) flake8 app/

format: ## Format code with black
	docker-compose exec $(SERVICE_BACKEND) black app/

isort: ## Sort imports
	docker-compose exec $(SERVICE_BACKEND) isort app/

check: lint format isort ## Run all code quality checks

# =================================================================
# UTILITY COMMANDS
# =================================================================

shell: ## Access backend shell
	docker-compose exec $(SERVICE_BACKEND) /bin/bash

ps: ## Show running containers
	docker-compose ps

stats: ## Show container resource usage
	docker stats $$(docker-compose ps -q)

clean: ## Clean up containers, networks, and volumes
	@echo "🧹 Cleaning up..."
	docker-compose down -v --remove-orphans
	docker system prune -f

clean-all: ## Clean up everything including images
	@echo "🧹 Cleaning up everything..."
	docker-compose down -v --remove-orphans --rmi all
	docker system prune -af

# =================================================================
# MONITORING COMMANDS
# =================================================================

health: ## Check health of all services
	@echo "🏥 Checking service health..."
	@docker-compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"

status: ## Show detailed status
	@echo "📊 Service Status:"
	@echo "=================="
	@docker-compose ps
	@echo ""
	@echo "📈 Resource Usage:"
	@echo "=================="
	@docker stats --no-stream $$(docker-compose ps -q) 2>/dev/null || echo "No running containers"

# =================================================================
# FLUTTER COMMANDS
# =================================================================

flutter-deps: ## Install Flutter dependencies
	cd flutter_app && flutter pub get

flutter-build: ## Build Flutter app
	cd flutter_app && flutter build apk

flutter-run: ## Run Flutter app
	cd flutter_app && flutter run

flutter-test: ## Run Flutter tests
	cd flutter_app && flutter test

flutter-clean: ## Clean Flutter build
	cd flutter_app && flutter clean

# =================================================================
# QUICK SETUP COMMANDS
# =================================================================

setup: ## Initial project setup
	@echo "🔧 Setting up Queue Management System..."
	@echo "Creating .env file if it doesn't exist..."
	@test -f .env || cp .env.example .env
	@echo "Building and starting development environment..."
	$(MAKE) dev-build
	@echo "✅ Setup complete!"
	@echo ""
	@echo "🌐 Services available at:"
	@echo "  • API Documentation: http://localhost:8000/docs"
	@echo "  • Database Admin: http://localhost:8080"
	@echo "  • Redis Admin: http://localhost:8081"

install: setup ## Alias for setup

# =================================================================
# BACKUP & RESTORE
# =================================================================

backup: ## Create full backup (database + uploads)
	@echo "💾 Creating full backup..."
	mkdir -p backups/$(shell date +%Y%m%d_%H%M%S)
	$(MAKE) db-backup
	docker cp $$(docker-compose ps -q backend):/app/uploads ./backups/$(shell date +%Y%m%d_%H%M%S)/
	@echo "✅ Backup created in backups/$(shell date +%Y%m%d_%H%M%S)/"

# =================================================================
# ENVIRONMENT INFO
# =================================================================

info: ## Show environment information
	@echo "Queue Management System Information"
	@echo "=================================="
	@echo "Environment: $$(grep ENVIRONMENT .env 2>/dev/null || echo 'development')"
	@echo "Docker Compose version: $$(docker-compose --version)"
	@echo "Docker version: $$(docker --version)"
	@echo ""
	@echo "Services:"
	@echo "---------"
	@docker-compose config --services | sed 's/^/  • /'
	@echo ""
	@echo "Volumes:"
	@echo "--------"
	@docker volume ls --filter name=queue --format "  • {{.Name}}"