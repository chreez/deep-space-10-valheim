#!/bin/bash

echo "╔══════════════════════════════════════════════╗"
echo "║      deep.space.10 Server Control Tool       ║"
echo "╚══════════════════════════════════════════════╝"

# Configuration
REMOTE_HOST="192.168.1.236"
REMOTE_USER="chris"
WORKSPACE_DIR="/mnt/e/deep.space.10"
SSH_CMD="$HOME/.dotfiles/bin/ssh_windows_wsl"

# Commands
ACTION=${1:-"status"}

case "$ACTION" in
    "start")
        echo "Starting Valheim server..."
        # Use the Linux server executable in WSL
        $SSH_CMD $REMOTE_USER $REMOTE_HOST "cd $WORKSPACE_DIR/server && nohup ./valheim_server.x86_64 -name 'deep.space.10' -port 2456 -world 'DeepSpace10' -password 'changeme123' -crossplay > server_output.log 2>&1 &"
        sleep 3
        echo "✓ Start command sent"
        echo "Checking status in 10 seconds..."
        sleep 10
        $0 status
        ;;
        
    "stop")
        echo "Stopping Valheim server..."
        $SSH_CMD $REMOTE_USER $REMOTE_HOST "pkill -f valheim_server.x86_64 || echo 'Server not running'"
        echo "✓ Stop command sent"
        sleep 3
        $0 status
        ;;
        
    "restart")
        echo "Restarting Valheim server..."
        $0 stop
        sleep 5
        $0 start
        ;;
        
    "status")
        echo "Running comprehensive status check..."
        python3 scripts/health_check.py
        ;;
        
        
    "backup")
        echo "Creating world backup..."
        ./scripts/backup_world.sh world-only
        ;;
        
    "logs")
        LOG_TYPE=${2:-"server"}
        echo "Showing $LOG_TYPE logs..."
        ./scripts/tail_logs.sh "$LOG_TYPE"
        ;;
        
    "players")
        echo "Checking player connections..."
        # This would need integration with server API or log parsing
        echo "Player count: Not implemented yet"
        echo "Recent connections:"
        $SSH_CMD $REMOTE_USER $REMOTE_HOST "grep -i 'player\|connect\|disconnect' $WORKSPACE_DIR/server/logs/output.log 2>/dev/null | tail -5 || echo 'No connection logs found'"
        ;;
        
    "update")
        echo "Updating server..."
        echo "Stopping server first..."
        $0 stop
        sleep 5
        
        echo "Running SteamCMD update..."
        $SSH_CMD $REMOTE_USER $REMOTE_HOST "steamcmd +force_install_dir $WORKSPACE_DIR/server +login anonymous +app_update 896660 validate +quit"
        
        echo "Update complete. Starting server..."
        $0 start
        ;;
        
    "deploy")
        echo "Deploying latest changes..."
        python3 scripts/deploy_server.py
        ;;
        
    "menu")
        echo ""
        echo "Available commands:"
        echo "  start    - Start the server"
        echo "  stop     - Stop the server"
        echo "  restart  - Restart the server"
        echo "  status   - Check server status and health"
        echo "  backup   - Create world backup"
        echo "  logs     - View server logs"
        echo "  players  - Check player status"
        echo "  update   - Update server via SteamCMD"
        echo "  deploy   - Deploy latest changes"
        echo "  menu     - Show this menu"
        echo ""
        echo "Usage: $0 [command]"
        ;;
        
    *)
        echo "Error: Unknown command '$ACTION'"
        echo "Use '$0 menu' to see available commands"
        exit 1
        ;;
esac