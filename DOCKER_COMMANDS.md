# Docker Commands and Usage

Этот документ содержит все доступные команды для работы с Docker в проекте Queue Management System.

## Быстрый старт

### Разработка
```bash
# Использование Makefile (рекомендуется)
make up

# Или напрямую через docker-compose
docker-compose up -d db redis
docker-compose up backend
```

### Продакшн
```bash
make prod
# или
docker-compose --profile production up -d
```

## Доступные команды через docker-entrypoint.sh

### Основные команды

#### Запуск сервера разработки
```bash
docker-compose run backend dev
# или
make up
```

#### Запуск продакшн сервера
```bash
docker-compose run backend prod
# или
make prod
```

#### Миграции базы данных
```bash
# Применить миграции
docker-compose run backend migrate
# или
make migrate

# Создать новую миграцию
docker-compose run backend migrate-create "add user table"
# или
make migrate-create MSG="add user table"
```

#### Python shell с загруженными моделями
```bash
docker-compose run backend shell
# или
make shell
```

#### Bash shell в контейнере
```bash
docker-compose run backend bash
# или
make bash
```

### Тестирование и качество кода

#### Запуск тестов
```bash
docker-compose --profile test run backend-test
# или
make test

# Запуск конкретных тестов
docker-compose run backend test tests/test_auth.py
```

#### Линтинг кода
```bash
docker-compose run backend lint
# или
make lint
```

#### Форматирование кода
```bash
# Проверка форматирования
docker-compose run backend format
# или
make format

# Исправление форматирования
docker-compose run backend format-fix
# или
make format-fix
```

### Утилиты базы данных

#### Заполнение тестовыми данными
```bash
docker-compose run backend seed
# или
make seed
```

#### Сброс базы данных
```bash
docker-compose run backend reset-db
# или
make reset-db
```

#### Установка зависимостей
```bash
docker-compose run backend install-deps
```

## Профили Docker Compose

### Базовый профиль (по умолчанию)
Включает сервисы: `db`, `redis`, `backend`
```bash
docker-compose up
```

### Профиль production
Включает сервисы: `db`, `redis`, `backend-prod`, `nginx`
```bash
docker-compose --profile production up
```

### Профиль test
Включает сервисы для тестирования: `db`, `redis`, `backend-test`
```bash
docker-compose --profile test up
```

### Профиль tools
Включает утилиты: `migrator`
```bash
docker-compose --profile tools up
```

## Примеры использования

### Первый запуск проекта
```bash
# 1. Сборка образов
make build

# 2. Запуск инфраструктуры
make up

# 3. Применение миграций (если необходимо)
make migrate

# 4. Заполнение тестовыми данными
make seed
```

### Ежедневная разработка
```bash
# Запуск для разработки
make up

# Просмотр логов
make logs

# Остановка
make down
```

### Создание и применение миграций
```bash
# Создать новую миграцию
make migrate-create MSG="add new field to user table"

# Применить миграции
make migrate

# Если нужно сбросить БД
make reset-db
```

### Тестирование
```bash
# Запуск всех тестов
make test

# Запуск конкретного теста
docker-compose run backend test tests/test_specific.py::test_function

# Линтинг и форматирование
make lint
make format-fix
```

### Продакшн деплой
```bash
# Сборка продакшн образов
docker-compose --profile production build

# Запуск в продакшн режиме
make prod

# Просмотр статуса сервисов
make status

# Остановка продакшн окружения
make prod-down
```

### Отладка и диагностика
```bash
# Интерактивный Python shell
make shell

# Bash в контейнере
make bash

# Просмотр логов конкретного сервиса
make logs-backend
make logs-db
make logs-redis

# Проверка статуса сервисов
make status
```

### Очистка
```bash
# Остановка всех сервисов
make down

# Полная очистка (включая volumes)
make clean

# Удаление Docker образов
make clean-images
```

## Переменные окружения

### Backend
- `DATABASE_URL` - URL подключения к PostgreSQL
- `REDIS_URL` - URL подключения к Redis
- `ENVIRONMENT` - Режим работы (development/production/test)

### Database
- `POSTGRES_DB` - Имя базы данных
- `POSTGRES_USER` - Пользователь PostgreSQL
- `POSTGRES_PASSWORD` - Пароль PostgreSQL

## Порты

- **8000** - Backend (development)
- **8001** - Backend (production)
- **5432** - PostgreSQL
- **6379** - Redis
- **80** - Nginx (production)
- **443** - Nginx HTTPS (production)

## Volumes

- `postgres_data` - Данные PostgreSQL
- `./backend:/app` - Код приложения (для разработки)

## Сети

- `queue_network` - Внутренняя сеть Docker для всех сервисов

## Health Checks

Все сервисы имеют health checks для корректного порядка запуска:
- PostgreSQL: `pg_isready`
- Redis: `redis-cli ping`

## Troubleshooting

### Проблемы с подключением к БД
```bash
# Проверить статус сервисов
make status

# Посмотреть логи БД
make logs-db

# Перезапустить сервисы
make restart
```

### Проблемы с миграциями
```bash
# Сбросить БД и применить миграции заново
make reset-db
```

### Проблемы с зависимостями
```bash
# Пересобрать образы
make build

# Переустановить зависимости
docker-compose run backend install-deps
```