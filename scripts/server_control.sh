#!/bin/bash

echo "╔══════════════════════════════════════════════╗"
echo "║      deep.space.10 Server Control Tool       ║"
echo "╚══════════════════════════════════════════════╝"

# Configuration
REMOTE_HOST="windows-host"
REMOTE_USER="steam"
WORKSPACE_DIR="/mnt/c/deep.space.10"

# Commands
ACTION=${1:-"status"}

case "$ACTION" in
    "start")
        echo "Starting Valheim server..."
        ssh $REMOTE_USER@$REMOTE_HOST "cd $WORKSPACE_DIR/server && nohup ./start_server.bat > server.log 2>&1 &"
        sleep 3
        echo "✓ Start command sent"
        echo "Checking status in 10 seconds..."
        sleep 10
        $0 status
        ;;
        
    "stop")
        echo "Stopping Valheim server..."
        ssh $REMOTE_USER@$REMOTE_HOST "cd $WORKSPACE_DIR/server && ./stop_server.bat"
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
        echo "Checking server status..."
        echo ""
        
        # Check process
        if ssh $REMOTE_USER@$REMOTE_HOST "tasklist | findstr valheim_server" >/dev/null 2>&1; then
            echo "✅ Server process: RUNNING"
            
            # Get process details
            PROCESS_INFO=$(ssh $REMOTE_USER@$REMOTE_HOST "tasklist | findstr valheim_server")
            echo "   $PROCESS_INFO"
        else
            echo "❌ Server process: NOT RUNNING"
        fi
        
        # Check ports
        echo ""
        echo "Port status:"
        for port in 2456 2457 2458; do
            if ssh $REMOTE_USER@$REMOTE_HOST "netstat -an | findstr :$port | findstr LISTENING" >/dev/null 2>&1; then
                echo "   ✅ Port $port: LISTENING"
            else
                echo "   ❌ Port $port: NOT LISTENING"
            fi
        done
        
        # Check recent log activity
        echo ""
        echo "Recent log activity:"
        LAST_LOG=$(ssh $REMOTE_USER@$REMOTE_HOST "tail -1 $WORKSPACE_DIR/server/logs/output.log 2>/dev/null || echo 'No log file'")
        echo "   Last log entry: $LAST_LOG"
        ;;
        
    "health")
        echo "Running comprehensive health check..."
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
        ssh $REMOTE_USER@$REMOTE_HOST "grep -i 'player\|connect\|disconnect' $WORKSPACE_DIR/server/logs/output.log 2>/dev/null | tail -5 || echo 'No connection logs found'"
        ;;
        
    "update")
        echo "Updating server..."
        echo "Stopping server first..."
        $0 stop
        sleep 5
        
        echo "Running SteamCMD update..."
        ssh $REMOTE_USER@$REMOTE_HOST "steamcmd +force_install_dir $WORKSPACE_DIR/server +login anonymous +app_update 896660 validate +quit"
        
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
        echo "  status   - Check server status"
        echo "  health   - Run health check"
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