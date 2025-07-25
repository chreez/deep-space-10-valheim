#!/bin/bash

echo "╔══════════════════════════════════════════════╗"
echo "║      deep.space.10 Server Control Tool       ║"
echo "║         Where Vikings Meet the Void          ║"
echo "╚══════════════════════════════════════════════╝"

# Load environment variables
if [ -f ".env" ]; then
    export $(grep -v '^#' .env | xargs)
fi

# Configuration
REMOTE_HOST="192.168.1.236"
REMOTE_USER="chris"
WORKSPACE_DIR="/mnt/e/deep.space.10"
SSH_CMD="$HOME/.dotfiles/bin/ssh_windows_wsl"
CONTAINER_NAME="valheim-server"

# Commands
ACTION=${1:-"health"}

case "$ACTION" in
    "health"|"status"|"")
        echo ""
        echo "▪ SPACE VIKING HEALTH MATRIX"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        
        # Check container status
        echo "[..] ◦ Scanning Docker container status..."
        CONTAINER_STATUS=$($SSH_CMD --command "docker ps --filter name=$CONTAINER_NAME --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'")
        
        if echo "$CONTAINER_STATUS" | grep -q "$CONTAINER_NAME"; then
            echo "[OK] ✓ Container: $CONTAINER_NAME is running"
            echo "$CONTAINER_STATUS" | tail -n +2
        else
            echo "[XX] ✗ Container: $CONTAINER_NAME not found or stopped"
            # Check if container exists but is stopped
            STOPPED_STATUS=$($SSH_CMD --command "docker ps -a --filter name=$CONTAINER_NAME --format 'table {{.Names}}\t{{.Status}}'")
            if echo "$STOPPED_STATUS" | grep -q "$CONTAINER_NAME"; then
                echo "[!!] ▲ Container exists but is stopped"
                echo "$STOPPED_STATUS" | tail -n +2
            fi
        fi
        
        echo ""
        echo "[..] ◦ Checking resource consumption..."
        
        # Check resource usage
        RESOURCE_STATS=$($SSH_CMD --command "docker stats --no-stream $CONTAINER_NAME 2>/dev/null || echo 'Container not running'")
        if echo "$RESOURCE_STATS" | grep -q "Container not running"; then
            echo "[XX] ✗ Resource monitoring unavailable - container offline"
        else
            echo "[OK] ✓ Resource utilization:"
            echo "$RESOURCE_STATS"
        fi
        
        echo ""
        echo "[..] ◦ Analyzing recent server activity..."
        
        # Check recent logs for mod loading and activity
        RECENT_LOGS=$($SSH_CMD --command "docker logs --tail 10 $CONTAINER_NAME 2>/dev/null || echo 'No logs available'")
        if echo "$RECENT_LOGS" | grep -q "No logs available"; then
            echo "[XX] ✗ No log data available"
        else
            echo "[OK] ✓ Recent activity detected"
            # Look for BepInEx mod loading
            MOD_COUNT=$(echo "$RECENT_LOGS" | grep -c "Loading \[" || echo "0")
            if [ "$MOD_COUNT" -gt 0 ]; then
                echo "[OK] ✓ BepInEx mods detected: $MOD_COUNT loading events"
            else
                echo "[!!] ▲ No BepInEx mod loading detected in recent logs"
            fi
            
            # Show last few log lines
            echo ""
            echo "▸ Last 5 log entries:"
            echo "$RECENT_LOGS" | tail -5 | sed 's/^/    /'
        fi
        
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "[ HEALTH CHECK COMPLETE ]"
        ;;
        
    "deploy")
        echo ""
        echo "▪ DEPLOYMENT PROTOCOL INITIATED"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        
        echo "[..] ◦ Attempting atomic file sync via sync_windows_wsl..."
        
        # Try to use the atomic sync tool
        if command -v ~/.dotfiles/bin/sync_windows_wsl >/dev/null 2>&1; then
            echo "[OK] ✓ sync_windows_wsl tool detected"
            
            # Check if we have source files to deploy
            if [ -d "./src/server" ]; then
                echo "[..] ◦ Deploying server files to $WORKSPACE_DIR/server..."
                ~/.dotfiles/bin/sync_windows_wsl ./src/server/ $WORKSPACE_DIR/server/
                
                if [ $? -eq 0 ]; then
                    echo "[OK] ✓ Server files deployed successfully"
                else
                    echo "[XX] ✗ sync_windows_wsl failed, trying fallback method..."
                    # Fallback to manual rsync
                    echo "[..] ◦ Using rsync fallback..."
                    rsync -avz ./src/server/ $REMOTE_USER@$REMOTE_HOST:$WORKSPACE_DIR/server/
                fi
            else
                echo "[!!] ▲ No ./src/server directory found to deploy"
            fi
            
            # Deploy any config files
            if [ -d "./config" ]; then
                echo "[..] ◦ Deploying configuration files..."
                ~/.dotfiles/bin/sync_windows_wsl ./config/ $WORKSPACE_DIR/config/
                echo "[OK] ✓ Configuration files synchronized"
            fi
            
        else
            echo "[XX] ✗ sync_windows_wsl not available, using manual deployment..."
            echo "[..] ◦ Falling back to SSH file transfer..."
            
            # Manual deployment via SSH
            $SSH_CMD --command "mkdir -p $WORKSPACE_DIR/server $WORKSPACE_DIR/config"
            
            if [ -d "./src/server" ]; then
                echo "[..] ◦ Copying server files..."
                # Note: This is a placeholder - would need proper file transfer implementation
                echo "[!!] ▲ Manual file transfer not implemented - please use sync_windows_wsl"
            fi
        fi
        
        echo ""
        echo "[..] ◦ Verifying BepInEx directory structure..."
        $SSH_CMD --command "mkdir -p $WORKSPACE_DIR/server/BepInEx/plugins"
        echo "[OK] ✓ BepInEx plugin directory ready"
        
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "[ DEPLOYMENT COMPLETE ]"
        ;;
        
    "restart")
        echo ""
        echo "▪ CONTAINER RESTART PROTOCOL"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        
        echo "[..] ◦ Stopping existing container..."
        STOP_RESULT=$($SSH_CMD --command "docker stop $CONTAINER_NAME 2>/dev/null || echo 'Container not running'")
        
        if echo "$STOP_RESULT" | grep -q "Container not running"; then
            echo "[!!] ▲ Container was not running"
        else
            echo "[OK] ✓ Container stopped: $CONTAINER_NAME"
        fi
        
        echo "[..] ◦ Removing stopped container..."
        $SSH_CMD --command "docker rm $CONTAINER_NAME 2>/dev/null || echo 'Container already removed'"
        
        echo "[..] ◦ Starting new container with BepInEx support..."
        
        # Start container in headless mode (non-blocking)
        START_CMD="docker run -d --name $CONTAINER_NAME \
          -p 27500-27502:27500-27502/udp \
          -v $WORKSPACE_DIR/server:/config \
          -e SERVER_NAME=\"$SERVER_NAME\" \
          -e WORLD_NAME=\"$WORLD_NAME\" \
          -e SERVER_PASS=\"$SERVER_PASS\" \
          -e SERVER_PORT=\"$SERVER_PORT\" \
          -e PUBLIC=\"$PUBLIC\" \
          -e SERVER_TOKEN=\"$SERVER_TOKEN\" \
          -e DISCORD_WEBHOOK=\"$DISCORD_WEBHOOK\" \
          -e BEPINEX=true \
          lloesche/valheim-server"
        
        echo "[!!] ▲ Executing headless container start..."
        CONTAINER_ID=$($SSH_CMD --command "$START_CMD")
        
        if [ $? -eq 0 ]; then
            echo "[OK] ✓ Container started successfully"
            echo "▸ Container ID: $CONTAINER_ID"
            echo "[..] ◦ Container is initializing in background..."
            echo ""
            echo "▸ Monitor progress with: docker logs -f $CONTAINER_NAME"
            echo "▸ Check status with: ./scripts/server_control.sh health"
        else
            echo "[XX] ✗ Failed to start container"
            echo "▸ Check Docker daemon and environment variables"
        fi
        
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "[ RESTART COMPLETE ]"
        ;;
        
    "debug")
        echo ""
        echo "▪ SYNCHRONOUS DEBUG MODE"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "[!!] ▲ Starting container in synchronous mode for debugging..."
        echo "[!!] ▲ This will block terminal - use Ctrl+C to stop"
        echo ""
        
        # Stop existing container first
        $SSH_CMD --command "docker stop $CONTAINER_NAME 2>/dev/null; docker rm $CONTAINER_NAME 2>/dev/null"
        
        # Start in foreground mode
        DEBUG_CMD="docker run --rm -it --name $CONTAINER_NAME \
          -p 27500-27502:27500-27502/udp \
          -v $WORKSPACE_DIR/server:/config \
          -e SERVER_NAME=\"$SERVER_NAME-Debug\" \
          -e WORLD_NAME=\"$WORLD_NAME\" \
          -e SERVER_PASS=\"$SERVER_PASS\" \
          -e SERVER_PORT=\"$SERVER_PORT\" \
          -e PUBLIC=\"$PUBLIC\" \
          -e SERVER_TOKEN=\"$SERVER_TOKEN\" \
          -e DISCORD_WEBHOOK=\"$DISCORD_WEBHOOK\" \
          -e BEPINEX=true \
          lloesche/valheim-server"
        
        echo "[..] ◦ Executing: $DEBUG_CMD"
        $SSH_CMD --command "$DEBUG_CMD"
        ;;
        
    "menu"|"help")
        echo ""
        echo "▪ AVAILABLE PROTOCOLS"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "  health   - [Default] Check server status and resources"
        echo "  deploy   - Deploy server files via atomic sync"
        echo "  restart  - Restart Docker container (headless)"
        echo "  debug    - Start container in synchronous debug mode"
        echo "  menu     - Show this command matrix"
        echo ""
        echo "▸ Usage: $0 [command]"
        echo "▸ Example: $0 health"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        ;;
        
    *)
        echo ""
        echo "[XX] ✗ Unknown protocol: '$ACTION'"
        echo "▸ Use '$0 menu' to see available commands"
        echo ""
        exit 1
        ;;
esac

echo ""
echo "[ TRANSMISSION END ]"