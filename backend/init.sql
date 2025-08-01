-- =================================================================
-- QUEUE MANAGEMENT SYSTEM - DATABASE INITIALIZATION
-- =================================================================

-- Create database if not exists (handled by Docker)
-- CREATE DATABASE queue_app;

-- Set timezone
SET timezone = 'UTC';

-- Create extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Create custom types for enums
DO $$ BEGIN
    CREATE TYPE auth_provider_enum AS ENUM ('email', 'google', 'facebook');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE point_status_enum AS ENUM ('active', 'inactive', 'maintenance');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE cashier_status_enum AS ENUM ('available', 'busy', 'offline', 'break');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE order_type_enum AS ENUM ('immediate', 'scheduled');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Create indexes for better performance (will be created by Alembic)

-- Sample data for development (only if in development mode)
-- This will be handled by the application initialization