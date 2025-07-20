# deep.space.10 Server Setup Specification

## 🎯 Overview
Complete automation specification for setting up a deep.space.10 Valheim server using existing tooling and Claude Code CLI integration.

## 🏗️ Architecture Integration

### Hybrid Ubuntu/Windows Environment
```
Local macOS           →    Ubuntu WSL2         →    Windows Host
├── ssh_windows_wsl   →    Python scripts      →    .bat launchers
├── deploy_server.py  →    File management     →    Steam/SteamCMD
├── server_control.sh →    Server lifecycle    →    Valheim executable
└── server_control.sh →    Ubuntu commands     →    Windows processes
```

### Tool Ecosystem
```
Local Development      →    Ubuntu WSL2 Setup       →    Windows Execution
├── ssh_windows_wsl    →    SSH to Ubuntu          →    Execute .bat files
├── network scanning   →    File sync via rsync    →    Windows file paths
├── server_control.sh  →    Ubuntu shell commands  →    cmd.exe/.bat scripts
├── deploy_server.py   →    Python deployment      →    Windows service files
└── health_check.py    →    Status monitoring      →    Server health reports
```

### Claude + Dotfiles Integration
```bash
# Available via dotfiles system
~/.dotfiles/bin/ssh_windows_wsl              # Windows/WSL connection
~/.dotfiles/bin/network_drive_manager         # File management
# Project-specific tools (Ubuntu environment)
./scripts/server_control.sh                  # Server lifecycle (Ubuntu → Windows)
./scripts/deploy_server.py                   # Deployment automation (Ubuntu → Windows)
```

## 📋 Setup Prerequisites

### Local Requirements
- SSH key pair configured for target Windows host
- Python 3.8+ with required dependencies
- rsync for file synchronization
- Access to Chris's dotfiles system

### Remote Host Requirements
- **Windows 10/11 Host:**
  - Steam client installed on Windows
  - Valheim dedicated server files
  - Linux server executable (running in WSL2)
  - File paths using E: drive (/mnt/e/)
- **WSL2 Ubuntu Environment:**
  - SSH server configured for remote access
  - Python 3.8+ for deployment scripts
  - rsync for file synchronization
  - Access to Windows filesystem via /mnt/e/

## 🚀 Automated Setup Process

### Phase 1: Connection Establishment
```bash
# Claude can execute these steps automatically
~/.dotfiles/bin/ssh_windows_wsl               # Test connection
./scripts/server_control.sh status           # Verify remote access
```

**Claude Actions:**
1. Test SSH connectivity using dotfiles tool
2. Verify remote host accessibility
3. Scan network if primary IP fails
4. Report connection status

### Phase 2: Environment Preparation
```bash
# Ubuntu WSL2 environment setup
ssh chris@windows-host "mkdir -p /mnt/e/deep.space.10/{server,backups,logs}"
ssh chris@windows-host "mkdir -p /mnt/e/deep.space.10/server/BepInEx/{plugins,config}"
```

**Claude Actions:**
1. Create Windows directory structure via WSL2 (/mnt/e/deep.space.10)
2. Set appropriate file permissions for cross-platform access
3. Verify Valheim dedicated server files
4. Ensure Linux executable has proper permissions

### Phase 3: Server Installation
```bash
# Server installation approach
# Copy from existing installation or use DepotDownloader
ssh chris@windows-host "cp -r /path/to/valheim/server/* /mnt/e/deep.space.10/server/"

# Ensure Linux server executable is present
ssh chris@windows-host "chmod +x /mnt/e/deep.space.10/server/valheim_server.x86_64"
```

**Claude Actions:**
1. Check for existing Valheim dedicated server in Windows Steam
2. Copy from Steam library OR download via SteamCMD
3. Validate installation integrity
4. Install BepInEx framework
5. Generate Windows .bat files for server control

### Phase 4: Configuration Deployment
```bash
# Use existing deployment script
python3 scripts/deploy_server.py
```

**Claude Actions:**
1. Execute deployment pipeline
2. Copy server configurations
3. Install modpack files
4. Configure BepInEx settings

### Phase 5: Service Configuration
```bash
# Server startup scripts and services
./scripts/server_control.sh deploy
```

**Claude Actions:**
1. Configure server startup scripts
2. Set up logging directories
3. Install health monitoring
4. Test server startup process

## 🛠️ Claude Tool Integration Specification

### SSH Connection Management
```python
# Integration with dotfiles ssh tool
def establish_connection():
    """Use dotfiles tool for reliable SSH connection"""
    result = subprocess.run([
        "~/.dotfiles/bin/ssh_windows_wsl", 
        "steam", 
        "192.168.1.236"
    ], capture_output=True)
    return result.returncode == 0
```

### File Transfer Operations
```python
# Enhanced rsync with progress monitoring
def sync_server_files():
    """Sync files with progress reporting"""
    sync_commands = [
        "rsync -avz --progress ./src/server/ steam@windows-host:/mnt/c/deep.space.10/server/",
        "rsync -avz --progress ./src/modpack/ steam@windows-host:/mnt/c/deep.space.10/server/BepInEx/"
    ]
    for cmd in sync_commands:
        yield execute_with_progress(cmd)
```

### Health Check Integration
```python
# Comprehensive server validation
def validate_server_setup():
    """Run all validation checks"""
    checks = [
        "scripts/server_control.sh status",
        "scripts/server_control.sh status",
        "scripts/verify_server.py"
    ]
    return all(run_check(check) for check in checks)
```

