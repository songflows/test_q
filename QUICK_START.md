# 🚀 Quick Start Guide

Это руководство поможет вам быстро запустить систему управления очередями.

## 📋 Требования

- **Docker** и **Docker Compose** (версия 3.8+)
- **Git** для клонирования репозитория
- **Make** (опционально, для удобных команд)

## ⚡ Быстрый запуск (1 минута)

### 1. Клонирование и настройка
```bash
# Клонируйте репозиторий
git clone <repository-url>
cd queue-management-system

# Скопируйте файл конфигурации
cp .env.example .env
```

### 2. Запуск с помощью Make (рекомендуется)
```bash
# Быстрая установка и запуск
make setup

# Расширенный development режим с demo-данными
make dev-enhanced
```

### 3. Альтернативный запуск с Docker Compose
```bash
# Запуск в development режиме
docker-compose --profile development up -d --build
```

## 🌐 Доступ к сервисам

После запуска сервисы будут доступны по следующим адресам:

| Сервис | URL | Описание |
|--------|-----|----------|
| **API Documentation** | http://localhost:8000/docs | Swagger UI для API |
| **API ReDoc** | http://localhost:8000/redoc | Alternative API документация |
| **Database Admin** | http://localhost:8080 | Adminer для управления БД |
| **Redis Admin** | http://localhost:8081 | Redis Commander |
| **Backend API** | http://localhost:8000 | FastAPI backend |

### Логины для админ-панелей:
- **Adminer**: сервер `db`, пользователь `postgres`, пароль из `.env`
- **Redis Commander**: admin/admin_password_2024

## 🔧 Основные команды

### С использованием Make:
```bash
make help           # Показать все доступные команды
make dev            # Запустить development окружение
make prod           # Запустить production окружение
make logs           # Показать логи всех сервисов
make shell          # Зайти в backend контейнер
make db-shell       # Зайти в PostgreSQL
make redis-shell    # Зайти в Redis CLI
make test           # Запустить тесты
make clean          # Очистить контейнеры и данные
```

### С Docker Compose:
```bash
# Development
docker-compose --profile development up -d         # Запуск
docker-compose --profile development down          # Остановка
docker-compose --profile development logs -f       # Логи

# Production  
docker-compose --profile production up -d          # Запуск
docker-compose --profile production down           # Остановка
```

## 📱 Тестирование API

### 1. Регистрация пользователя
```bash
curl -X POST "http://localhost:8000/api/v1/auth/register" \
     -H "Content-Type: application/json" \
     -d '{
       "email": "test@example.com",
       "password": "test12345",
       "full_name": "Test User"
     }'
```

### 2. Вход в систему
```bash
curl -X POST "http://localhost:8000/api/v1/auth/login" \
     -H "Content-Type: application/json" \
     -d '{
       "email": "test@example.com",
       "password": "test12345"
     }'
```

### 3. Проверка здоровья системы
```bash
curl http://localhost:8000/health
```

## 🔧 Конфигурация

### Основные настройки в `.env`:
```env
# Для разработки
ENVIRONMENT=development
DEBUG=true

# Для продакшена
ENVIRONMENT=production
DEBUG=false
ALLOWED_HOSTS=["yourdomain.com"]
```

### OAuth настройки:
1. **Google OAuth**: https://console.developers.google.com/
2. **Facebook OAuth**: https://developers.facebook.com/

Добавьте полученные ключи в `.env`:
```env
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret
FACEBOOK_APP_ID=your-facebook-app-id
FACEBOOK_APP_SECRET=your-facebook-app-secret
```

## 📱 Flutter приложение

### Установка зависимостей:
```bash
cd flutter_app
flutter pub get
```

### Запуск:
```bash
flutter run
```

### Конфигурация API endpoint:
Обновите `lib/services/api_service.dart`:
```dart
static const String baseUrl = 'http://your-backend-url/api/v1';
```

## 🐛 Решение проблем

### Порты заняты:
```bash
# Проверить, какие порты заняты
netstat -tulpn | grep :8000

# Изменить порты в .env
BACKEND_PORT=8001
DB_PORT=5433
```

### Очистка при проблемах:
```bash
make clean-all      # Очистить всё
make setup          # Запустить заново
```

### Проверка логов:
```bash
make logs                                    # Все логи
docker-compose logs backend                 # Только backend
docker-compose logs db                      # Только БД
```

### Перестройка контейнеров:
```bash
make dev-build      # Development
make prod-build     # Production
```

## 📊 Мониторинг

### Проверка статуса:
```bash
make status         # Детальный статус
make health         # Здоровье сервисов
make ps             # Список контейнеров
```

### Бэкапы:
```bash
make backup         # Полный бэкап
make db-backup      # Только БД
```

## 🚀 Деплой в продакшен

### 1. Подготовка:
```bash
# Обновить .env для продакшена
ENVIRONMENT=production
DEBUG=false
SECRET_KEY=очень-секретный-ключ
ALLOWED_HOSTS=["yourdomain.com"]
```

### 2. Запуск:
```bash
make prod-build
```

### 3. Nginx + SSL (опционально):
```bash
# Включить nginx профиль
docker-compose --profile production up -d
```

## 📚 Дополнительная информация

- [Полная документация](README.md)
- [API документация](http://localhost:8000/docs)
- [Архитектура проекта](docs/architecture.md)

## 🆘 Получить помощь

```bash
make help           # Список всех команд
make info           # Информация о системе
```

---

**Готово!** 🎉 Ваша система управления очередями запущена и готова к использованию!