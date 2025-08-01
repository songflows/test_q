# 🚀 Entrypoint Quick Reference

## Доступные Entrypoint'ы

### 1. **Основной Backend** - `backend/docker-entrypoint.sh`
```bash
# Автоматический запуск
make dev
docker-compose up backend

# Что делает:
✅ Ждёт PostgreSQL и Redis
✅ Запускает миграции  
✅ Создаёт таблицы
✅ Uvicorn (dev) / Gunicorn (prod)
```

### 2. **Enhanced Development** - `backend/docker-entrypoint-dev.sh`
```bash
# Запуск с demo-данными и дополнительными инструментами
make dev-enhanced
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up

# Что добавляет:
🎨 Красивый баннер и расширенное логирование
👥 Demo пользователи (admin@demo.com / demo123)
🏢 Готовые поинты и кассиры
📋 Настроенные статусы заказов
🔧 Автоматическое форматирование кода
📊 Дополнительные dev инструменты
```

### 3. **Production** - `scripts/production-entrypoint.sh`
```bash
# Production запуск с проверками
make prod
docker-compose --profile production up backend-prod

# Особенности:
🔒 Валидация критических настроек
⚡ Optimized Gunicorn конфигурация
🏥 Health checks всех сервисов
📊 Monitoring и graceful shutdown
```

### 4. **Testing** - `scripts/test-entrypoint.sh`
```bash
# Полные тесты с проверками качества
make test
docker-compose --profile testing run backend-test

# Опции:
--coverage      # Отчёт о покрытии
--verbose       # Подробный вывод
--skip-quality  # Без проверок качества кода
--keep-db       # Оставить тестовую БД
--path <path>   # Конкретные тесты
```

### 5. **Database Init** - `scripts/init-db.sh`
```bash
# Инициализация БД с demo-данными
make init-db
docker-compose --profile init run db-init

# Создаёт:
🗄️ Базу данных (если нет)
👥 Demo пользователей
🏢 Примеры поинтов и кассиров
📋 Базовые статусы заказов
```

### 6. **Backup** - `scripts/backup.sh`
```bash
# Полный backup
make backup
docker-compose --profile backup run backup

# Опции:
--no-compress   # Без сжатия
--no-cleanup    # Не удалять старые
--retention N   # Хранить N дней
```

## 🎯 Быстрые команды

### Разработка:
```bash
make setup          # Первый запуск
make dev            # Обычный development
make dev-enhanced   # С demo-данными и инструментами
make init-db        # Добавить demo-данные
```

### Тестирование:
```bash
make test           # Полные тесты
make test-unit      # Unit тесты
make test-cov       # С покрытием кода
```

### Production:
```bash
make prod           # Production запуск
make backup         # Создать backup
make health         # Проверить здоровье
```

### Утилиты:
```bash
make logs           # Показать логи
make shell          # Зайти в backend
make db-shell       # PostgreSQL shell
make redis-shell    # Redis CLI
make clean          # Очистить всё
```

## 🌐 Доступные сервисы

### Основные:
- **API**: http://localhost:8000/docs
- **Health**: http://localhost:8000/health
- **ReDoc**: http://localhost:8000/redoc

### Development инструменты:
- **Adminer**: http://localhost:8080 (БД)
- **Redis Commander**: http://localhost:8081
- **pgAdmin**: http://localhost:5050 (enhanced mode)
- **Jupyter**: http://localhost:8888 (enhanced mode)
- **MailHog**: http://localhost:8025 (enhanced mode)

## 📧 Demo данные (enhanced/init-db)

### Пользователи:
- **Admin**: admin@demo.com / demo123
- **User**: user@demo.com / demo123

### Поинты:
- **Главный офис** - полный функционал
- **Филиал №2** - базовый функционал

### Кассиры:
- Касса №1, №2 (главный офис)
- Касса №1 (филиал)

## 🔧 Переменные окружения

### Основные:
```env
ENVIRONMENT=development|production|test
DEBUG=true|false
DATABASE_URL=postgresql://...
REDIS_URL=redis://...
```

### Production:
```env
SECRET_KEY=secure-key
WORKERS=4
MAX_REQUESTS=1000
ALLOWED_HOSTS=["domain.com"]
```

## 🛠️ Troubleshooting

### Права доступа:
```bash
chmod +x backend/docker-entrypoint*.sh
chmod +x scripts/*.sh
```

### Порты заняты:
```bash
# Изменить в .env
BACKEND_PORT=8001
DB_PORT=5433
```

### Очистка при проблемах:
```bash
make clean          # Мягкая очистка
make clean-all      # Полная очистка
```

---

**Выберите нужный entrypoint в зависимости от ваших задач!** 🎯