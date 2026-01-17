#!/bin/bash
set -e

source /app/scripts/common.sh

BACKUP_PATH="${1}"

if [ ! -f "${BACKUP_PATH}" ]; then
    log_error "Backup file not found: ${BACKUP_PATH}"
    exit 1
fi

log_info "Starting backup verification..."
log_info "Backup file: ${BACKUP_PATH}"

# Check file size
BACKUP_SIZE=$(stat -f%z "${BACKUP_PATH}" 2>/dev/null || stat -c%s "${BACKUP_PATH}" 2>/dev/null)
log_info "File size: ${BACKUP_SIZE} bytes"

# Check PostgreSQL dump signature
log_info "Checking PostgreSQL dump signature..."

if ! zcat "${BACKUP_PATH}" 2>/dev/null | head -n 10 | grep -qi "PostgreSQL database dump" 2>/dev/null; then
    log_error "Backup file does not appear to be a valid PostgreSQL dump"
    exit 1
fi

log_info "PostgreSQL dump signature check passed"

# Check for valid SQL content (look for common PostgreSQL dump elements)
if ! zcat "${BACKUP_PATH}" 2>/dev/null | grep -qi "SET" 2>/dev/null; then
    log_error "Backup may not have completed properly (missing SQL statements)"
    exit 1
fi

log_info "PostgreSQL dump content check passed"

log_info "Backup verification completed successfully"
