```markdown
# deep.space.10 Workspace Initialization Spec

## 🎯 Objective
Automate the setup, deployment, and verification of deep.space.10 server and modpack distribution system using SSH/WSL access to Windows host machine.

## 🏗️ Architecture Overview

```
[Local Dev Machine] ─── SSH/SCP ──→ [Windows Host (WSL)]
        ↓                                    ↓
[Build Scripts]                    [Valheim Server]
[Test Suite]                       [BepInEx + Mods]
[Deploy Tools]                     [Distribution Files]
```

## 📋 Prerequisites

### Windows Host Requirements
- Windows 10/11 with WSL2 enabled
- SSH server running (OpenSSH or WSL SSH)
- Steam installed with Valheim
- SteamCMD accessible via PATH
- Sufficient disk space (20GB+)
- Ports 2456-2458 open for UDP

### Local Dev Requirements
- SSH client with key-based auth
- rsync or scp available
- Python 3.8+ (for automation scripts)

## 🔧 Workspace Structure

```
deep.space.10-workspace/
├── scripts/
│   ├── init_workspace.sh
│   ├── deploy_server.sh
│   ├── test_server.sh
│   └── build_modpack.sh
├── config/
│   ├── server_config.json
│   ├── ssh_config
│   └── test_scenarios.yaml
├── src/
│   ├── server/
│   │   ├── start_server.bat
│   │   ├── stop_server.bat
│   │   └── backup_world.bat
│   └── modpack/
│       ├── install.cmd
│       ├── manifest.json
│       └── mods/
├── tests/
│   ├── verify_server.py
│   ├── test_modpack.py
│   └── integration_tests.py
└── deploy/
    └── .gitkeep
```

## 🚀 Initialization Script

### `init_workspace.sh`
```bash
#!/bin/bash
echo "╔══════════════════════════════════════════════╗"
echo "║    deep.space.10 Workspace Initializer       ║"
echo "╚══════════════════════════════════════════════╝"

# Configuration
REMOTE_HOST="windows-host"
REMOTE_USER="steam"
WORKSPACE_DIR="/mnt/c/deep.space.10"

# Steps
echo "[..] ◦ Creating remote workspace..."
ssh $REMOTE_USER@$REMOTE_HOST "mkdir -p $WORKSPACE_DIR/{server,modpack,backups,logs}"

echo "[..] ◦ Installing Valheim Dedicated Server..."
ssh $REMOTE_USER@$REMOTE_HOST "steamcmd +force_install_dir $WORKSPACE_DIR/server +login anonymous +app_update 896660 validate +quit"

echo "[..] ◦ Setting up BepInEx..."
# Download and extract BepInEx to server

echo "[OK] ✓ Workspace initialized"
```

## 📦 Deployment Pipeline

### 1. Server Deployment
```python
# deploy_server.py
class ServerDeployer:
    def __init__(self, ssh_config):
        self.ssh = paramiko.SSHClient()
        self.config = ssh_config
    
    def deploy(self):
        # Copy server files
        self.copy_files()
        # Configure server
        self.configure_server()
        # Install mods
        self.install_server_mods()
        # Start server
        self.start_server()
        # Verify running
        return self.verify_server_status()
```

### 2. Modpack Building
```python
# build_modpack.py
def build_modpack(version):
    """Build distribution package"""
    steps = [
        collect_mod_files(),
        generate_manifest(),
        create_install_script(),
        package_zip(f"deep.space.10-v{version}.zip"),
        generate_checksums()
    ]
    return all(steps)
```

## 🧪 Testing Framework

### Server Verification Tests
```python
# verify_server.py
class ServerTests:
    def test_server_running(self):
        """Check if server process is active"""
        result = ssh_exec("tasklist | findstr valheim_server")
        assert "valheim_server.exe" in result
    
    def test_port_listening(self):
        """Verify game ports are open"""
        for port in [2456, 2457, 2458]:
            result = ssh_exec(f"netstat -an | findstr :{port}")
            assert "LISTENING" in result
    
    def test_mod_loading(self):
        """Check BepInEx log for mod initialization"""
        log = ssh_exec("type $WORKSPACE_DIR/server/BepInEx/LogOutput.log")
        assert "deep.space.10" in log
        assert "plugins loaded" in log
    
    def test_client_connection(self):
        """Attempt client connection to verify"""
        # Use Valheim API or packet test
        pass
