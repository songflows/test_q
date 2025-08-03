.PHONY: help build up down logs shell bash test migrate init prod worker scheduler clean

# Переменные
COMPOSE = docker-compose
BACKEND_SERVICE = backend

help: ## Показать эту справку
	@echo "Доступные команды:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

build: ## Собрать все образы
	$(COMPOSE) build

up: ## Запустить сервисы для разработки
	$(COMPOSE) up -d

down: ## Остановить все сервисы
	$(COMPOSE) down

logs: ## Показать логи backend сервиса
	$(COMPOSE) logs -f $(BACKEND_SERVICE)

logs-all: ## Показать логи всех сервисов
	$(COMPOSE) logs -f

shell: ## Запустить Python shell в контейнере
	$(COMPOSE) exec $(BACKEND_SERVICE) ./docker-entrypoint.sh shell

bash: ## Запустить bash в контейнере
	$(COMPOSE) exec $(BACKEND_SERVICE) bash

test: ## Запустить тесты
	$(COMPOSE) --profile test up --build backend-test

migrate: ## Запустить миграции
	$(COMPOSE) --profile migration up --build backend-migrate

init: ## Создать таблицы в БД
	$(COMPOSE) --profile init up --build backend-init

prod: ## Запустить production сервер
	$(COMPOSE) --profile production up -d db redis backend-prod

worker: ## Запустить background worker
	$(COMPOSE) --profile worker up -d backend-worker

scheduler: ## Запустить scheduler
	$(COMPOSE) --profile scheduler up -d backend-scheduler

full-prod: ## Запустить полный production стек
	$(COMPOSE) --profile production --profile worker --profile scheduler up -d

restart: ## Перезапустить backend сервис
	$(COMPOSE) restart $(BACKEND_SERVICE)

rebuild: ## Пересобрать и перезапустить backend
	$(COMPOSE) build $(BACKEND_SERVICE)
	$(COMPOSE) up -d $(BACKEND_SERVICE)

clean: ## Остановить и удалить все контейнеры
	$(COMPOSE) down

clean-all: ## Остановить и удалить все контейнеры и volume'ы
	$(COMPOSE) down -v

status: ## Показать статус сервисов
	$(COMPOSE) ps

# Команды для разработки
dev-setup: build init up ## Первоначальная настройка для разработки

dev-reset: clean-all dev-setup ## Полный сброс среды разработки

# Полезные команды
exec: ## Выполнить команду в контейнере (use: make exec CMD="command")
	$(COMPOSE) exec $(BACKEND_SERVICE) $(CMD)

run: ## Запустить одноразовую команду (use: make run CMD="command")
	$(COMPOSE) run --rm $(BACKEND_SERVICE) ./docker-entrypoint.sh $(CMD)