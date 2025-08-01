# 🚀 Entrypoint Scripts Documentation

Система управления очередями использует несколько специализированных entrypoint скриптов для различных сценариев запуска и эксплуатации.

## 📋 Список Entrypoint'ов

### 1. **Основной Backend Entrypoint**
**Файл:** `backend/docker-entrypoint.sh`
**Назначение:** Основной скрипт для запуска backend приложения

#### Функции:
- ✅ Ожидание готовности PostgreSQL и Redis
- ✅ Автоматические миграции базы данных
- ✅ Создание таблиц при первом запуске
- ✅ Установка dev-зависимостей в development режиме
- ✅ Запуск Uvicorn (development) или Gunicorn (production)
- ✅ Цветной вывод с информативными сообщениями

#### Использование:
```bash
# Development (автоматически)
make dev

# Прямой запуск
docker-compose up backend
```

#### Переменные окружения:
- `ENVIRONMENT` - режим работы (development/production)
- `DEBUG` - режим отладки
- `DATABASE_URL` - строка подключения к БД
- `REDIS_URL` - строка подключения к Redis

---

### 2. **Production Entrypoint**
**Файл:** `scripts/production-entrypoint.sh`
**Назначение:** Оптимизированный запуск для production

#### Особенности:
- 🔒 **Валидация окружения** - проверка критических настроек
- ⚡ **Оптимизации** для production
- 🏥 **Health checks** для всех зависимостей
- 📊 **Мониторинг** и логирование
- 🔄 **Graceful shutdown** при получении сигналов
- 🚀 **Gunicorn** с оптимальными настройками

#### Использование:
```bash
# Production запуск
make prod

# Или напрямую
docker-compose --profile production up backend-prod
```

#### Конфигурация Gunicorn:
```bash
WORKERS=4                    # Количество worker'ов
WORKER_CONNECTIONS=1000      # Соединений на worker
MAX_REQUESTS=1000           # Перезапуск worker'а после N запросов
TIMEOUT=30                  # Таймаут запросов
```

---

### 3. **Test Entrypoint**
**Файл:** `scripts/test-entrypoint.sh`
**Назначение:** Запуск тестов с настройкой тестового окружения

#### Функции:
- 🧪 **Тестовая БД** - создание отдельной базы данных
- 🔍 **Code Quality** - линтинг, форматирование, type checking
- 📊 **Coverage** - отчёты о покрытии кода
- 🧹 **Cleanup** - автоматическая очистка после тестов

#### Использование:
```bash
# Полные тесты
make test

# С покрытием кода
make test-cov

# Только unit тесты
make test-unit

# Кастомный запуск
docker-compose --profile testing run --rm backend-test --coverage --verbose
```

#### Опции командной строки:
```bash
--coverage      # Включить отчёт о покрытии
--verbose       # Подробный вывод
--skip-quality  # Пропустить проверки качества кода
--keep-db       # Не удалять тестовую БД
--path <path>   # Запустить конкретные тесты
```

---

### 4. **Database Initialization**
**Файл:** `scripts/init-db.sh`
**Назначение:** Инициализация базы данных с примерами данных

#### Функции:
- 🗄️ **Создание БД** если не существует
- 📝 **Выполнение SQL** инициализации
- 👥 **Демо-данные** для development окружения
- ✅ **Проверка готовности** базы данных

#### Демо-данные:
- Пользователи: `admin@example.com`, `user@example.com`
- Пароль для демо-пользователей: `password123`
- Демо-поинты с различными настройками
- Базовые статусы заказов

#### Использование:
```bash
# Инициализация БД
make init-db

# Полный сброс и инициализация
make reset-db
```

---

### 5. **Backup Entrypoint**
**Файл:** `scripts/backup.sh`
**Назначение:** Создание резервных копий базы данных