```

### Modpack Installation Tests
```python
# test_modpack.py
def test_clean_install():
    """Test modpack on fresh Valheim install"""
    ssh_exec("xcopy /E /I test_valheim_clean test_valheim_temp")
    ssh_exec("cd test_valheim_temp && install.cmd")
    assert verify_files_exist()
    assert no_overwritten_configs()
```

## 🔄 Continuous Integration

### GitHub Actions Workflow
```yaml
name: deep.space.10 CI/CD
on: [push, pull_request]

jobs:
  test-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Setup SSH
        run: |
          mkdir -p ~/.ssh
          echo "${{ secrets.SSH_KEY }}" > ~/.ssh/id_rsa
          chmod 600 ~/.ssh/id_rsa
      
      - name: Initialize Workspace
        run: ./scripts/init_workspace.sh
      
      - name: Run Server Tests
        run: python tests/verify_server.py
      
      - name: Build Modpack
        run: ./scripts/build_modpack.sh
      
      - name: Test Modpack
        run: python tests/test_modpack.py
      
      - name: Deploy if Main
        if: github.ref == 'refs/heads/main'
        run: ./scripts/deploy_release.sh
```

## 📊 Monitoring & Verification

### Health Check Script
```python
# health_check.py
def server_health_check():
    checks = {
        "process": check_process_running(),
        "ports": check_ports_open(),
        "memory": check_memory_usage() < 4096,
        "disk": check_disk_space() > 5000,
        "players": get_player_count(),
        "uptime": get_server_uptime(),
        "mods": verify_mod_versions()
    }
    return all(checks.values()), checks
```

### Automated Verification Loop
```bash
#!/bin/bash
# verify_loop.sh
while true; do
    echo "[..] ◦ Running health check..."
    python health_check.py
    if [ $? -eq 0 ]; then
        echo "[OK] ✓ Server healthy"
    else
        echo "[!!] ▲ Server issue detected"
        # Send alert
    fi
    sleep 300  # 5 minutes
done
```

## 🛠️ Utility Scripts

### Sync Development Files
```bash
# sync_dev.sh
rsync -avz --exclude 'node_modules' --exclude '.git' \
    ./src/ $REMOTE_USER@$REMOTE_HOST:$WORKSPACE_DIR/
```

### Backup World
```bash
# backup_world.sh
ssh $REMOTE_USER@$REMOTE_HOST \
    "cd $WORKSPACE_DIR && tar -czf backups/world_$(date +%Y%m%d_%H%M%S).tar.gz server/worlds/"
```

### View Server Logs
```bash
# tail_logs.sh
ssh $REMOTE_USER@$REMOTE_HOST \
    "tail -f $WORKSPACE_DIR/server/logs/output.log"
```

## 🔐 Security Considerations

1. **SSH Key Management**
   - Use dedicated deploy key
   - Restrict key permissions
   - Rotate regularly

2. **Windows Firewall**
   - Only open required ports
   - Whitelist specific IPs if possible

3. **File Permissions**
   - Restrict write access to server files
   - Separate user for game server

## 📈 Success Metrics

- **Deployment Time**: < 5 minutes from commit to running
- **Test Coverage**: 100% critical paths
- **Verification Accuracy**: Zero false positives
- **Automation Rate**: 95% hands-off operation

## 🚦 Implementation Phases

### Phase 1: Basic Setup (Week 1)
- [ ] Manual SSH setup and verification
- [ ] Basic workspace structure
- [ ] Simple deployment scripts

### Phase 2: Automation (Week 2)
- [ ] Python test framework
- [ ] CI/CD pipeline
- [ ] Automated health checks

### Phase 3: Polish (Week 3)
- [ ] Error handling and recovery
- [ ] Performance optimization
- [ ] Documentation and training

---

This spec provides a complete framework for agentically managing the deep.space.10 server setup and testing via SSH/WSL access.
```