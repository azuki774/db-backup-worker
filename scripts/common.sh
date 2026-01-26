#!/bin/bash
set -e

# Common functions and utilities for DB backup scripts

# Logging functions
log_info() {
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $*" >&2
}

log_error() {
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $*" >&2
}

log_warning() {
    echo "[WARNING] $(date '+%Y-%m-%d %H:%M:%S') - $*" >&2
}

log_debug() {
    if [ "${DEBUG:-false}" = "true" ]; then
        echo "[DEBUG] $(date '+%Y-%m-%d %H:%M:%S') - $*" >&2
    fi
}

# Check required environment variables
check_required_vars() {
    local missing_vars=()

    for var in "$@"; do
        if [ -z "${!var}" ]; then
            missing_vars+=("$var")
        fi
    done

    if [ ${#missing_vars[@]} -gt 0 ]; then
        log_error "Missing required environment variables: ${missing_vars[*]}"
        exit 1
    fi
}

# Verify AWS credentials are available
verify_aws_credentials() {
    if [ -z "${AWS_ACCESS_KEY_ID}" ] && [ -z "${AWS_SECRET_ACCESS_KEY}" ]; then
        log_warning "AWS credentials not set. Attempting to use instance profile or other credential sources."
    fi
    
    if [ -n "${AWS_ACCESS_KEY_ID}" ] && [ -z "${AWS_SECRET_ACCESS_KEY}" ]; then
        log_error "AWS_ACCESS_KEY_ID is set but AWS_SECRET_ACCESS_KEY is not"
        exit 1
    fi
}

# Send Discord notification
send_discord_notification() {
    local message="$1"
    local color="$2"  # decimal color (e.g., 3066993 for green, 15158332 for red)
    local content="$3"  # optional content field for mentions
    local title="${4:-Database Backup Notification}"  # optional custom title
    
    if [ -z "${DISCORD_WEBHOOK}" ]; then
        log_debug "DISCORD_WEBHOOK not set, skipping notification"
        return 0
    fi
    
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    local payload=$(cat <<EOF
{
  "content": "${content}",
  "embeds": [{
    "title": "${title}",
    "description": "${message}",
    "color": ${color},
    "timestamp": "${timestamp}"
  }]
}
EOF
)
    
    log_debug "Sending Discord notification..."
    if ! curl -sf -X POST "${DISCORD_WEBHOOK}" \
        -H "Content-Type: application/json" \
        -d "${payload}" > /dev/null 2>&1; then
        log_warning "Failed to send Discord notification (this will not affect the backup process)"
    else
        log_debug "Discord notification sent successfully"
    fi
}

# Send Discord success notification
send_discord_success() {
    local db_name="$1"
    local backup_file="$2"
    local s3_uri="$3"
    local file_size="$4"
    local title="${5:-Database Backup Notification}"  # optional custom title
    
    local message="✅ **Backup Successful**\n\n"
    message+="**Database:** \`${db_name}\`\n"
    message+="**Backup File:** \`${backup_file}\`\n"
    
    if [ -n "${s3_uri}" ]; then
        message+="**S3 Location:** \`${s3_uri}\`\n"
    fi
    
    if [ -n "${file_size}" ]; then
        # Convert bytes to human readable format
        local size_mb=$((file_size / 1024 / 1024))
        message+="**File Size:** ${size_mb} MB\n"
    fi
    
    send_discord_notification "${message}" "3066993" "" "${title}"  # Green color
}

# Send Discord failure notification
send_discord_failure() {
    local db_name="$1"
    local title="${2:-Database Backup Notification}"  # optional custom title
    
    local message="❌ **Backup Failed**\n\n"
    
    if [ -n "${db_name}" ]; then
        message+="**Database:** \`${db_name}\`\n"
    fi
    
    message+="Please check the logs for details."
    
    send_discord_notification "${message}" "15158332" "@here" "${title}"  # Red color with @here mention
}
