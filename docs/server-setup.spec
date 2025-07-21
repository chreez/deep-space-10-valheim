# deep.space.10 Server Setup Specification

## 🎯 Overview
Complete automation specification for setting up a deep.space.10 Valheim server using Docker containers and secure environment management with Claude Code CLI integration.

## 🏗️ Architecture Integration

### Docker-First Environment
```
Local macOS           →    Windows Host (WSL2)    →    Docker Container
├── ssh_windows_wsl   →    Docker commands        →    Valheim Server
├── .env config       →    Volume mounts          →    Persistent data
├── deploy scripts    →    Container lifecycle    →    BepInEx + Mods
└── health checks     →    Container monitoring   →    Server validation
```

### Simplified Tool Ecosystem
```
Local Development      →    WSL2 Docker Host       →    Container Execution
├── ssh_windows_wsl    →    Docker run/stop        →    lloesche/valheim-server
├── .env management    →    Environment variables  →    Server configuration
├── volume mounting    →    /mnt/e/ persistence    →    World/mod data
└── health_check.py    →    Container monitoring   →    Service validation
```

### Claude + Dotfiles Integration
```bash
# Available via dotfiles system
~/.dotfiles/bin/ssh_windows_wsl              # Windows/WSL connection
~/.dotfiles/bin/sync_windows_wsl             # File synchronization
# Project-specific tools (Docker-focused)
./scripts/docker_deploy.sh                   # Container deployment
./scripts/server_control.sh                  # Docker container lifecycle
./scripts/health_check.py                    # Container health monitoring
```

## 📋 Setup Prerequisites

### Local Requirements
- SSH key pair configured for target Windows host
- Python 3.8+ with required dependencies
- rsync for file synchronization
- Access to Chris's dotfiles system

### Remote Host Requirements
- **Windows 10/11 Host:**
  - WSL2 enabled and configured
  - Docker installed (Docker Desktop or WSL2 Docker)
  - E: drive or persistent storage mounted as /mnt/e/
  - Ports 2456-2458 UDP forwarded
- **WSL2 Environment:**
  - SSH server configured for remote access
  - Docker daemon running
  - Access to Windows filesystem via /mnt/e/
  - Environment file (.env) with secure credentials

## 🚀 Automated Setup Process

### Phase 1: Connection & Environment Setup
```bash
# Claude can execute these steps automatically
~/.dotfiles/bin/ssh_windows_wsl               # Test connection
~/.dotfiles/bin/ssh_windows_wsl --command "docker --version"  # Verify Docker
source .env                                   # Load environment variables
```

**Claude Actions:**
1. Test SSH connectivity using dotfiles tool
2. Verify Docker is running on remote host
3. Load secure environment configuration
4. Validate .env file contains required variables

### Phase 2: Storage & Container Preparation
```bash
# Create persistent storage directories
~/.dotfiles/bin/ssh_windows_wsl --command "mkdir -p ${SERVER_DATA_PATH}/{config,worlds,backups,logs}"
~/.dotfiles/bin/ssh_windows_wsl --command "mkdir -p ${SERVER_DATA_PATH}/config/BepInEx/{plugins,config}"

# Pull Docker image
~/.dotfiles/bin/ssh_windows_wsl --command "docker pull ${DOCKER_IMAGE}"
```

**Claude Actions:**
1. Create persistent storage structure on E: drive via WSL2
2. Set up BepInEx directories for mod support
3. Pull latest Valheim server Docker image
4. Verify storage permissions and accessibility

### Phase 3: Container Deployment
```bash
# Deploy server container with environment variables
~/.dotfiles/bin/ssh_windows_wsl --command "
docker run -d --name ${CONTAINER_NAME} \
  -p ${PORT_RANGE}:${PORT_RANGE}/udp \
  -v ${SERVER_DATA_PATH}:/config \
  -e SERVER_NAME='${SERVER_NAME}' \
  -e WORLD_NAME='${WORLD_NAME}' \
  -e SERVER_PASS='${SERVER_PASS}' \
  -e PUBLIC=${PUBLIC} \
  -e SERVER_TOKEN='${SERVER_TOKEN}' \
  ${DOCKER_IMAGE}
"
```

**Claude Actions:**
1. Deploy Docker container with secure environment variables
2. Mount persistent storage volumes
3. Configure network ports (2456-2458 UDP)
4. Validate container startup and health
5. No manual server installation required (handled by container)

### Phase 4: Mod & Configuration Deployment
```bash
# Deploy modpack to container volume
~/.dotfiles/bin/sync_windows_wsl ./src/modpack/ ${SERVER_DATA_PATH}/config/BepInEx/

# Restart container to load mods
~/.dotfiles/bin/ssh_windows_wsl --command "docker restart ${CONTAINER_NAME}"
```

