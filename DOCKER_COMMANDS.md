# Docker Commands для Queue Management API

Этот проект теперь поддерживает различные команды для запуска через Docker с помощью `docker-entrypoint.sh` и `docker-compose.yml`.

## Доступные команды в docker-entrypoint.sh

### Основные команды сервера

- `server` - Запуск production сервера
- `server-dev` - Запуск development сервера с auto-reload
- `migrate` - Запуск миграций базы данных (Alembic)
- `create-tables` - Создание таблиц в базе данных
- `shell` - Запуск Python shell
- `bash` - Запуск bash shell
- `test` - Запуск тестов
- `worker` - Запуск background worker (заготовка для Celery)
- `scheduler` - Запуск scheduler (заготовка для Celery Beat)
- `manage` - Запуск management команд

## Использование с docker-compose

### Базовые сервисы (запускаются по умолчанию)

```bash
# Запуск всех базовых сервисов (db, redis, backend в dev режиме)
docker-compose up

# Запуск в фоне
docker-compose up -d

# Просмотр логов
docker-compose logs -f backend
```

### Специальные профили

#### Production режим

```bash
# Запуск production сервера
docker-compose --profile production up backend-prod

# Запуск с базовыми сервисами
docker-compose --profile production up db redis backend-prod
```

#### Миграции

```bash
# Запуск миграций
docker-compose --profile migration up backend-migrate

# Создание таблиц
docker-compose --profile init up backend-init
```

#### Тесты

```bash
# Запуск тестов
docker-compose --profile test up backend-test

# Запуск тестов с конкретными параметрами
docker-compose --profile test run --rm backend-test test -v
```

#### Background задачи

```bash
# Запуск worker'а
docker-compose --profile worker up backend-worker

# Запуск scheduler'а
docker-compose --profile scheduler up backend-scheduler

# Запуск и worker'а и scheduler'а
docker-compose --profile worker --profile scheduler up
```

## Прямое использование docker run

### Основные команды

```bash
# Сборка образа
docker build -t queue-app-backend ./backend

# Запуск development сервера
docker run --rm -p 8000:8000 queue-app-backend server-dev

# Запуск production сервера
docker run --rm -p 8000:8000 queue-app-backend server

# Создание таблиц
docker run --rm queue-app-backend create-tables

# Запуск Python shell
docker run --rm -it queue-app-backend shell

# Запуск bash
docker run --rm -it queue-app-backend bash
```

### С переменными окружения

```bash
docker run --rm -p 8000:8000 \
  -e DATABASE_URL=postgresql://user:pass@host:5432/db \
  -e REDIS_URL=redis://redis:6379 \
  -e ENVIRONMENT=production \
  queue-app-backend server
```

## Полезные команды для разработки

### Быстрый запуск для разработки

```bash
# Запуск всех необходимых сервисов для разработки
docker-compose up -d

# Перезапуск только backend
docker-compose restart backend

# Остановка всех сервисов
docker-compose down
```

### Отладка и консоль

```bash
# Войти в контейнер с backend
docker-compose exec backend bash

# Запустить Python shell в контейнере
docker-compose exec backend python

# Выполнить произвольную команду
docker-compose exec backend python -c "from app.core.database import engine; print(engine.url)"
```

### Логи и мониторинг

```bash
# Просмотр логов всех сервисов
docker-compose logs -f

# Просмотр логов конкретного сервиса
docker-compose logs -f backend

# Просмотр последних 100 строк логов
docker-compose logs --tail=100 backend
```

### Очистка

```bash
# Остановка и удаление контейнеров
docker-compose down

# Удаление с volume'ами (ВНИМАНИЕ: удалит данные БД)
docker-compose down -v

# Пересборка образов
docker-compose build

# Пересборка без кэша
docker-compose build --no-cache
```

## Структура конфигурации

### Healthchecks

Все сервисы имеют healthcheck'и:
- PostgreSQL: `pg_isready`
- Redis: `redis-cli ping`

Backend сервисы ждут готовности базы данных и Redis перед запуском.

### Profiles

Используются профили для группировки сервисов:
- `production` - production сервер
- `migration` - миграции
- `init` - инициализация БД
- `test` - тесты
- `worker` - background worker
- `scheduler` - scheduler

### Переменные окружения

Все сервисы используют единые переменные:
- `DATABASE_URL` - URL подключения к PostgreSQL
- `REDIS_URL` - URL подключения к Redis
- `ENVIRONMENT` - окружение (development/production/testing)

## Примеры workflow'ов

### Первый запуск проекта

```bash
# 1. Клонирование и переход в проект
git clone <repo>
cd <project>

# 2. Сборка и запуск
docker-compose build
docker-compose up -d

# 3. Создание таблиц (если нет миграций)
docker-compose --profile init up backend-init

# 4. Проверка работы
curl http://localhost:8000/health
```

### Разработка

```bash
# Запуск для разработки
docker-compose up -d

# Просмотр логов при разработке
docker-compose logs -f backend

# При изменении зависимостей
docker-compose build backend
docker-compose up -d

# Выполнение тестов
docker-compose --profile test up backend-test
```

### Production деплой

```bash
# Запуск production
docker-compose --profile production up -d db redis backend-prod

# Если нужны миграции
docker-compose --profile migration up backend-migrate

# Запуск background задач
docker-compose --profile worker --profile scheduler up -d
```