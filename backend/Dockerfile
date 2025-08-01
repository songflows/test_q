# =================================================================
# QUEUE MANAGEMENT SYSTEM - BACKEND DOCKERFILE
# =================================================================

# Use Python 3.11 Alpine for smaller image size
FROM python:3.11-alpine as base

# Set build arguments
ARG ENVIRONMENT=development

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    ENVIRONMENT=${ENVIRONMENT}

# Install system dependencies
RUN apk add --no-cache \
    build-base \
    postgresql-dev \
    libffi-dev \
    openssl-dev \
    curl \
    bash \
    netcat-openbsd \
    && rm -rf /var/cache/apk/*

# Create app user
RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup

# Set work directory
WORKDIR /app

# Copy requirements first (for better caching)
COPY requirements.txt .
COPY requirements-dev.txt* ./

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt && \
    if [ "$ENVIRONMENT" = "development" ] && [ -f "requirements-dev.txt" ]; then \
        pip install --no-cache-dir -r requirements-dev.txt; \
    fi

# Copy application code
COPY . .

# Create uploads directory
RUN mkdir -p uploads && \
    chown -R appuser:appgroup /app && \
    chmod +x docker-entrypoint.sh

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Set entrypoint
ENTRYPOINT ["/app/docker-entrypoint.sh"]

# =================================================================
# PRODUCTION IMAGE
# =================================================================
FROM base as production

ENV ENVIRONMENT=production

# Install gunicorn for production
USER root
RUN pip install --no-cache-dir gunicorn
USER appuser

# =================================================================
# DEVELOPMENT IMAGE
# =================================================================
FROM base as development

ENV ENVIRONMENT=development

# Install development tools
USER root
RUN pip install --no-cache-dir \
    pytest \
    pytest-asyncio \
    black \
    isort \
    flake8
USER appuser