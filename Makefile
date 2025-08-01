.PHONY: help build up down logs shell migrate test lint format clean

# Default target
help:
	@echo "Available commands:"
	@echo ""
	@echo "Development:"
	@echo "  make up              - Start development environment"
	@echo "  make down            - Stop all services"
	@echo "  make build           - Build Docker images"
	@echo "  make logs            - View logs"
	@echo "  make restart         - Restart all services"
	@echo ""
	@echo "Backend operations:"
	@echo "  make shell           - Start Python shell in backend container"
	@echo "  make bash            - Start bash shell in backend container"
	@echo "  make migrate         - Run database migrations"
	@echo "  make migrate-create  - Create new migration (requires MSG='migration name')"
	@echo "  make seed            - Seed database with initial data"
	@echo "  make reset-db        - Reset database"
	@echo ""
	@echo "Testing and Quality:"
	@echo "  make test            - Run tests"
	@echo "  make lint            - Run code linting"
	@echo "  make format          - Check code formatting"
	@echo "  make format-fix      - Fix code formatting"
	@echo ""
	@echo "Production:"
	@echo "  make prod            - Start production environment"
	@echo "  make prod-down       - Stop production environment"
	@echo ""
	@echo "Cleanup:"
	@echo "  make clean           - Remove all containers and volumes"
	@echo "  make clean-images    - Remove Docker images"

# Development commands
build:
	docker-compose build

up:
	docker-compose up -d db redis
	@echo "Waiting for database and redis to be ready..."
	@sleep 5
	docker-compose up backend

down:
	docker-compose down

restart: down up

logs:
	docker-compose logs -f

# Backend operations
shell:
	docker-compose run --rm backend shell

bash:
	docker-compose run --rm backend bash

migrate:
	docker-compose run --rm backend migrate

migrate-create:
	@if [ -z "$(MSG)" ]; then \
		echo "Usage: make migrate-create MSG='migration description'"; \
		exit 1; \
	fi
	docker-compose run --rm backend migrate-create "$(MSG)"

seed:
	docker-compose run --rm backend seed

reset-db:
	docker-compose run --rm backend reset-db

# Testing and quality
test:
	docker-compose --profile test run --rm backend-test

lint:
	docker-compose run --rm backend lint

format:
	docker-compose run --rm backend format

format-fix:
	docker-compose run --rm backend format-fix

# Production
prod:
	docker-compose --profile production up -d db redis
	@echo "Waiting for database and redis to be ready..."
	@sleep 5
	docker-compose --profile production up -d backend-prod nginx

prod-down:
	docker-compose --profile production down

# Cleanup
clean:
	docker-compose down -v --remove-orphans
	docker system prune -f

clean-images:
	docker-compose down --rmi all

# Install development dependencies locally (optional)
install:
	pip install -r backend/requirements.txt

# View service status
status:
	docker-compose ps

# Follow logs for specific service
logs-backend:
	docker-compose logs -f backend

logs-db:
	docker-compose logs -f db

logs-redis:
	docker-compose logs -f redis