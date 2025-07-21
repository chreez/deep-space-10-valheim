#!/bin/bash
set -e

echo "╔══════════════════════════════════════════════╗"
echo "║     deep.space.10 Development File Sync      ║"
echo "╚══════════════════════════════════════════════╝"

# Standard Configuration (Docker-based deployment)
REMOTE_HOST="windows-host"
REMOTE_USER="chris"
WORKSPACE_DIR="/mnt/e/deep.space.10"
LOCAL_SRC="./src"
SSH_CONFIG="./config/ssh_config"
LOG_DIR="./logs"

# Logging functions
log_info() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $*"; }
log_warn() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] WARN: $*" >&2; }
log_error() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $*" >&2; }

# SSH execution wrapper
ssh_exec() {
    local command="$1"
    ~/.dotfiles/bin/ssh_windows_wsl --command "$command"
}

# Validation functions
validate_ssh_connection() {
    log_info "Validating SSH connection"
    if ssh_exec "echo 'connection_test'" | grep -q "connection_test"; then
        log_info "SSH connection validated"
        return 0
    else
        log_error "SSH connection failed"
        return 1
    fi
}

validate_config() {
    [[ -n "$REMOTE_HOST" ]] || { log_error "REMOTE_HOST not set"; return 1; }
    [[ -n "$REMOTE_USER" ]] || { log_error "REMOTE_USER not set"; return 1; }
    [[ -n "$WORKSPACE_DIR" ]] || { log_error "WORKSPACE_DIR not set"; return 1; }
    [[ -f "$SSH_CONFIG" ]] || { log_error "SSH config not found: $SSH_CONFIG"; return 1; }
    [[ -d "$LOCAL_SRC" ]] || { log_error "Source directory not found: $LOCAL_SRC"; return 1; }
}

validate_prerequisites() {
    log_info "Validating prerequisites"
    
    # Check required tools
    command -v ~/.dotfiles/bin/ssh_windows_wsl >/dev/null || { log_error "ssh_windows_wsl not found"; return 1; }
    command -v ~/.dotfiles/bin/sync_windows_wsl >/dev/null || { log_error "sync_windows_wsl not found"; return 1; }
    
    validate_config || return 1
    validate_ssh_connection || return 1
    
    log_info "Prerequisites validation passed"
}

# Safe SSH execution with error handling
safe_ssh_exec() {
    local command="$1"
    local description="$2"
    
    log_info "Executing remotely: $description"
    if ! ssh_exec "$command"; then
        log_error "Failed: $description"
        log_error "Command: $command"
        return 1
    fi
}

# Retry operation with exponential backoff
retry_operation() {
    local max_attempts=3
    local delay=5
    local attempt=1
    local command="$1"
    local description="$2"
    
    while [[ $attempt -le $max_attempts ]]; do
        log_info "Attempt $attempt/$max_attempts: $description"
        
        if eval "$command"; then
            log_info "$description completed successfully"
            return 0
        fi
        
        if [[ $attempt -lt $max_attempts ]]; then
            log_warn "Attempt $attempt failed, retrying in ${delay}s..."
            sleep $delay
            delay=$((delay * 2))  # Exponential backoff
        fi
        
        ((attempt++))
    done
    
    log_error "All attempts failed: $description"
    return 1
}

# Sync functions using dotfiles tools
sync_to_remote() {
    local dry_run="$1"
    
    log_info "Syncing local files to remote server"
    log_info "Local: $LOCAL_SRC/"
    log_info "Remote: $REMOTE_HOST:$WORKSPACE_DIR/"
    
    local sync_cmd="~/.dotfiles/bin/sync_windows_wsl --to '$LOCAL_SRC/' '$WORKSPACE_DIR/'"
    
    if [[ "$dry_run" == "true" ]]; then
        log_info "DRY RUN MODE - Would execute: $sync_cmd"
        return 0
    fi
    
    retry_operation "$sync_cmd" "Sync files to remote" || {
        log_error "Failed to sync files to remote"
        return 4
    }
    
    log_info "Files successfully synced to remote server"
    
    # Provide next steps
    echo ""
    echo "✓ Files synced to remote server"
    echo "Next steps:"
    echo "  1. Restart server: ./scripts/server_control.sh restart"
    echo "  2. Check health: python3 scripts/health_check.py"
}

sync_from_remote() {
    local dry_run="$1"
    
    log_info "Syncing remote files to local development environment"
    log_info "Remote: $REMOTE_HOST:$WORKSPACE_DIR/"
    log_info "Local: $LOCAL_SRC/"
    
    # Ensure remote directory exists
    safe_ssh_exec "test -d $WORKSPACE_DIR" "Check remote directory exists" || {
        log_error "Remote directory does not exist: $WORKSPACE_DIR"
        return 4
    }
    
    local sync_cmd="~/.dotfiles/bin/sync_windows_wsl --from '$WORKSPACE_DIR/' '$LOCAL_SRC/'"
    
    if [[ "$dry_run" == "true" ]]; then
        log_info "DRY RUN MODE - Would execute: $sync_cmd"
        return 0
    fi
    
    retry_operation "$sync_cmd" "Sync files from remote" || {
        log_error "Failed to sync files from remote"
        return 4
    }
    
    log_info "Files successfully synced from remote server"
    
    echo ""
    echo "✓ Files synced from remote server"
    echo "Review changes and commit if needed"
}

# Show sync status
show_sync_status() {
    log_info "Checking sync status"
    
    # Get local file count
    local local_count=$(find "$LOCAL_SRC" -type f | wc -l)
    log_info "Local files: $local_count"
    
    # Get remote file count
    local remote_count
    if remote_count=$(ssh_exec "find $WORKSPACE_DIR -type f 2>/dev/null | wc -l"); then
        log_info "Remote files: $remote_count"
    else
        log_warn "Could not determine remote file count"
    fi
    
    # Check for recent changes
    local recent_local=$(find "$LOCAL_SRC" -type f -mtime -1 | wc -l)
    log_info "Local files modified in last 24h: $recent_local"
}

# Parse command line arguments
DRY_RUN=false
DIRECTION="to-remote"
SHOW_STATUS=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run|-n)
            DRY_RUN=true
            shift
            ;;
        to-remote)
            DIRECTION="to-remote"
            shift
            ;;
        from-remote)
            DIRECTION="from-remote"
            shift
            ;;
        status)
            SHOW_STATUS=true
            shift
            ;;
        *)
            log_error "Unknown option: $1"
            echo "Usage: $0 [--dry-run] [to-remote|from-remote|status]"
            exit 1
            ;;
    esac
done

# Main function
main() {
    # Create log directory
    mkdir -p "$LOG_DIR"
    
    # Validate prerequisites
    validate_prerequisites || exit 3
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN MODE - No files will be modified"
    fi
    
    case "$DIRECTION" in
        "to-remote")
            sync_to_remote "$DRY_RUN" || exit 4
            ;;
        "from-remote")
            sync_from_remote "$DRY_RUN" || exit 4
            ;;
    esac
    
    if [[ "$SHOW_STATUS" == "true" ]]; then
        show_sync_status
    fi
    
    log_info "Sync operation completed successfully"
}

# Execute main function
main "$@"