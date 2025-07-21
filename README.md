```
╔══════════════════════════════════════════════════════════════╗
║    ·  · ✦  D E E P . S P A C E . 1 0  ✦ ·  ·               ║
║         Where Vikings Meet the Void                          ║
╚══════════════════════════════════════════════════════════════╝
```

# deep.space.10 Valheim Server Workspace

▪ **Mission**: Forge the ultimate modded Valheim experience for Space Vikings  
▪ **Vision**: Simple, foolproof server and modpack management across the cosmos

## 🚀 Quick Modpack Installation (Space Vikings)

**PLACEHOLDER - Modpack Setup Guide**
```
[ TRANSMISSION INCOMING - MODPACK DEPLOYMENT PROTOCOL ]

1. [..] ◦ Download deep.space.10-modpack-v{latest}.zip
2. [..] ◦ Extract to your Valheim installation directory  
3. [..] ◦ Run install.cmd for automated deployment
4. [OK] ✓ Launch Valheim and join deep.space.10 server
5. [!!] ▲ Manual installation guide available below

[ END TRANSMISSION ]
```

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## ▪ SPACE VIKING COMMAND CENTER

### ◆ Prerequisites for Server Deployment
- ✓ SSH access to Windows host with WSL
- ✓ Docker installed on target system
- ✓ Steam Game Server Login Token (GSLT)

### ▸ Server Control (Single Command Interface)
```bash
# Primary interface - health check (default)
./scripts/server_control.sh

# Deploy server files to remote host
./scripts/server_control.sh deploy

# Restart server (headless Docker container)
./scripts/server_control.sh restart
```

## ▪ COMMAND STRUCTURE

```
deep.space.10-workspace/
├── scripts/           # [OK] ✓ Automation protocols  
│   └── server_control.sh  # ◆ Primary command interface
├── config/           # [..] ◦ Configuration matrices
├── src/              # [..] ◦ Source artifacts
│   ├── server/       # ▸ Server deployment files
│   └── modpack/      # ▸ Modpack distribution system
├── tests/            # [!!] ▲ Validation protocols
├── logs/             # [..] ◦ System telemetry
├── deploy/           # [OK] ✓ Build artifacts
└── docs/             # [..] ◦ Technical documentation
```

## ▪ COMMAND PROTOCOLS

### ◆ Primary Interface
- `./scripts/server_control.sh` - **Default**: Health check and status
- `./scripts/server_control.sh deploy` - Deploy server files via atomic sync
- `./scripts/server_control.sh restart` - Restart Docker container (headless)

### ◆ Legacy Operations (Deprecated)
- `./scripts/build_modpack.py [version]` - Build modpack distribution
- `./scripts/backup_world.sh [type]` - World backups  
- `./scripts/tail_logs.sh [log_type]` - Direct log viewing

## ▪ SERVER COMMAND MATRIX

### ◆ Unified Control Interface
```bash
# [..] ◦ Health check and system status (default)
./scripts/server_control.sh

# [..] ◦ Deploy server configuration and files  
./scripts/server_control.sh deploy

# [OK] ✓ Restart containerized server (headless)
./scripts/server_control.sh restart
```

### ◆ Docker Container Configuration
```bash
# BepInEx-enabled server deployment
docker run -d --name valheim-server \
  -p 2456-2458:2456-2458/udp \
  -v /mnt/e/deep.space.10/server:/config \
  -e SERVER_NAME="DeepSpace10" \
  -e WORLD_NAME="DeepSpace10" \
  -e SERVER_PASS="${SERVER_PASS}" \
  -e PUBLIC="0" \
  -e SERVER_TOKEN="${SERVER_TOKEN}" \
  -e BEPINEX=true \
  lloesche/valheim-server
```

### ◆ Mod Deployment Protocol
```bash
# [..] ◦ Server mod directory structure
/mnt/e/deep.space.10/server
├── BepInEx
│   └── plugins
│       └── <modname>

# [!!] ▲ Manual mod installation (Space Viking method)
cd /mnt/e/deep.space.10/server/BepInEx/plugins
curl -L -o AzuClock.zip "https://thunderstore.io/package/download/Azumatt/AzuClock/1.0.5/"
unzip AzuClock.zip && rm AzuClock.zip

# [OK] ✓ Verify mod loading in container logs
docker logs valheim-server | grep "Loading \["
# Expected: "[Info   :   BepInEx] Loading [AzuClock 1.0.5]"
```

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## ▪ MODPACK DISTRIBUTION SYSTEM

### ◆ Building Modpack Artifacts
```bash
# [..] ◦ Build current version
python3 scripts/build_modpack.py

# [..] ◦ Build specific version
python3 scripts/build_modpack.py "2.1.0"

# [!!] ▲ Test modpack integrity
python3 tests/test_modpack.py
```

### ◆ Distribution Artifacts
Built modpacks are deployed to `./deploy/` containing:
- `deep.space.10-v{version}.zip` - ▸ Main distribution archive
- `checksums.txt` - ▸ Verification hashes

## ▪ VALIDATION PROTOCOLS

### ◆ Test Matrix
```bash
# [OK] ✓ Server verification
python3 tests/verify_server.py

# [..] ◦ Modpack validation  
python3 tests/test_modpack.py

# [!!] ▲ Integration tests
python3 tests/integration_tests.py
```

### ◆ Coverage Analysis
- ✓ Container health monitoring
- ✓ Port availability scanning
- ✓ BepInEx mod loading verification
- ✓ Resource usage telemetry
- ✓ Configuration matrix validation
- ✓ Build artifact integrity

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## ▪ TROUBLESHOOTING PROTOCOLS

### ◆ Common System Failures

**[XX] ✗ SSH Connection Failure**
```bash
# [..] ◦ Test connection to remote host
~/.dotfiles/bin/ssh_windows_wsl --command "echo 'Connection Test'"
```

**[XX] ✗ Container Not Responding**
```bash
# [!!] ▲ Check container status
./scripts/server_control.sh

# [..] ◦ Restart if necessary
./scripts/server_control.sh restart
```

**[XX] ✗ Mods Not Loading**
```bash
# [!!] ▲ Verify BepInEx loading in container logs
docker logs valheim-server | grep "Loading \["
# Expected: "[Info : BepInEx] Loading [ModName Version]"
```

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## ▪ TECHNICAL DOCUMENTATION

### ◆ Reference Materials
- **[Server Setup Guide](docs/gslt-token-guide.md)** - Steam authentication
- **[Project Requirements](docs/prd.md)** - Architecture and vision
- **[BepInEx Documentation](https://docs.bepinex.dev/)** - Mod framework
- **[lloesche/valheim-server](docs/)** - Docker container reference

### ◆ Support Channels
- **[Project Issue Tracker](../../issues)** - Bug reports and features
- **[Valheim Modding Wiki](https://valheim.fandom.com/wiki/Dedicated_server)** - Community resources

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

```
[ TRANSMISSION END ]

           ·  · ✦  deep.space.10 Command Center  ✦ ·  ·
                Where Vikings Conquer the Void

             Automated Infrastructure for Space Vikings
                        across the Nine Realms
```