#### Возможности:
- 💾 **Полный backup** базы данных
- 📋 **Schema-only** backup
- 🗂️ **Критические таблицы** отдельно
- 📝 **Метаданные** backup'а
- 🗜️ **Сжатие** архивов
- 🧹 **Автоочистка** старых backup'ов
- ✅ **Верификация** целостности

#### Форматы backup'ов:
- `database.sql` - полный SQL dump
- `database.sql.custom` - PostgreSQL custom format
- `schema.sql` - только схема
- `table_*.sql` - отдельные таблицы
- `metadata.json` - информация о backup'е

#### Использование:
```bash
# Полный backup
make backup

# Быстрый backup БД
make backup-quick

# Backup файлов
make backup-files

# Кастомные опции
docker-compose --profile backup run --rm backup --no-compress --retention 14
```

#### Опции:
```bash
--no-compress   # Не сжимать backup
--no-cleanup    # Не удалять старые backup'ы
--retention N   # Хранить backup'ы N дней
```

---

## 🔧 Настройка и конфигурация

### Переменные окружения

#### Общие:
```env
ENVIRONMENT=development|production|test
DEBUG=true|false
DATABASE_URL=postgresql://user:pass@host:port/db
REDIS_URL=redis://host:port
SECRET_KEY=your-secret-key
```

#### Production:
```env
WORKERS=4
MAX_REQUESTS=1000
TIMEOUT=30
ALLOWED_HOSTS=["yourdomain.com"]
SSL_CERT_PATH=/path/to/cert.pem
SSL_KEY_PATH=/path/to/key.pem
```

#### Backup:
```env
BACKUP_RETENTION_DAYS=7
COMPRESS_BACKUP=true
```

### Health Checks

Все entrypoint'ы включают health checks:

```bash
# Проверка здоровья
curl http://localhost:8000/health

# Проверка через make
make health
```

### Мониторинг

Логи доступны через:
```bash
# Все сервисы
make logs

# Конкретный сервис
docker-compose logs -f backend

# Production логи
docker-compose --profile production logs -f backend-prod
```

---

## 🚀 Примеры использования

### Development окружение
```bash
# Запуск с автоматической настройкой
make setup

# Только backend
make dev

# С инициализацией данных
make dev && make init-db
```

### Testing
```bash
# Полные тесты с качеством кода
make test

# Быстрые unit тесты
make test-unit

# Интеграционные тесты
make test-integration
```

### Production деплой
```bash
# Подготовка
cp .env.example .env
# Настройте .env для production

# Запуск
make prod

# Или с Nginx
docker-compose --profile production up -d
```

### Backup и восстановление
```bash
# Регулярный backup
make backup

# Быстрый backup перед изменениями
make backup-quick

# Восстановление (пример)
docker-compose exec db psql -U postgres -d queue_app < backups/backup.sql
```

---

## 🛠️ Troubleshooting

### Общие проблемы

#### Entrypoint не запускается:
```bash
# Проверьте права доступа
ls -la backend/docker-entrypoint.sh
ls -la scripts/*.sh

# Исправьте если нужно
chmod +x backend/docker-entrypoint.sh
chmod +x scripts/*.sh
```

#### База данных недоступна:
```bash
# Проверьте статус
make ps

# Логи базы данных
docker-compose logs db

# Перезапуск
make restart
```

#### Тесты падают:
```bash
# Очистите тестовую среду
docker-compose --profile testing down -v

# Запустите заново
make test
```

### Отладка entrypoint'ов

Для отладки добавьте `set -x` в начало скрипта:
```bash
#!/bin/bash
set -e
set -x  # Включить отладочный вывод
```

---

## 📚 Дополнительные ресурсы

- [Быстрый старт](../QUICK_START.md)
- [Основная документация](../README.md)
- [Docker Compose конфигурация](../docker-compose.yml)
- [Makefile команды](../Makefile)

---

**Все entrypoint'ы спроектированы для максимальной надёжности и удобства использования!** 🎉