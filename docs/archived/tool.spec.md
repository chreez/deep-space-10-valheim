# Remote Server Management Tool Specification

## Overview
This specification defines standard patterns for all tools that manage remote Valheim servers, perform deployments, or conduct health checks. All scripts should follow these patterns for consistency, reliability, and maintainability.

## Architecture Pattern

### Environment Stack
```
Local macOS Development    →    Windows WSL2 Target    →    Windows Host
├── ssh_windows_wsl tool   →    Ubuntu commands        →    .bat execution
├── deployment scripts     →    file operations        →    Steam/SteamCMD
├── health monitoring      →    process management     →    Valheim server
└── backup/sync tools      →    data transfer          →    Windows storage
```

## 1. SSH Connection Management

### Standard SSH Pattern
**REQUIRED**: All tools MUST use the dotfiles SSH wrapper tool.

```bash
# Correct Pattern
ssh_exec() {
    local command="$1"
    ~/.dotfiles/bin/ssh_windows_wsl --command "$command"
}

# Python Pattern
def ssh_exec(self, command, check=True):
    """Execute command on remote host via SSH"""
    full_command = [
        os.path.expanduser("~/.dotfiles/bin/ssh_windows_wsl"),
        "--command", command
    ]
    # ... rest of implementation
```

**FORBIDDEN**: Direct SSH usage
```bash
# DO NOT USE - Inconsistent patterns
ssh user@host "command"
ssh -F config host "command"
```

### SSH Connection Validation
All tools MUST validate SSH connectivity before executing operations:

```bash
validate_ssh_connection() {
    if ~/.dotfiles/bin/ssh_windows_wsl --command "echo 'connection_test'" | grep -q "connection_test"; then
        return 0
    else
        echo "ERROR: SSH connection failed"
        return 1
    fi
}
```

### SSH Output Parsing
When parsing SSH tool output, account for tool messages:

```bash
# Extract actual command output after SSH tool messages
parse_ssh_output() {
    local raw_output="$1"
    echo "$raw_output" | awk '
        /🚀 Executing command.*:/ { capture=1; next }
        capture { print }
    '
}
```

## 2. Configuration Management

### Standard Configuration Variables
All tools MUST use these standardized configuration values:

```bash
# Required Configuration (DO NOT CHANGE)
REMOTE_HOST="windows-host"          # Use hostname from ssh_config
REMOTE_USER="chris"                 # Consistent with ssh_config
WORKSPACE_DIR="/mnt/e/deep.space.10" # E: drive mount point
SSH_CONFIG="./config/ssh_config"    # Local SSH configuration

# Derived from ssh_config
REMOTE_IP="192.168.1.236"          # Resolved from hostname
```

### Configuration Loading
Tools should load configuration from a central source:

```bash
load_config() {
    local config_file="${1:-./config/server_config.json}"
    if [[ -f "$config_file" ]]; then
        # Parse JSON config or source shell config
        source "$config_file" 2>/dev/null || true
    fi
}
```

### Environment Validation
Validate configuration before operations:

```bash
validate_config() {
    [[ -n "$REMOTE_HOST" ]] || { echo "ERROR: REMOTE_HOST not set"; return 1; }
    [[ -n "$REMOTE_USER" ]] || { echo "ERROR: REMOTE_USER not set"; return 1; }
    [[ -n "$WORKSPACE_DIR" ]] || { echo "ERROR: WORKSPACE_DIR not set"; return 1; }
    [[ -f "$SSH_CONFIG" ]] || { echo "ERROR: SSH config not found"; return 1; }
}
```

## 3. Error Handling & Validation

### Standard Error Handling Pattern
All tools MUST implement comprehensive error handling:

```bash
set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Function-level error handling
safe_exec() {
    local command="$1"
    local description="$2"
    
    echo "INFO: $description"
    if ! eval "$command"; then
        echo "ERROR: Failed to $description"
        echo "Command: $command"
        return 1
    fi
}

# SSH command with validation
safe_ssh_exec() {
    local command="$1"
    local description="$2"
    
    validate_ssh_connection || return 1
    
    echo "INFO: Executing remotely: $description"
    if ! ssh_exec "$command"; then
        echo "ERROR: Remote command failed: $description"
        echo "Command: $command"
        return 1
    fi
}
```

### Retry Logic for Network Operations
Implement retry logic for unreliable operations:

