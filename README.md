```
╔══════════════════════════════════════════════════════════════╗
║    ·  · ✦  D E E P . S P A C E . 1 0  ✦ ·  ·               ║
║         Where Vikings Meet the Void                          ║
╚══════════════════════════════════════════════════════════════╝
```

# deep.space.10 Valheim Server Workspace

▪ **Mission**: Forge the ultimate modded Valheim experience for Space Vikings  
▪ **Vision**: Simple, foolproof server and modpack management across the cosmos

## 🚀 Quick Modpack Installation (Players)

**r2modman Profile Code: `01983a2e-22a5-26ae-35a4-8858c59c0849`**

```
[ TRANSMISSION INCOMING - MODPACK DEPLOYMENT PROTOCOL ]

Mod management is now handled via r2modman for optimal compatibility.

1. [..] ◦ Install r2modman from [Thunderstore](https://www.overwolf.com/app/Thunderstore-r2modman)
2. [..] ◦ Launch r2modman and select Valheim
3. [..] ◦ Click "Import Profile" and enter code: 01983a2e-22a5-26ae-35a4-8858c59c0849
4. [OK] ✓ Launch Valheim via r2modman and join deep.space.10 server

[ END TRANSMISSION ]
```

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## ▪ MODPACK CONFIGURATION

**r2modman Profile**: `01983a2e-22a5-26ae-35a4-8858c59c0849`

*Note: Mod files are no longer maintained in this repository. All mod management is handled through r2modman for better compatibility and easier updates.*

### ◆ Included Mod Categories

### ◆ Framework & Dependencies
- **Jotunn** [Both] - Core modding framework required by many other mods
- **Zen.ModLib** [Both] - Library for Zen-prefixed mods
- **Newtonsoft.Json** [Both] - JSON processing libraries

### ◆ Building & Construction  
- **PlanBuild** [Both] - Advanced building with blueprints and planning mode
- **BalrondConstructions** [Both] - Additional building pieces and decorative structures
- **BalrondFurnitureReborn** [Both] - Decorative furniture and interior design items
- **ZenConstruction** [Both] - Construction improvements and building helpers
- **ZenRedecorate** [Client] - Reposition furniture and decorations without destroying

### ◆ Inventory & Storage
- **AdventureBackpacks** [Both] - Backpack system for extra inventory space
- **AzuCraftyBoxes** [Both] - Craft from nearby containers without manual inventory management
- **AzuAutoStore** [Both] - Automatically sort items into appropriate containers
- **AzuExtendedPlayerInventory** [Both] - Expands player inventory slots
- **QuickStackStore** [Client] - Quick stack items to nearby containers
- **CraftyCartsRemake** [Both] - Mobile storage carts with crafting capabilities
- **ZenItemStands** [Both] - Display items on stands and pedestals
- **ZenRecycle** [Both] - Alternative recycling system with configurable rates

### ◆ Gameplay & Content
- **EpicLoot** [Both] - RPG-style loot system with magical item properties
- **Warfare** [Both] - Combat enhancements and new weapons/armor
- **Almanac** [Both] - In-game encyclopedia and information system
- **AlmanacClasses** [Both] - Class system addon for Almanac
- **MagicalMounts** [Both] - Rideable creatures and mount system
- **KnowledgeTable** [Both] - Crafting knowledge and progression system
- **ZenBossStone** [Both] - Boss summoning improvements and altar enhancements
- **ZenCombat** [Both] - Combat mechanics tweaks and improvements
- **ZenRaids** [Both] - Enhanced raid system with configuration options

### ◆ Quality of Life
- **AzuAntiArthriticCrafting** [Client] - Simplifies crafting UI and reduces clicking
- **Advize_PlantEasily** [Both] - Simplified farming and planting mechanics
- **AutoRepair** [Client] - Automatically repairs items when interacting with workbenches
- **BetterCarts** [Both] - Quick detach/reattach carts, buddy pushing, and reduced cart damage
- **ComfortTweaks** [Both] - Improvements to the comfort and resting system
- **ConfigurationManager** [Client] - In-game configuration editor for BepInEx mods
- **CW_Jesse.BetterNetworking** [Both] - Network optimization for better multiplayer
- **FastLink** [Client] - Quick server joining UI with YAML configuration for favorite servers
- **Groups** [Both] - Party system with shared map pins and health bars

- **PlayerActivity** [Both] - Tracks player activity and time played
- **Recycle_N_Reclaim** [Both] - Recycle items to recover materials -- replaced by recycle
- **RockTheBoat** [Both] - Improved boat physics and handling
- **ServerCharacters** [Server] - Server-side character storage and management
- **ServersideQoL** [Server] - Server-side quality of life improvements
- **SpeedyPaths** [Both] - Faster movement on paths and roads
- **ZenCompass** [Both] - Enhanced compass with customizable markers
- **ZenMap** [Both] - Improved map features and sharing capabilities
- **ZenPlayer** [Both] - Player stats and progression enhancements
- **ZenSign** [Both] - Advanced sign system with formatting options
- **ZenUI** [Both] - UI improvements and customization options
- **ZenUseItem** [Client] - Use items directly from inventory without hotbar

### ◆ Environment & Nature
- **Seasonality** [Both] - Dynamic seasons with visual changes (includes 181 texture assets)
- **BalrondAmazingNature** [Both] - Environmental enhancements and new nature elements
- **BalrondAmazingNatureResource** [Both] - Additional natural resources and materials


