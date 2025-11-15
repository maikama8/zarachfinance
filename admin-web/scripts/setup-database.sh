#!/bin/bash

# Zaracfinance Admin - Database Setup Script
# This script initializes the admin database tables

set -e

echo "========================================="
echo "Zaracfinance Admin - Database Setup"
echo "========================================="
echo ""

# Load environment variables
if [ -f ../.env ]; then
    export $(cat ../.env | grep -v '^#' | xargs)
else
    echo "Error: .env file not found!"
    echo "Please create .env file first."
    exit 1
fi

# Check if required variables are set
if [ -z "$DB_NAME" ] || [ -z "$DB_USER" ]; then
    echo "Error: Database configuration missing in .env file"
    exit 1
fi

echo "Database: $DB_NAME"
echo "User: $DB_USER"
echo ""

# Run initialization SQL
echo "Creating admin tables..."
PGPASSWORD=$DB_PASSWORD psql -h ${DB_HOST:-localhost} -U $DB_USER -d $DB_NAME -f ../database/init.sql

if [ $? -eq 0 ]; then
    echo ""
    echo "========================================="
    echo "✓ Database setup complete!"
    echo "========================================="
    echo ""
    echo "Next step: Create your first admin user"
    echo "Run: node create-admin.js"
    echo ""
else
    echo ""
    echo "✗ Database setup failed!"
    echo "Please check your database configuration."
    exit 1
fi
