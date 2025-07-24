#!/bin/bash

echo "╔══════════════════════════════════════════════╗"
echo "║     Chat Logger Mod Installation Tool        ║"
echo "║         ServerDevcommands Setup              ║"
echo "╚══════════════════════════════════════════════╝"

# Configuration
REMOTE_HOST="192.168.1.236"
REMOTE_USER="chris"
WORKSPACE_DIR="/mnt/e/deep.space.10"
SSH_CMD="$HOME/.dotfiles/bin/ssh_windows_wsl"
CONTAINER_NAME="valheim-server"

echo ""
echo "▪ CHAT LOGGING MOD INSTALLATION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "[!!] ▲ ServerDevcommands enables chat logging and admin commands"
echo ""

echo "MANUAL INSTALLATION STEPS:"
echo ""
echo "1. Download ServerDevcommands from Thunderstore:"
echo "   https://thunderstore.io/c/valheim/p/JereKuusela/Server_devcommands/"
echo ""
echo "2. Extract the zip file to get:"
echo "   - ServerDevcommands.dll"
echo "   - README.md"
echo "   - manifest.json"
echo ""
echo "3. Copy ServerDevcommands.dll to server:"
echo "   ~/.dotfiles/bin/sync_windows_wsl ./ServerDevcommands.dll $WORKSPACE_DIR/server/BepInEx/plugins/"
echo ""
echo "4. Create config file on server:"
$SSH_CMD --command "cat > $WORKSPACE_DIR/server/BepInEx/config/server_devcommands.cfg << 'EOF'
## Settings file for Server devcommands

[General]

## Enables devcommands
# Setting type: Boolean
# Default value: true
Enabled = true

## Enables server chat for admins
# Setting type: Boolean
# Default value: true
Server chat = true

## Adds a dummy client to the server for chat messages
# Setting type: Boolean
# Default value: true
Server client = true

## Logs all chat messages to console
# Setting type: Boolean
# Default value: true
Log chat = true

## Chat command prefix
# Setting type: String
# Default value: !
Command prefix = !

EOF"

echo ""
echo "5. Add your Steam ID to adminlist.txt:"
echo "   Your Steam ID: 76561197962507535"
$SSH_CMD --command "echo '76561197962507535' >> $WORKSPACE_DIR/server/adminlist.txt"

echo ""
echo "6. Restart the server:"
echo "   ./scripts/server_control.sh restart"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "AFTER INSTALLATION:"
echo ""
echo "▪ Chat Logging:"
echo "  - All chat messages will appear in docker logs"
echo "  - Format: [Chat] PlayerName: message"
echo ""
echo "▪ Admin Commands in Chat:"
echo "  - Use ! prefix for commands"
echo "  - Example: !help"
echo "  - Example: !spawn Wood 50"
echo ""
echo "▪ Monitor Chat:"
echo "  docker logs -f $CONTAINER_NAME | grep -E '\\[Chat\\]|Say:'"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "[ INSTALLATION GUIDE COMPLETE ]"