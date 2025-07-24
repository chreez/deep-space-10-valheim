#!/bin/bash

echo "╔══════════════════════════════════════════════╗"
echo "║     Valheim Server Admin Command Tool        ║"
echo "╚══════════════════════════════════════════════╝"

# Configuration
REMOTE_HOST="192.168.1.236"
REMOTE_USER="chris"
WORKSPACE_DIR="/mnt/e/deep.space.10"
SSH_CMD="$HOME/.dotfiles/bin/ssh_windows_wsl"
CONTAINER_NAME="valheim-server"

# Function to check admin list
check_admin_list() {
    echo ""
    echo "▪ CURRENT ADMIN LIST"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    ADMIN_LIST=$($SSH_CMD --command "docker exec $CONTAINER_NAME cat /config/adminlist.txt 2>/dev/null || echo 'File not found'")
    
    if echo "$ADMIN_LIST" | grep -q "File not found"; then
        echo "[!!] ▲ adminlist.txt not found - creating..."
        $SSH_CMD --command "docker exec $CONTAINER_NAME touch /config/adminlist.txt"
        echo "[OK] ✓ Created empty adminlist.txt"
    else
        echo "[OK] ✓ Current admins:"
        echo "$ADMIN_LIST" | sed 's/^/    /'
    fi
}

# Function to add admin
add_admin() {
    local STEAM_ID=$1
    
    if [ -z "$STEAM_ID" ]; then
        echo "[XX] ✗ Please provide a Steam ID"
        echo "▸ Usage: $0 add-admin <steam_id>"
        return 1
    fi
    
    echo ""
    echo "▪ ADDING ADMIN"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "[..] ◦ Adding Steam ID: $STEAM_ID"
    
    # Add to adminlist.txt
    $SSH_CMD --command "docker exec $CONTAINER_NAME sh -c 'echo $STEAM_ID >> /config/adminlist.txt'"
    
    if [ $? -eq 0 ]; then
        echo "[OK] ✓ Admin added successfully"
        echo "[!!] ▲ Admin must reconnect to server for changes to take effect"
    else
        echo "[XX] ✗ Failed to add admin"
    fi
}

# Function to execute server-side commands
server_command() {
    local CMD=$1
    
    echo ""
    echo "▪ SERVER-SIDE COMMAND EXECUTION"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "[!!] ▲ Note: Valheim doesn't support remote console commands"
    echo "[!!] ▲ Admin commands must be executed in-game using F5 console"
    echo ""
    echo "Available server-side operations:"
    echo "  - Restart server: docker restart $CONTAINER_NAME"
    echo "  - View logs: docker logs $CONTAINER_NAME"
    echo "  - Stop server: docker stop $CONTAINER_NAME"
    echo ""
    
    case "$CMD" in
        "save")
            echo "[..] ◦ Triggering world save..."
            echo "[!!] ▲ Valheim auto-saves every 30 minutes"
            echo "[!!] ▲ Manual save requires in-game admin command"
            ;;
        "restart")
            echo "[..] ◦ Restarting server..."
            $SSH_CMD --command "docker restart $CONTAINER_NAME"
            echo "[OK] ✓ Server restart initiated"
            ;;
        *)
            echo "[XX] ✗ Unknown command: $CMD"
            echo "[!!] ▲ Use in-game F5 console for admin commands like:"
            echo "      - kick <username>"
            echo "      - ban <username>"
            echo "      - save"
            echo "      - help"
            ;;
    esac
}

# Function to monitor player connections
monitor_players() {
    echo ""
    echo "▪ MONITORING PLAYER CONNECTIONS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "[..] ◦ Checking recent connections..."
    
    # Get recent logs showing player connections
    PLAYER_LOGS=$($SSH_CMD --command "docker logs --tail 100 $CONTAINER_NAME 2>&1 | grep -E 'Got connection|Got character|Closing socket' | tail -20")
    
    if [ -n "$PLAYER_LOGS" ]; then
        echo "[OK] ✓ Recent player activity:"
        echo "$PLAYER_LOGS" | sed 's/^/    /'
        
        # Extract Steam IDs
        echo ""
        echo "[..] ◦ Detected Steam IDs:"
        echo "$PLAYER_LOGS" | grep -oE 'Steam[0-9]+' | sort -u | sed 's/^/    /'
    else
        echo "[!!] ▲ No recent player connections found"
    fi
}

# Function to enable supervisor HTTP interface
enable_supervisor() {
    echo ""
    echo "▪ ENABLING SUPERVISOR HTTP INTERFACE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "[!!] ▲ This requires container restart with additional environment variables:"
    echo ""
    echo "Add to your docker run command:"
    echo "  -e SUPERVISOR_HTTP=true"
    echo "  -e SUPERVISOR_HTTP_PASS=<your_password>"
    echo "  -p 9001:9001/tcp"
    echo ""
    echo "Then access at: http://$REMOTE_HOST:9001"
    echo "Username: admin"
    echo "Password: <your_password>"
}

# Main command handling
ACTION=${1:-"help"}

case "$ACTION" in
    "list-admins")
        check_admin_list
        ;;
        
    "add-admin")
        add_admin "$2"
        ;;
        
    "monitor")
        monitor_players
        ;;
        
    "command")
        server_command "$2"
        ;;
        
    "enable-supervisor")
        enable_supervisor
        ;;
        
    "help"|"")
        echo ""
        echo "▪ AVAILABLE COMMANDS"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "  list-admins      - Show current admin list"
        echo "  add-admin <id>   - Add Steam ID to admin list"
        echo "  monitor          - Monitor player connections and get Steam IDs"
        echo "  command <cmd>    - Execute server-side command"
        echo "  enable-supervisor - Instructions to enable web interface"
        echo ""
        echo "▸ Usage: $0 [command] [args]"
        echo "▸ Example: $0 add-admin 76561198012345678"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "NOTE: Valheim admin commands must be executed in-game:"
        echo "  1. Add your Steam ID to admin list"
        echo "  2. Start Valheim with -console flag"
        echo "  3. Press F5 in-game to open console"
        echo "  4. Type commands like: kick, ban, save, help"
        ;;
        
    *)
        echo "[XX] ✗ Unknown command: '$ACTION'"
        echo "▸ Use '$0 help' to see available commands"
        exit 1
        ;;
esac

echo ""
echo "[ TRANSMISSION END ]"