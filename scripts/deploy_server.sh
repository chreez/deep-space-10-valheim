#!/bin/bash
set -e

echo "╔══════════════════════════════════════════════╗"
echo "║       deep.space.10 Server Deployer          ║"
echo "╚══════════════════════════════════════════════╝"

# Configuration
REMOTE_HOST="windows-host"
REMOTE_USER="steam"
WORKSPACE_DIR="/mnt/c/deep.space.10"
LOCAL_SRC="./src"

echo "[..] ◦ Deploying server files..."
rsync -avz --progress "$LOCAL_SRC/server/" "$REMOTE_USER@$REMOTE_HOST:$WORKSPACE_DIR/server/"

echo "[..] ◦ Deploying server configuration..."
scp "./config/server_config.json" "$REMOTE_USER@$REMOTE_HOST:$WORKSPACE_DIR/server/"

echo "[..] ◦ Setting up BepInEx configuration..."
ssh $REMOTE_USER@$REMOTE_HOST "cd $WORKSPACE_DIR/server/BepInEx/config && echo '[Logging.Console]
Enabled = true
[Preloader.Entrypoint]
Type = MonoBehaviour
[Chainloader]
HideManagerGameObject = false' > BepInEx.cfg"

echo "[..] ◦ Making scripts executable..."
ssh $REMOTE_USER@$REMOTE_HOST "chmod +x $WORKSPACE_DIR/server/*.bat"

echo "[OK] ✓ Server deployment complete"

echo ""
echo "Server deployed to: $REMOTE_HOST:$WORKSPACE_DIR/server"
echo "Start server with: ssh $REMOTE_USER@$REMOTE_HOST 'cd $WORKSPACE_DIR/server && ./start_server.bat'"