**Claude Actions:**
1. Sync modpack files to persistent volume
2. Deploy BepInEx configuration files
3. Restart container to load new mods
4. Validate mod loading in container logs

### Phase 5: Validation & Monitoring Setup
```bash
# Validate container and server status
~/.dotfiles/bin/ssh_windows_wsl --command "docker ps | grep ${CONTAINER_NAME}"
~/.dotfiles/bin/ssh_windows_wsl --command "docker logs -n 50 ${CONTAINER_NAME}"

# Test server connectivity
./scripts/health_check.py --docker
```

**Claude Actions:**
1. Verify container is running and healthy
2. Check server logs for successful startup
3. Validate network connectivity on game ports
4. Confirm GSLT token authentication
5. Test client connection capabilities

## 🛠️ Claude Tool Integration Specification

### Environment Variable Management
```python
# Load secure environment configuration
def load_environment():
    """Load .env file with security validation"""
    required_vars = ['SERVER_NAME', 'SERVER_PASS', 'SERVER_TOKEN', 'CONTAINER_NAME']
    env_vars = load_dotenv('.env')
    missing = [var for var in required_vars if not os.getenv(var)]
    if missing:
        raise EnvironmentError(f"Missing required environment variables: {missing}")
    return env_vars
```

### Docker Container Management
```python
# Docker operations via SSH
def deploy_container():
    """Deploy Valheim server container"""
    load_environment()
    docker_cmd = f"""
    docker run -d --name {os.getenv('CONTAINER_NAME')} \
      -p {os.getenv('PORT_RANGE')}:{os.getenv('PORT_RANGE')}/udp \
      -v {os.getenv('SERVER_DATA_PATH')}:/config \
      -e SERVER_NAME='{os.getenv('SERVER_NAME')}' \
      -e WORLD_NAME='{os.getenv('WORLD_NAME')}' \
      -e SERVER_PASS='{os.getenv('SERVER_PASS')}' \
      -e PUBLIC={os.getenv('PUBLIC')} \
      -e SERVER_TOKEN='{os.getenv('SERVER_TOKEN')}' \
      {os.getenv('DOCKER_IMAGE')}
    """
    return subprocess.run(['~/.dotfiles/bin/ssh_windows_wsl', '--command', docker_cmd])
```

### Container Health Validation
```python
# Container-specific health checks
def validate_container_health():
    """Validate Docker container and server status"""
    checks = [
        "docker ps | grep valheim-server",
        "docker logs --tail 20 valheim-server | grep 'Game server connected'",
        "netstat -ln | grep :2456"
    ]
    return all(run_remote_check(check) for check in checks)
```

## 📊 Monitoring & Validation

### Automated Health Checks
```bash
# Docker-based health monitoring
~/.dotfiles/bin/ssh_windows_wsl --command "docker ps --filter name=${CONTAINER_NAME}"
~/.dotfiles/bin/ssh_windows_wsl --command "docker stats ${CONTAINER_NAME} --no-stream"
./scripts/health_check.py --docker          # Container-aware validation
```

### Performance Monitoring
```bash
# Container resource monitoring
~/.dotfiles/bin/ssh_windows_wsl --command "docker stats ${CONTAINER_NAME} --no-stream"
~/.dotfiles/bin/ssh_windows_wsl --command "docker exec ${CONTAINER_NAME} netstat -ln | grep :2456"
```

### Log Analysis
```bash
# Container log monitoring
~/.dotfiles/bin/ssh_windows_wsl --command "docker logs -f ${CONTAINER_NAME}"
~/.dotfiles/bin/ssh_windows_wsl --command "docker logs ${CONTAINER_NAME} | grep -i error"
```

## 🔄 Maintenance Automation

### Update Pipeline
```bash
# Container-based server updates
~/.dotfiles/bin/ssh_windows_wsl --command "docker pull ${DOCKER_IMAGE}"
~/.dotfiles/bin/ssh_windows_wsl --command "docker stop ${CONTAINER_NAME}"
~/.dotfiles/bin/ssh_windows_wsl --command "docker rm ${CONTAINER_NAME}"
# Re-deploy with new image using Phase 3 commands
```

### Backup Management
```bash
# Volume-based backup strategy
~/.dotfiles/bin/ssh_windows_wsl --command "docker exec ${CONTAINER_NAME} tar -czf /config/backup_\$(date +%Y%m%d_%H%M%S).tar.gz /config/worlds/"
~/.dotfiles/bin/sync_windows_wsl --from ${SERVER_DATA_PATH}/backup_*.tar.gz ./backups/
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