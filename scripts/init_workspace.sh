#!/bin/bash
echo "╔══════════════════════════════════════════════╗"
echo "║    deep.space.10 Workspace Initializer       ║"
echo "╚══════════════════════════════════════════════╝"

# Configuration
REMOTE_HOST="windows-host"
REMOTE_USER="steam"
WORKSPACE_DIR="/mnt/c/deep.space.10"

# Steps
echo "[..] ◦ Creating remote workspace..."
ssh $REMOTE_USER@$REMOTE_HOST "mkdir -p $WORKSPACE_DIR/{server,modpack,backups,logs}"

echo "[..] ◦ Installing Valheim Dedicated Server..."
ssh $REMOTE_USER@$REMOTE_HOST "steamcmd +force_install_dir $WORKSPACE_DIR/server +login anonymous +app_update 896660 validate +quit"

echo "[..] ◦ Setting up BepInEx..."
ssh $REMOTE_USER@$REMOTE_HOST "cd $WORKSPACE_DIR && curl -L -o BepInEx.zip https://github.com/BepInEx/BepInEx/releases/download/v5.4.22/BepInEx_x64_5.4.22.0.zip"
ssh $REMOTE_USER@$REMOTE_HOST "cd $WORKSPACE_DIR && unzip -o BepInEx.zip -d server/"
ssh $REMOTE_USER@$REMOTE_HOST "cd $WORKSPACE_DIR && rm BepInEx.zip"

echo "[..] ◦ Setting up server configuration..."
ssh $REMOTE_USER@$REMOTE_HOST "cd $WORKSPACE_DIR && mkdir -p server/BepInEx/config"

echo "[..] ◦ Creating startup scripts..."
ssh $REMOTE_USER@$REMOTE_HOST "cd $WORKSPACE_DIR && mkdir -p scripts"

echo "[OK] ✓ Workspace initialized successfully"
echo ""
echo "Next steps:"
echo "1. Copy server files: ./scripts/deploy_server.sh"
echo "2. Run tests: python tests/verify_server.py"
echo "3. Start server: ssh $REMOTE_USER@$REMOTE_HOST 'cd $WORKSPACE_DIR/server && ./start_server.bat'"