## 📊 Monitoring & Validation

### Automated Health Checks
```bash
# Claude can run these periodically
./scripts/server_control.sh status          # Comprehensive status and health check
./scripts/verify_server.py                  # Server verification
```

### Performance Monitoring
```bash
# Resource usage monitoring
ssh steam@windows-host "wmic process where name='valheim_server.exe' get PageFileUsage,WorkingSetSize"
ssh steam@windows-host "netstat -an | findstr :245[6-8]"
```

### Log Analysis
```bash
# Automated log monitoring
./scripts/tail_logs.sh server               # Real-time logs
./scripts/tail_logs.sh errors               # Error monitoring
```

## 🔄 Maintenance Automation

### Update Pipeline
```bash
# Automated server updates
./scripts/server_control.sh update          # Update via SteamCMD
python3 scripts/deploy_server.py            # Deploy changes
./scripts/server_control.sh restart         # Restart services
```

### Backup Management
```bash
# Automated backup creation
./scripts/backup_world.sh                   # World backup
./scripts/server_control.sh backup          # Quick backup
```

## 🎮 Claude Interaction Patterns

### Setup Command Flow
```
User: "Set up the Valheim server"
Claude:
1. Use ssh_windows_wsl to test connection
2. Run server_control.sh status to check current state
3. Execute deploy_server.py for full deployment
4. Run server_control.sh status to validate setup
5. Report setup status and next steps
```

### Monitoring Command Flow
```
User: "Check server status"
Claude:
1. Run server_control.sh status
2. Parse output for key metrics
3. Check detailed status output
4. Provide actionable recommendations
```

### Troubleshooting Command Flow
```
User: "Server isn't working"
Claude:
1. Run comprehensive diagnostics via existing scripts
2. Check logs using tail_logs.sh
3. Test connectivity using ssh_windows_wsl
4. Provide specific remediation steps
```

## 🔧 Configuration Management

### Server Configuration Template
```json
{
  "server_name": "deep.space.10",
  "world_name": "DeepSpace10", 
  "password": "${SECURE_PASSWORD}",
  "public": false,
  "port": 2456,
  "save_interval": 1800,
  "backup_short": 7200,
  "backup_long": 43200,
  "crossplay": true,
  "preset": "normal",
  "console": true,
  "logfile": "/mnt/e/deep.space.10/logs/server.log"
}
```

### BepInEx Configuration
```ini
[Logging.Console]
Enabled = true
LogLevels = Fatal, Error, Warning, Message, Info

[Logging.Disk]
Enabled = true
LogLevels = Fatal, Error, Warning, Message, Info

[Preloader.Entrypoint] 
Type = MonoBehaviour
```

## 🚨 Error Handling & Recovery

### Connection Failures
```bash
# Automatic retry with network scanning
if ! ~/.dotfiles/bin/ssh_windows_wsl; then
    echo "Primary connection failed, scanning network..."
    ~/.dotfiles/bin/ssh_windows_wsl - auto-discover
fi
```

### Deployment Failures
```python
# Rollback capability
def deploy_with_rollback():
    backup_current_state()
    try:
        deploy_new_version()
        validate_deployment()
    except DeploymentError:
        restore_from_backup()
        raise
```

### Service Recovery
```bash
# Automatic service recovery
./scripts/server_control.sh status || {
    echo "Server not responding, attempting recovery..."
    ./scripts/server_control.sh restart
    sleep 30
    ./scripts/server_control.sh status
}
```

## 📝 Usage Examples

### Initial Server Setup
```bash
# Claude executes this sequence
~/.dotfiles/bin/ssh_windows_wsl chris 192.168.1.236
python3 scripts/deploy_server.py
./scripts/server_control.sh start
./scripts/server_control.sh status
```

### Daily Maintenance
```bash
# Automated daily tasks
./scripts/server_control.sh status
./scripts/backup_world.sh daily
```

### Update Deployment
```bash
# Update process
./scripts/server_control.sh stop
python3 scripts/deploy_server.py
./scripts/server_control.sh start
./scripts/verify_server.py
```

## 🎯 Success Criteria

### Setup Validation
- [ ] SSH connection established via dotfiles tool
- [ ] Valheim dedicated server installed
- [ ] BepInEx framework configured
- [ ] Modpack deployed successfully
- [ ] Server responds to status checks
- [ ] All ports listening (2456-2458)
- [ ] Health checks pass completely

### Operational Validation  
- [ ] Server starts/stops reliably
- [ ] Automated backups working
- [ ] Log monitoring functional
- [ ] Update process tested
- [ ] Recovery procedures verified

### Claude Integration Validation
- [ ] All existing scripts callable via Claude
- [ ] dotfiles tools accessible
- [ ] Error handling provides useful feedback
- [ ] Monitoring reports actionable information
- [ ] Maintenance tasks can be automated

## 🔮 Extension Points

### Future Automation
- World backup scheduling
- Player activity monitoring
- Performance metrics collection
- Automatic mod updates
- Capacity scaling alerts

### Tool Integration
- Discord bot notifications
- Web dashboard creation
- Mobile app integration
- Cloud backup synchronization

---

*This specification enables Claude Code CLI to fully automate deep.space.10 server setup using existing tooling infrastructure*