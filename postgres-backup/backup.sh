#!/bin/bash
set -e

source /app/scripts/common.sh

DB_NAME="${1}"
BACKUP_PATH="${2}"

if [ -z "${DB_NAME}" ]; then
    log_error "Database name not provided"
    exit 1
fi

if [ -z "${BACKUP_PATH}" ]; then
    log_error "Backup path not provided"
    exit 1
fi

log_info "Starting PostgreSQL backup..."
log_info "Database: ${DB_NAME}"
log_info "Backup path: ${BACKUP_PATH}"

# Set PostgreSQL environment variables
export PGHOST="${DB_HOST}"
export PGPORT="${DB_PORT}"
export PGUSER="${DB_USER}"
export PGPASSWORD="${DB_PASSWORD}"

log_info "Backing up database: ${DB_NAME}"
pg_dump --format=plain --no-owner --no-acl --no-privileges "${DB_NAME}" | gzip > "${BACKUP_PATH}"

BACKUP_SIZE=$(stat -f%z "${BACKUP_PATH}" 2>/dev/null || stat -c%s "${BACKUP_PATH}" 2>/dev/null)
log_info "Backup completed. Size: ${BACKUP_SIZE} bytes"