### ◆ Server Administration
- **ServerDevcommands** [Server] - Enables admin commands and chat logging for servers
- **AdventureBackpacksAPI** [Both] - API framework for Adventure Backpacks mod

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## ▪ MODPACK CHANGELOG

### ◆ Version 3.0.0 - 2025-07-24
**Migration to r2modman:**
- **Profile Code**: `01983a2e-22a5-26ae-35a4-8858c59c0849`
- **Management**: Mods now managed via r2modman for better compatibility
- **Deployment**: Manual deployment using r2modman configurations
- **Repository**: Mod files removed from git repository to reduce size

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
│   └── modpack/      # ▸ Modpack metadata and manifests
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

### ◆ Mod Management
- **r2modman Profile**: `01983a2e-22a5-26ae-35a4-8858c59c0849`
- **Manual Deployment**: Mods deployed manually using r2modman
- **Server Sync**: Copy modpack from r2modman to server as needed

### ◆ Legacy Operations (Deprecated)
- `./scripts/build_modpack.py [version]` - Replaced by r2modman
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
  -p 27500-27502:27500-27502/udp \
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
# [..] ◦ r2modman profile deployment to server
r2modman Profile Code: 01983a2e-22a5-26ae-35a4-8858c59c0849

# Manual deployment steps:
# 1. Export BepInEx folder from r2modman
# 2. Copy to server directory structure:
/mnt/e/deep.space.10/server
├── BepInEx
│   ├── plugins/                    # Mod DLLs from r2modman
│   └── config/                     # Configuration from r2modman

# [OK] ✓ Verify modpack loading in container logs
docker logs valheim-server | grep "Loading \["
# Expected: "[Info : BepInEx] Loading [mod entries]"
```

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## ▪ MODPACK MANAGEMENT SYSTEM

### ◆ r2modman Profile Management
```bash
# r2modman Profile Code
01983a2e-22a5-26ae-35a4-8858c59c0849

# Manual deployment process:
# 1. Configure mods in r2modman
# 2. Export BepInEx folder
# 3. Deploy to server manually
# 4. Update profile code if needed
```

### ◆ Deployment Notes
- Mod files no longer stored in git repository
- r2modman handles all mod downloads and updates
- Server deployment is manual process for now
- Profile code provides consistent mod configuration

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

## ▪ ADMIN COMMAND PROTOCOLS

### ◆ Enabling Admin Access

**[..] ◦ Add Admin to Server**
1. Get your Steam ID (press F2 in-game or check server logs)
2. Add Steam ID to `/config/adminlist.txt` on server
3. Restart Valheim client with `-console` flag
4. Press F5 in-game to open console

**[OK] ✓ Using Admin Helper Script**
```bash
# View current admins
./scripts/send_admin_command.sh list-admins

# Add new admin (Steam ID format: 76561198xxxxxxxxx)
./scripts/send_admin_command.sh add-admin 76561198012345678

# Monitor player connections and get Steam IDs
./scripts/send_admin_command.sh monitor
```

### ◆ Server Admin Commands

Commands available to server admins (require adminlist.txt entry):

| Command | Description |
|---------|-------------|
| `help` | Shows all available admin commands |
| `kick <playername>` | Kicks a player from the server |
| `ban <playername>` | Bans a player from the server |
| `unban <playername>` | Unbans a player |
| `banned` | Lists all banned players |
| `save` | Forces world save (normally auto-saves every 30 min) |
| `info` | Prints current server info |
| `ping` | Pings the server for latency check |

### ◆ Console Commands (Singleplayer/Local Only)

**[!!] ▲ IMPORTANT**: These commands do NOT work on dedicated servers

To enable cheat commands in singleplayer:
1. Press F5 to open console
2. Type `devcommands` and press Enter
3. Type `devcommands` again to disable

**Common Cheat Commands:**
- `god` - Toggle god mode (invulnerability)
- `ghost` - Toggle ghost mode (enemies ignore you)
- `killall` - Kill all nearby enemies
- `tame` - Tame all nearby creatures
- `exploremap` - Reveal entire map
- `resetmap` - Hide entire map
- `playerlist` - List all players with IDs
- `freefly` - Toggle free camera mode
- `ffsmooth` - Smooth free camera mode
- `location` - Set new spawn location
- `raiseskill <skill> <level>` - Increase skill level
- `resetskill <skill>` - Reset skill to level 0
- `heal` - Heal to full health
- `puke` - Clear food buffs
- `hair` - Remove hair
- `beard` - Remove beard
- `dpsdebug` - Toggle DPS debug output

**Item Spawning (Singleplayer):**
- `spawn <item> <quantity> <level>` - Spawn items
- Example: `spawn Wood 50` - Spawns 50 wood
- Example: `spawn SwordIron 1 3` - Spawns level 3 iron sword

### ◆ Important Limitations

**[XX] ✗ Dedicated Server Restrictions**
- No remote console/RCON support
- Admin commands must be executed in-game
- `devcommands` and cheats do NOT work on dedicated servers
- Only basic admin commands (kick, ban, etc.) available

**[!!] ▲ Console Access Requirements**
- Steam: Right-click Valheim → Properties → Launch Options → Add `-console`
- Must restart game after adding launch option
- Press F5 in-game to open console
- Admin status required for server commands

**[..] ◦ Alternative Management Options**
```bash
# Enable Supervisor web interface (requires container restart)
./scripts/send_admin_command.sh enable-supervisor

# Server-side operations
./scripts/send_admin_command.sh command restart
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