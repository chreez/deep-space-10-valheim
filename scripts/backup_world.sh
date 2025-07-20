#!/bin/bash
set -e

echo "╔══════════════════════════════════════════════╗"
echo "║       deep.space.10 World Backup Tool        ║"
echo "╚══════════════════════════════════════════════╝"

# Configuration
REMOTE_HOST="windows-host"
REMOTE_USER="steam"
WORKSPACE_DIR="/mnt/c/deep.space.10"
BACKUP_DIR="$WORKSPACE_DIR/backups"
LOCAL_BACKUP_DIR="./backups"

# Options
BACKUP_TYPE=${1:-"full"}  # full, world-only, or configs-only
DOWNLOAD=${2:-false}      # --download to also download locally

TIMESTAMP=$(date +%Y%m%d_%H%M%S)

case "$BACKUP_TYPE" in
    "full")
        echo "Creating full server backup..."
        BACKUP_NAME="full_backup_$TIMESTAMP"
        BACKUP_PATH="$BACKUP_DIR/$BACKUP_NAME.tar.gz"
        
        ssh $REMOTE_USER@$REMOTE_HOST "cd $WORKSPACE_DIR && mkdir -p backups"
        ssh $REMOTE_USER@$REMOTE_HOST "cd $WORKSPACE_DIR && tar -czf $BACKUP_PATH --exclude='backups' --exclude='logs/*.log' ."
        ;;
        
    "world-only")
        echo "Creating world-only backup..."
        BACKUP_NAME="world_backup_$TIMESTAMP"
        BACKUP_PATH="$BACKUP_DIR/$BACKUP_NAME.tar.gz"
        
        ssh $REMOTE_USER@$REMOTE_HOST "cd $WORKSPACE_DIR && mkdir -p backups"
        ssh $REMOTE_USER@$REMOTE_HOST "cd $WORKSPACE_DIR && tar -czf $BACKUP_PATH server/worlds/"
        ;;
        
    "configs-only")
        echo "Creating config-only backup..."
        BACKUP_NAME="config_backup_$TIMESTAMP"
        BACKUP_PATH="$BACKUP_DIR/$BACKUP_NAME.tar.gz"
        
        ssh $REMOTE_USER@$REMOTE_HOST "cd $WORKSPACE_DIR && mkdir -p backups"
        ssh $REMOTE_USER@$REMOTE_HOST "cd $WORKSPACE_DIR && tar -czf $BACKUP_PATH server/BepInEx/config/ server/*.json server/*.cfg"
        ;;
        
    *)
        echo "Error: Invalid backup type '$BACKUP_TYPE'"
        echo "Usage: $0 [full|world-only|configs-only] [--download]"
        exit 1
        ;;
esac

# Verify backup was created
BACKUP_SIZE=$(ssh $REMOTE_USER@$REMOTE_HOST "ls -lh $BACKUP_PATH | awk '{print \$5}'")
echo "✓ Backup created: $BACKUP_NAME.tar.gz ($BACKUP_SIZE)"

# Download backup locally if requested
if [ "$DOWNLOAD" = "--download" ]; then
    echo "Downloading backup to local machine..."
    mkdir -p "$LOCAL_BACKUP_DIR"
    scp "$REMOTE_USER@$REMOTE_HOST:$BACKUP_PATH" "$LOCAL_BACKUP_DIR/"
    echo "✓ Backup downloaded to: $LOCAL_BACKUP_DIR/$BACKUP_NAME.tar.gz"
fi

# Show backup info
echo ""
echo "Backup Information:"
echo "  Type: $BACKUP_TYPE"
echo "  Remote path: $BACKUP_PATH"
echo "  Size: $BACKUP_SIZE"
echo "  Timestamp: $TIMESTAMP"

# List recent backups
echo ""
echo "Recent backups on remote server:"
ssh $REMOTE_USER@$REMOTE_HOST "ls -lht $BACKUP_DIR/ | head -6"

# Cleanup old backups (keep last 10)
echo ""
echo "Cleaning up old backups (keeping 10 most recent)..."
ssh $REMOTE_USER@$REMOTE_HOST "cd $BACKUP_DIR && ls -t *.tar.gz | tail -n +11 | xargs rm -f"

echo ""
echo "✓ Backup process completed successfully"