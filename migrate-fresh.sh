#!/bin/bash

# Vapor Migration Fresh Script (like Laravel's artisan migrate:fresh)
# This drops all tables and re-runs migrations

echo "🔄 Starting fresh migration..."
echo ""

# Database credentials (update these if needed)
DB_HOST="${DATABASE_HOST:-127.0.0.1}"
DB_PORT="${DATABASE_PORT:-3306}"
DB_USER="${DATABASE_USERNAME:-root}"
DB_PASS="${DATABASE_PASSWORD:-root}"
DB_NAME="${DATABASE_NAME:-rumahsakit}"

# Drop all tables
echo "🗑️  Dropping all tables in database '$DB_NAME'..."
mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" <<EOF
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS doctors;
DROP TABLE IF EXISTS schedules;
DROP TABLE IF EXISTS _fluent_migrations;
SET FOREIGN_KEY_CHECKS = 1;
EOF

if [ $? -eq 0 ]; then
    echo "✅ All tables dropped successfully"
    echo ""
    
    # Run migrations
    echo "🚀 Running migrations..."
    swift run rumahsakit migrate --auto-migrate
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "✅ Migration fresh completed successfully!"
    else
        echo ""
        echo "❌ Migration failed!"
        exit 1
    fi
else
    echo "❌ Failed to drop tables!"
    exit 1
fi
