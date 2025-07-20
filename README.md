# deep.space.10 Valheim Server Workspace

Automated deployment and management system for the deep.space.10 Valheim server with modpack distribution.

## 🚀 Quick Start

### Prerequisites
- SSH access to Windows host with WSL
- Python 3.8+
- Steam and SteamCMD on target host

### Initial Setup
```bash
# 1. Initialize remote workspace
./scripts/init_workspace.sh

# 2. Deploy server
python3 scripts/deploy_server.py

# 3. Verify deployment
python3 tests/verify_server.py
```

## 📁 Project Structure

```
deep.space.10-workspace/
├── scripts/           # Automation scripts
├── config/           # Configuration files
├── src/              # Source files
│   ├── server/       # Server batch scripts
│   └── modpack/      # Modpack files and installer
├── tests/            # Testing framework
├── logs/             # Health monitoring logs
├── deploy/           # Build artifacts
└── .github/          # CI/CD workflows
```

## 🛠️ Scripts Reference

### Core Operations
- `./scripts/init_workspace.sh` - Initialize remote workspace
- `./scripts/deploy_server.py` - Deploy server and configuration
- `./scripts/build_modpack.py [version]` - Build modpack distribution
- `./scripts/server_control.sh [command]` - Server management

### Monitoring & Maintenance
- `./scripts/health_check.py` - Comprehensive health check
- `./scripts/verify_loop.sh [interval]` - Continuous monitoring
- `./scripts/backup_world.sh [type]` - World backups
- `./scripts/tail_logs.sh [log_type]` - Log viewing

### Development
- `./scripts/sync_dev.sh [direction]` - Sync dev files
- `python3 tests/integration_tests.py` - End-to-end testing

## 🎮 Server Management

### Basic Commands
```bash
# Server control
./scripts/server_control.sh start
./scripts/server_control.sh stop
./scripts/server_control.sh status
./scripts/server_control.sh restart

# Health monitoring
python3 scripts/health_check.py
./scripts/verify_loop.sh 300  # Check every 5 minutes

# View logs
./scripts/tail_logs.sh server
./scripts/tail_logs.sh bepinex
./scripts/tail_logs.sh all
```

### Backup Management
```bash
# Create backups
./scripts/backup_world.sh full --download
./scripts/backup_world.sh world-only
./scripts/backup_world.sh configs-only
```

## 📦 Modpack Development

### Building Modpacks
```bash
# Build current version
python3 scripts/build_modpack.py

# Build specific version
python3 scripts/build_modpack.py "2.1.0"

# Test modpack
python3 tests/test_modpack.py
```

### Distribution Files
Built modpacks are placed in `./deploy/` with:
- `deep.space.10-v{version}.zip` - Main distribution
- `checksums.txt` - Verification hashes

## 🧪 Testing

### Test Suites
```bash
# Server verification
python3 tests/verify_server.py

# Modpack validation
python3 tests/test_modpack.py

# Integration tests
python3 tests/integration_tests.py
```

### Test Coverage
- ✅ Server process monitoring
- ✅ Port availability checking
- ✅ Mod loading verification
- ✅ Memory and disk usage
- ✅ Configuration validation
- ✅ Build process testing

## 🔄 CI/CD Pipeline

The GitHub Actions workflow automatically:
1. Validates configuration files
2. Runs comprehensive test suites
3. Builds modpack distributions
4. Deploys to server (on mainline branch)
5. Performs security scanning
6. Uploads build artifacts

### Required Secrets
- `SSH_PRIVATE_KEY` - Deploy key for server access
- `SSH_KNOWN_HOSTS` - Known hosts file content

## 📊 Monitoring

### Health Checks
The health monitoring system tracks:
- Server process status
- Network port availability  
- Memory and disk usage
- Mod loading status
- Player connections
- System uptime

### Alerts
Configure alerts via environment variables:
```bash
export ALERT_EMAIL="admin@example.com"
export ALERT_WEBHOOK="https://hooks.slack.com/..."
```

## 🔧 Configuration

### SSH Configuration
Edit `config/ssh_config` for your environment:
```
Host windows-host
    HostName your.server.ip
    User your-username
    Port 22
    IdentityFile ~/.ssh/your_key
```

### Server Configuration
Modify `config/server_config.json`:
```json
{
  "server_name": "deep.space.10",
  "world_name": "YourWorld",
  "password": "your-password",
  "port": 2456
}
```

## 🔐 Security

- Use dedicated SSH keys for deployment
- Restrict firewall ports to minimum required
- Regular backup rotation and cleanup
- Automated security scanning in CI/CD
- No credentials stored in version control

## 📈 Performance

### Optimization Settings
- Automatic memory usage monitoring
- Disk space alerts at 95% capacity
- Process restart on consecutive failures
- Backup cleanup (keeps 10 most recent)

### Scaling
- Health check intervals configurable
- Modular script architecture
- Parallel test execution
- Artifact caching in CI/CD

## 🆘 Troubleshooting

### Common Issues

**SSH Connection Fails**
```bash
# Test SSH connectivity
ssh -F config/ssh_config steam@windows-host "echo 'Connection OK'"
```

**Server Won't Start**
```bash
# Check logs
./scripts/tail_logs.sh error
./scripts/server_control.sh status
```

**Mods Not Loading**
```bash
# Verify BepInEx installation
./scripts/tail_logs.sh bepinex
python3 tests/verify_server.py
```

### Debug Mode
Enable verbose logging:
```bash
export LOG_LEVEL=DEBUG
python3 scripts/health_check.py
```

## 📚 Additional Resources

- [Valheim Dedicated Server Guide](https://valheim.fandom.com/wiki/Dedicated_server)
- [BepInEx Documentation](https://docs.bepinex.dev/)
- [Project Issue Tracker](../../issues)

---

**Automated Infrastructure for deep.space.10 Community**