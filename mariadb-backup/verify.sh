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

if [ "${BACKUP_SIZE}" -eq 0 ]; then
    log_error "Backup file is empty"
    exit 1
fi

# Check MariaDB/MySQL dump signature
log_info "Checking MariaDB/MySQL dump signature..."

if ! zcat "${BACKUP_PATH}" 2>/dev/null | head -n 20 | grep -qE "MariaDB dump|MySQL dump" 2>/dev/null; then
    log_error "Backup file does not appear to be a valid MariaDB/MySQL dump"
    exit 1
fi

log_info "MariaDB/MySQL dump signature check passed"

# Check for dump completion marker
log_info "Checking dump completion marker..."

if ! zcat "${BACKUP_PATH}" 2>/dev/null | tail -n 5 | grep -qi "Dump completed on" 2>/dev/null; then
    log_error "Backup may not have completed properly (missing 'Dump completed on' marker)"
    exit 1
fi

log_info "Dump completion check passed"

log_info "Backup verification completed successfully"
