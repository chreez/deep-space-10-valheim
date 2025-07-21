#!/bin/bash
#
# Script Name: deploy_server.sh
# Description: Deploy Valheim server files and configuration to remote host
# Author: Automated tooling system
# Version: 2.0
# Last Modified: 2025-07-20
#
# Usage: ./deploy_server.sh [--dry-run] [--force]
#
# Dependencies:
#   - ~/.dotfiles/bin/ssh_windows_wsl
#   - ~/.dotfiles/bin/sync_windows_wsl
#   - python3
#
# Configuration:
#   - ./config/ssh_config (SSH connection settings)
#   - ./config/server_config.json (Server settings)
#
# Exit Codes:
#   0 - Success
#   1 - General error
#   2 - Configuration error
#   3 - Connection error
#   4 - Deployment error

set -euo pipefail

echo "╔══════════════════════════════════════════════╗"
echo "║       deep.space.10 Server Deployer          ║"
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

# Create backup before deployment
create_backup() {
    local backup_name="backup_$(date +%Y%m%d_%H%M%S)"
    log_info "Creating backup: $backup_name"
    
    if safe_ssh_exec "test -d $WORKSPACE_DIR" "Check if workspace exists"; then
        safe_ssh_exec "cp -r $WORKSPACE_DIR $WORKSPACE_DIR.$backup_name" "Create backup"
        echo "$backup_name"
    else
        log_info "No existing workspace to backup"
        echo ""
    fi
}

# Rollback from backup
rollback_from_backup() {
    local backup_name="$1"
    [[ -n "$backup_name" ]] || return 0
    
    log_warn "Rolling back from backup: $backup_name"
    safe_ssh_exec "rm -rf $WORKSPACE_DIR && mv $WORKSPACE_DIR.$backup_name $WORKSPACE_DIR" "Rollback from backup"
}

# Deployment functions
deploy_directory_structure() {
    log_info "Creating directory structure"
    safe_ssh_exec "mkdir -p $WORKSPACE_DIR/{server,backups,logs}" "Create directory structure"
    safe_ssh_exec "mkdir -p $WORKSPACE_DIR/server/BepInEx/{plugins,config}" "Create BepInEx structure"
}

deploy_server_files() {
    log_info "Deploying server files"
    ~/.dotfiles/bin/sync_windows_wsl --to "$LOCAL_SRC/server/" "$WORKSPACE_DIR/server/" || {
        log_error "Failed to sync server files"
        return 1
    }
}

deploy_configuration() {
    log_info "Deploying server configuration"
    if [[ -f "./config/server_config.json" ]]; then
        ~/.dotfiles/bin/sync_windows_wsl --to "./config/server_config.json" "$WORKSPACE_DIR/server/" || {
            log_error "Failed to sync server configuration"
            return 1
        }
    else
        log_warn "Server configuration file not found: ./config/server_config.json"
    fi
}

setup_bepinex() {
    log_info "Setting up BepInEx configuration"
    local bepinex_config="[Logging.Console]
Enabled = true
[Preloader.Entrypoint]
Type = MonoBehaviour
[Chainloader]
HideManagerGameObject = false"
    
    safe_ssh_exec "echo '$bepinex_config' > $WORKSPACE_DIR/server/BepInEx/config/BepInEx.cfg" "Create BepInEx config"
}

set_permissions() {
    log_info "Setting file permissions"
    safe_ssh_exec "chmod +x $WORKSPACE_DIR/server/valheim_server.x86_64" "Make server executable"
    safe_ssh_exec "chmod +x $WORKSPACE_DIR/server/*.bat" "Make batch files executable"
}

verify_deployment() {
    log_info "Verifying deployment"
    local required_files=("valheim_server.x86_64" "start_server.bat" "server_config.json")
    local errors=0
    
    for file in "${required_files[@]}"; do
        if ! safe_ssh_exec "test -f $WORKSPACE_DIR/server/$file" "Check $file"; then
            log_error "Required file missing: $file"
            ((errors++))
        fi
    done
    
    # Check server executable permissions
    if ! safe_ssh_exec "test -x $WORKSPACE_DIR/server/valheim_server.x86_64" "Check executable permissions"; then
        log_error "Server executable not executable"
        ((errors++))
    fi
    
    if [[ $errors -gt 0 ]]; then
        log_error "Deployment verification failed ($errors errors)"
        return 1
    fi
    
    log_info "Deployment verification passed"
}

# Parse command line arguments
DRY_RUN=false
FORCE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        *)
            log_error "Unknown option: $1"
            echo "Usage: $0 [--dry-run] [--force]"
            exit 1
            ;;
    esac
done

# Main deployment process
main() {
    local backup_name=""
    
    # Create log directory
    mkdir -p "$LOG_DIR"
    
    # Validate prerequisites
    validate_prerequisites || exit 3
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN MODE - No changes will be made"
        log_info "Would deploy $LOCAL_SRC to $REMOTE_HOST:$WORKSPACE_DIR"
        exit 0
    fi
    
    # Create backup
    backup_name=$(create_backup)
    
    # Deployment with rollback on failure
    {
        deploy_directory_structure &&
        deploy_server_files &&
        deploy_configuration &&
        setup_bepinex &&
        set_permissions &&
        verify_deployment
    } || {
        log_error "Deployment failed, initiating rollback"
        rollback_from_backup "$backup_name"
        exit 4
    }
    
    log_info "Deployment completed successfully"
    
    # Clean up old backup if deployment succeeded
    if [[ -n "$backup_name" ]]; then
        safe_ssh_exec "rm -rf $WORKSPACE_DIR.$backup_name" "Clean up backup" || log_warn "Failed to clean up backup"
    fi
}

# Execute main function
main "$@"
