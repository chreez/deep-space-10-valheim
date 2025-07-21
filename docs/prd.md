# deep.space.10 – System Architecture & Vision

## 🎯 Mission
Create a simple, foolproof Valheim modpack distribution system that doesn't require mod managers or accounts.

## 🏗️ Architecture

### Core Components
```
[User Downloads ZIP] → [Extracts to Folder] → [Runs install.cmd] → [Plays Modded Valheim]
                                                        ↓
                                            [Manual Copy Alternative]
```

### File Flow
```
Source (Modpack)                    →    Destination (Valheim)
/mods/plugins/deep.space.10/*.dll   →    /BepInEx/plugins/deep.space.10/
/mods/config/*.cfg                  →    /BepInEx/config/ (if not exists)
```

## 📦 Package Contents

### Essential Files
- **README.md** - Clear instructions with screenshots
- **install.cmd** - Automated installation script
- **manifest.json** - Mod list and versions
- **/mods/** - Actual mod files

### Optional Additions
- **uninstall.cmd** - Clean removal script
- **BepInEx installer** - For zero-dependency setup
- **verify.cmd** - Check installation integrity

### Adding New Mods to the Package
To include additional mods in the distribution:

1. **Download the mod** from Thunderstore or other sources
2. **Extract mod files** to examine structure
3. **Place DLL files** in `/mods/plugins/deep.space.10/`
4. **Copy config files** to `/mods/config/` (if any)
5. **Update manifest.json** with mod name and version
6. **Test installation** on clean Valheim setup
7. **Document any special requirements** in README

Example structure for adding a mod:
```
mods/
├── plugins/
│   └── deep.space.10/
│       ├── ExistingMod.dll
│       └── NewMod.dll        ← Add here
└── config/
    ├── ExistingMod.cfg
    └── NewMod.cfg            ← Add config here
```

## 🛡️ Safety Principles

1. **Never Destructive**
   - No overwrites of existing configs
   - No deletions from game folders
   - All mods in isolated subfolder

2. **Clear Communication**
   - Progress messages during install
   - Error messages that make sense
   - Success confirmation

3. **Reversible**
   - Can manually delete deep.space.10 folder
   - Original game remains untouched
   - Configs preserved

## 🔧 Technical Decisions

### Why Manual Distribution?
- No account requirements
- No external dependencies  
- Full user control
- Works offline
- Simple to understand

### Why BepInEx?
- Industry standard for Unity mods
- Clean plugin architecture
- Config file management
- Stable and maintained

### Why Subfolder Isolation?
- Prevents mod conflicts
- Easy identification
- Simple removal
- Clear ownership

## 📐 Implementation Phases

### Phase 1: Core (Current)
- Basic file copying
- Essential safety checks
- Minimal viable package

### Phase 2: Enhancement
- Better error handling
- Installation verification
- Config management

### Phase 3: Polish
- Update detection
- Backup systems
- Advanced features

## 🎮 User Journey

### First Time User
1. Downloads deep.space.10-modpack.zip
2. Extracts to Downloads folder
3. Reads README.md
4. Runs install.cmd
5. Launches Valheim
6. Joins deep.space.10 server

### Returning User (Update)
1. Downloads new version
2. Runs install.cmd
3. Configs preserved
4. New mods added
5. Continues playing

## 💭 Design Philosophy

**"It should just work"**
- Assume nothing about user technical level
- Make the happy path obvious
- Fail gracefully with helpful messages
- Respect user's existing setup

## 🚀 Success Metrics

- Install works on first try for 90%+ users
- No game-breaking conflicts
- Clear troubleshooting path
- Users can explain it to friends

## 🧪 Testing Requirements

### Pre-Release Testing
1. **Clean Install Test**
   - Fresh Windows user account
   - Valheim with no mods
   - Follow installation instructions exactly
   - Verify all mods load correctly

2. **Upgrade Test**
   - Existing BepInEx installation
   - Some mods already installed
   - Run installer and verify no conflicts
   - Confirm configs preserved

3. **Compatibility Test**
   - Test with current Valheim version
   - Verify all mods work together
   - Check for console errors
   - Test basic gameplay features

4. **Server Connection Test**
   - Client connects to server successfully
   - All mods sync properly
   - No version mismatch errors
   - Stable gameplay for 30+ minutes

### Test Checklist
- [ ] Installation completes without errors
- [ ] All DLLs load in BepInEx console
- [ ] No missing dependency errors
- [ ] Game launches to main menu
- [ ] Can create/load single player world
- [ ] Can connect to deep.space.10 server
- [ ] No major performance issues
- [ ] Uninstall removes only modpack files

### Performance Benchmarks
- Load time: < 2 minutes with all mods
- FPS impact: < 10% reduction
- RAM usage: < 500MB additional
- No memory leaks after 2 hours

## 🖥️ Server Setup & Management

### Server Requirements
- Windows host with WSL2 enabled
- Docker installed (Windows or WSL2)
- 4GB+ RAM available for container
- Port forwarding: 2456-2458 UDP
- E: drive or equivalent for persistent storage

### Docker-First Server Installation
The server runs in a containerized environment for reliability and isolation:

1. **Environment Configuration**
   - Create `.env` file with server credentials (git-ignored)
   - Configure persistent storage paths
   - Set Steam Game Server Login Token (GSLT)

2. **Docker Container Deployment**
   ```bash
   # Load environment variables
   source .env
   
   # Run server container with BepInEx mod support
   docker run -d --name valheim-server \
     -p 2456-2458:2456-2458/udp \
     -v /mnt/e/deep.space.10/server:/config \
     -e SERVER_NAME="${SERVER_NAME}" \
     -e WORLD_NAME="${WORLD_NAME}" \
     -e SERVER_PASS="${SERVER_PASS}" \
     -e PUBLIC="${PUBLIC}" \
     -e SERVER_TOKEN="${SERVER_TOKEN}" \
     -e BEPINEX=true \
     lloesche/valheim-server
   ```

3. **Server Management Commands**
   ```bash
   # Check server status
   docker ps
   docker logs -f valheim-server
   
   # Stop/restart server
   docker stop valheim-server
   docker start valheim-server
   
   # Update server
   docker pull lloesche/valheim-server
   docker stop valheim-server && docker rm valheim-server
   # Re-run docker run command above
   ```

### Server Launch Script (Docker-Based)
```bash
#!/bin/bash
echo "╔══════════════════════════════════════════════╗"
echo "║    deep.space.10 Docker Server Launcher     ║"
echo "╚══════════════════════════════════════════════╝"
echo
echo "[..] Starting containerized Valheim Server..."
echo "[!!] ▲ Server Name: ${SERVER_NAME}"
echo "[!!] ▲ Port: ${SERVER_PORT}"
echo "[!!] ▲ World: ${WORLD_NAME}"
echo

# Load environment variables
source .env

# Start container with BepInEx support
docker run -d --name "${CONTAINER_NAME}" \
  -p "${PORT_RANGE}:${PORT_RANGE}/udp" \
  -v "${SERVER_DATA_PATH}:/config" \
  -e SERVER_NAME="${SERVER_NAME}" \
  -e WORLD_NAME="${WORLD_NAME}" \
  -e SERVER_PASS="${SERVER_PASS}" \
  -e PUBLIC="${PUBLIC}" \
  -e SERVER_TOKEN="${SERVER_TOKEN}" \
  -e BEPINEX=true \
  "${DOCKER_IMAGE}"

echo "[OK] ✓ Server container started"
echo "[..] ◦ Use 'docker logs -f ${CONTAINER_NAME}' to monitor"
```

### Mod Installation & Management

#### Directory Structure for Server Mods
```
/mnt/e/deep.space.10/server
├── BepInEx
│   └── plugins
│       └── <modname>
```

#### Installing Mods via Command Line
```bash
# Navigate to plugins directory
cd /mnt/e/deep.space.10/server/BepInEx/plugins

# Download mod from Thunderstore (example: AzuClock)
curl -L -o AzuClock.zip "https://thunderstore.io/package/download/Azumatt/AzuClock/1.0.5/"
unzip AzuClock.zip
rm AzuClock.zip

# Verify mod loading in server logs
docker logs valheim-server | grep "Loading \["
# Expected output: "[Info   :   BepInEx] Loading [AzuClock 1.0.5]"
```

### Server-Client Sync
- All clients must have matching mod versions
- Server validates client mods on connection
- Mismatched versions = connection refused
- Config sync handled by BepInEx

### Server Maintenance
- **Automated backups**: Container volumes ensure persistent data
- **Log management**: Docker handles log rotation automatically
- **Performance monitoring**: Use `docker stats valheim-server`
- **Update procedure**: Pull new image, recreate container
- **Mod updates**: Update modpack and rebuild container volume

## 🔮 Future Vision

### Immediate
- Get working prototype
- Test with real users
- Iterate based on feedback

### Long Term
- Automated mod updates
- Server-client sync verification
- Mod preset system
- Community contributions

## 📝 Notes & Ideas

- Consider using relative paths from script location
- Maybe add a "portable Valheim" option later
- Could detect Steam vs GamePass installation
- Batch file could have ASCII art banner
- Include server connection info in README

## 🎨 Branding & Style Guidelines

### Visual Identity
- ASCII art header for README and scripts
- Space + Viking theme fusion
- Technical/terminal aesthetic
- Monospace formatting for tech elements

### ASCII Banner Template
```
╔══════════════════════════════════════════════════════════════╗
║    ·  · ✦  D E E P . S P A C E . 1 0  ✦ ·  ·               ║
║         Where Vikings Meet the Void                          ║
╚══════════════════════════════════════════════════════════════╝
```

### Status Indicators
- `[OK] ✓` - Success
- `[..] ◦` - Processing
- `[!!] ▲` - Warning
- `[XX] ✗` - Error

### Typography Conventions
- Headers: `## ▪ SECTION NAME`
- Dividers: `━━━━━━━━━━━━━━━━━━━━━`
- Lists: `◆` for bullets
- Instructions: `▸` for steps

### Voice & Tone
- Technical briefing style
- Mix space and Viking terminology
- Clear, concise instructions
- "Space Viking" as user reference

### File Naming Conventions
- Package: `deep.space.10-modpack-v{version}.zip`
- Scripts: lowercase with `.cmd` extension
- Documentation: UPPERCASE.md (README.md, CHANGELOG.md)
- Folders: lowercase, no spaces

### Script Output Style
```batch
echo ╔══════════════════════════════════════════════╗
echo ║    deep.space.10 Modpack Installer v1.0     ║
echo ╚══════════════════════════════════════════════╝
echo.
echo [..] Initializing installation protocol...
echo [OK] ✓ BepInEx detected
echo [..] ◦ Copying mod files...
echo [OK] ✓ Installation complete
```

### Error Messages
- Start with `[!!] ▲ WARNING:` or `[XX] ✗ ERROR:`
- Explain what went wrong
- Provide actionable next steps
- Reference documentation section if applicable

### Documentation Structure
- Always start with ASCII banner
- Use section dividers between major topics
- Include "Space Viking" terminology naturally
- End with `[ TRANSMISSION END ]` or similar

### In-Game References
- Server name: always lowercase `deep.space.10`
- Mod folder: `deep.space.10` (no variations)
- Display name: "deep.space.10 Modpack"

### Community Communication
- Discord/Forums: Use same ASCII aesthetic
- Patch notes: Technical briefing format
- Support: Maintain helpful but technical tone

### Version Numbering
- Format: `v{major}.{minor}.{patch}`
- Example: `v1.2.0`
- Alpha/Beta: `v1.0.0-alpha.1`

### Color Palette (if needed for rich content)
- Background: Deep Space Black (#0A0A0A)
- Primary: Cosmic Blue (#1E3A8A)
- Accent: Portal Purple (#6B21A8)
- Text: Starlight White (#F9FAFB)
- Alert: Warning Orange (#EA580C)

---

*This is a living document for the deep.space.10 modpack system*