```bash
retry_operation() {
    local max_attempts=3
    local delay=5
    local attempt=1
    local command="$1"
    local description="$2"
    
    while [[ $attempt -le $max_attempts ]]; do
        echo "INFO: Attempt $attempt/$max_attempts: $description"
        
        if eval "$command"; then
            echo "SUCCESS: $description completed"
            return 0
        fi
        
        if [[ $attempt -lt $max_attempts ]]; then
            echo "WARN: Attempt $attempt failed, retrying in ${delay}s..."
            sleep $delay
        fi
        
        ((attempt++))
    done
    
    echo "ERROR: All attempts failed: $description"
    return 1
}
```

### Rollback Capability
Tools that modify remote state MUST support rollback:

```bash
create_backup() {
    local backup_name="backup_$(date +%Y%m%d_%H%M%S)"
    safe_ssh_exec "cp -r $WORKSPACE_DIR $WORKSPACE_DIR.$backup_name" "Create backup"
    echo "$WORKSPACE_DIR.$backup_name"
}

rollback_from_backup() {
    local backup_path="$1"
    safe_ssh_exec "rm -rf $WORKSPACE_DIR && mv $backup_path $WORKSPACE_DIR" "Rollback from backup"
}
```

## 4. Logging & Monitoring

### Standard Logging Format
All tools MUST use consistent logging:

```bash
# Logging functions
log_info() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $*"; }
log_warn() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] WARN: $*" >&2; }
log_error() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $*" >&2; }

# Usage
log_info "Starting deployment process"
log_warn "Configuration file not found, using defaults"
log_error "Failed to connect to remote host"
```

### Operation Audit Trail
Log all significant operations:

```bash
audit_log() {
    local operation="$1"
    local status="$2"
    local details="$3"
    local log_file="${LOG_DIR:-./logs}/audit.log"
    
    mkdir -p "$(dirname "$log_file")"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $operation | $status | $details" >> "$log_file"
}

# Usage
audit_log "DEPLOY" "START" "Deploying server version 1.2.3"
audit_log "DEPLOY" "SUCCESS" "Deployment completed in 45s"
```

### Progress Reporting
Provide clear progress feedback:

```bash
progress_bar() {
    local current=$1
    local total=$2
    local description="$3"
    local percent=$((current * 100 / total))
    local filled=$((percent / 2))
    local empty=$((50 - filled))
    
    printf "\r%s [" "$description"
    printf "%*s" $filled | tr ' ' '█'
    printf "%*s" $empty | tr ' ' '░'
    printf "] %d%% (%d/%d)" $percent $current $total
    
    [[ $current -eq $total ]] && echo
}
```

## 5. Security Requirements

### SSH Key Management
- Use SSH keys only, no password authentication
- Validate SSH key permissions (600 for private keys)
- Use dedicated SSH config files

### Credential Management
- NO hardcoded passwords or secrets in scripts
- Use environment variables or secure config files
- Validate file permissions on config files (600)

```bash
validate_security() {
    local ssh_key="$HOME/.ssh/id_rsa"
    local ssh_config="./config/ssh_config"
    
    # Check SSH key permissions
    if [[ -f "$ssh_key" ]] && [[ $(stat -f "%A" "$ssh_key") != "600" ]]; then
        log_error "SSH key permissions too permissive: $ssh_key"
        return 1
    fi
    
    # Check config file permissions
    if [[ -f "$ssh_config" ]] && [[ $(stat -f "%A" "$ssh_config") != "600" ]]; then
        log_warn "SSH config permissions should be 600: $ssh_config"
    fi
}
```

### Input Validation
Validate all user inputs and remote data:

```bash
validate_input() {
    local input="$1"
    local pattern="$2"
    local description="$3"
    
    if [[ ! "$input" =~ $pattern ]]; then
        log_error "Invalid $description: $input"
        return 1
    fi
}

# Usage
validate_input "$server_name" '^[a-zA-Z0-9._-]+$' "server name"
validate_input "$port" '^[0-9]+$' "port number"
```

## 6. Testing & Validation

### Pre-operation Validation
All tools MUST validate prerequisites before executing:

