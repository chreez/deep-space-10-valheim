#!/bin/bash

echo "╔══════════════════════════════════════════════╗"
echo "║      deep.space.10 Mod Verification Tool     ║"
echo "║         Where Vikings Meet the Void          ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

REMOTE_HOST="192.168.1.236"
REMOTE_USER="chris"
SSH_CMD="$HOME/.dotfiles/bin/ssh_windows_wsl"
CONTAINER_NAME="valheim-server"
WORKSPACE_DIR="/mnt/e/deep.space.10"

# Check if specific mod should be excluded
EXCLUDE_MOD=${1:-""}

echo "▪ MOD VERIFICATION PROTOCOL"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Count mods in persistent directory
echo "[..] ◦ Scanning persistent mod directory..."
MOD_COUNT=$($SSH_CMD --command "ls $WORKSPACE_DIR/server/BepInEx/plugins/ | wc -l")
echo "[OK] ✓ Found $MOD_COUNT mod directories in persistent storage"

# Check if container is running and get BepInEx loading info
echo ""
echo "[..] ◦ Checking BepInEx mod loading status..."
CONTAINER_STATUS=$($SSH_CMD --command "docker ps --filter name=$CONTAINER_NAME --format '{{.Names}}'")

if echo "$CONTAINER_STATUS" | grep -q "$CONTAINER_NAME"; then
    echo "[OK] ✓ Container is running"
    
    # Get loaded mod count from logs
    LOADED_COUNT=$($SSH_CMD --command "docker logs $CONTAINER_NAME | grep -c 'Loading \\[' || echo '0'")
    echo "[OK] ✓ BepInEx loaded $LOADED_COUNT mods"
    
    # Check for specific mod exclusion
    if [ -n "$EXCLUDE_MOD" ]; then
        echo ""
        echo "[..] ◦ Checking exclusion of mod: $EXCLUDE_MOD"
        
        # Check file system
        FILE_CHECK=$($SSH_CMD --command "find $WORKSPACE_DIR/server/BepInEx/plugins/ -iname '*$EXCLUDE_MOD*' | wc -l" | tail -1)
        if [ "$FILE_CHECK" -eq 0 ] 2>/dev/null; then
            echo "[OK] ✓ $EXCLUDE_MOD not found in file system"
        else
            echo "[XX] ✗ $EXCLUDE_MOD files found in file system (count: $FILE_CHECK)"
        fi
        
        # Check loading logs
        LOG_CHECK=$($SSH_CMD --command "docker logs $CONTAINER_NAME | grep -ic '$EXCLUDE_MOD' || echo '0'" | tail -1)
        if [ "$LOG_CHECK" -eq 0 ] 2>/dev/null; then
            echo "[OK] ✓ $EXCLUDE_MOD not found in loading logs"
        else
            echo "[XX] ✗ $EXCLUDE_MOD found in loading logs (count: $LOG_CHECK)"
        fi
    fi
    
    # Show recently loaded mods
    echo ""
    echo "▸ Recently loaded mods (last 10):"
    $SSH_CMD --command "docker logs $CONTAINER_NAME | grep 'Loading \\[' | tail -10 | sed 's/^/    /'"
    
else
    echo "[XX] ✗ Container not running - cannot verify active mod loading"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "[ VERIFICATION COMPLETE ]"
echo ""
echo "▸ Usage: $0 [mod_name_to_exclude]"
echo "▸ Example: $0 ZenUI"
echo ""
echo "[ TRANSMISSION END ]"