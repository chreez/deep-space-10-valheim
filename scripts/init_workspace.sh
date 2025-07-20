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
# Download and extract BepInEx to server

echo "[OK] ✓ Workspace initialized"