```bash
validate_prerequisites() {
    local errors=0
    
    # Check local requirements
    command -v python3 >/dev/null || { log_error "python3 not found"; ((errors++)); }
    command -v rsync >/dev/null || { log_error "rsync not found"; ((errors++)); }
    
    # Check configuration
    validate_config || ((errors++))
    validate_security || ((errors++))
    
    # Check SSH connectivity
    validate_ssh_connection || ((errors++))
    
    if [[ $errors -gt 0 ]]; then
        log_error "Prerequisites validation failed ($errors errors)"
        return 1
    fi
    
    log_info "Prerequisites validation passed"
}
```

### Post-operation Verification
Validate that operations completed successfully:

```bash
verify_deployment() {
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
    
    return $errors
}
```

## 7. Performance Guidelines

### Parallel Operations
Use parallel execution where safe:

```bash
# Parallel file transfers
sync_files_parallel() {
    local source_dirs=("server" "modpack" "config")
    local pids=()
    
    for dir in "${source_dirs[@]}"; do
        sync_directory "$dir" &
        pids+=($!)
    done
    
    # Wait for all transfers to complete
    local failed=0
    for pid in "${pids[@]}"; do
        wait "$pid" || ((failed++))
    done
    
    if [[ $failed -gt 0 ]]; then
        log_error "$failed parallel operations failed"
        return 1
    fi
}
```

### Resource Monitoring
Monitor resource usage during operations:

```bash
monitor_resources() {
    local duration="$1"
    local interval=5
    
    for ((i=0; i<duration; i+=interval)); do
        safe_ssh_exec "free -m | grep ^Mem" "Check memory usage"
        safe_ssh_exec "df -h $WORKSPACE_DIR | tail -1" "Check disk usage"
        sleep $interval
    done
}
```

## 8. Integration Patterns

### Health Check Integration
All tools should integrate with health monitoring:

```bash
verify_server_health() {
    local health_script="./scripts/health_check.py"
    
    if [[ -f "$health_script" ]]; then
        log_info "Running health check"
        if python3 "$health_script"; then
            log_info "Health check passed"
        else
            log_warn "Health check failed"
            return 1
        fi
    else
        log_warn "Health check script not found: $health_script"
    fi
}
```

### Configuration Synchronization
Keep configurations synchronized:

```bash
sync_configuration() {
    local config_files=("server_config.json" "ssh_config")
    
    for config in "${config_files[@]}"; do
        if [[ -f "./config/$config" ]]; then
            safe_ssh_exec "mkdir -p $WORKSPACE_DIR/config" "Create config directory"
            retry_operation "rsync -avz ./config/$config $REMOTE_USER@$REMOTE_HOST:$WORKSPACE_DIR/config/" "Sync $config"
        fi
    done
}
```

## 9. Documentation Requirements

### Script Headers
All scripts MUST include comprehensive headers:

```bash
#!/bin/bash
#
# Script Name: deploy_server.sh
# Description: Deploy Valheim server files and configuration to remote host
# Author: Automated tooling system
# Version: 2.0
# Last Modified: $(date +%Y-%m-%d)
#
# Usage: ./deploy_server.sh [--dry-run] [--force]
#
# Dependencies:
#   - ~/.dotfiles/bin/ssh_windows_wsl
#   - rsync
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
#
```

### Function Documentation
Document all functions:

```bash
#
# Function: deploy_server_files
# Description: Deploy server binaries and configuration to remote host
# Parameters:
#   $1 - source_directory (local path to server files)
#   $2 - target_directory (remote path for deployment)
#   $3 - dry_run (optional: "true" for dry run)
# Returns:
#   0 - Success
#   1 - Error
# Example:
#   deploy_server_files "./src/server" "/mnt/e/deep.space.10/server" "false"
#
deploy_server_files() {
    # Implementation here
}
```

## 10. Compliance Checklist

Before implementing any remote server management tool, verify:

- [ ] Uses dotfiles ssh_windows_wsl tool exclusively
- [ ] Implements comprehensive error handling with rollback
- [ ] Validates all prerequisites before execution
- [ ] Uses standardized configuration values
- [ ] Implements consistent logging format
- [ ] Includes security validation (SSH keys, permissions)
- [ ] Provides progress feedback for long operations
- [ ] Supports dry-run mode for testing
- [ ] Includes post-operation verification
- [ ] Integrates with health monitoring
- [ ] Documents all functions and usage patterns
- [ ] Follows standard exit code conventions
- [ ] Implements retry logic for network operations
- [ ] Creates audit trails for all operations

---

**This specification ensures all remote server management tools are consistent, reliable, and maintainable. All existing scripts must be updated to comply with these standards.**