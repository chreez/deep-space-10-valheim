#!/bin/bash
set -e

echo "╔══════════════════════════════════════════════╗"
echo "║     deep.space.10 Development File Sync      ║"
echo "╚══════════════════════════════════════════════╝"

# Configuration
REMOTE_HOST="windows-host"
REMOTE_USER="steam"
WORKSPACE_DIR="/mnt/c/deep.space.10"
LOCAL_SRC="./src"

# Options
DRY_RUN=${1:-false}
DIRECTION=${2:-"to-remote"}  # to-remote or from-remote

if [ "$DRY_RUN" = "--dry-run" ] || [ "$DRY_RUN" = "-n" ]; then
    RSYNC_OPTIONS="-avz --dry-run"
    echo "DRY RUN MODE - No files will be modified"
else
    RSYNC_OPTIONS="-avz --progress"
fi

# Exclusions
EXCLUDE_OPTIONS="--exclude='node_modules' --exclude='.git' --exclude='*.log' --exclude='__pycache__' --exclude='*.pyc'"

case "$DIRECTION" in
    "to-remote")
        echo "Syncing local development files to remote server..."
        echo "Local: $LOCAL_SRC/"
        echo "Remote: $REMOTE_USER@$REMOTE_HOST:$WORKSPACE_DIR/"
        echo ""
        
        eval "rsync $RSYNC_OPTIONS $EXCLUDE_OPTIONS $LOCAL_SRC/ $REMOTE_USER@$REMOTE_HOST:$WORKSPACE_DIR/"
        
        if [ "$DRY_RUN" != "--dry-run" ] && [ "$DRY_RUN" != "-n" ]; then
            echo ""
            echo "✓ Files synced to remote server"
            echo "Next steps:"
            echo "  1. Restart server: ssh $REMOTE_USER@$REMOTE_HOST 'cd $WORKSPACE_DIR/server && ./stop_server.bat && ./start_server.bat'"
            echo "  2. Check health: python3 scripts/health_check.py"
        fi
        ;;
        
    "from-remote")
        echo "Syncing remote files to local development environment..."
        echo "Remote: $REMOTE_USER@$REMOTE_HOST:$WORKSPACE_DIR/"
        echo "Local: $LOCAL_SRC/"
        echo ""
        
        eval "rsync $RSYNC_OPTIONS $EXCLUDE_OPTIONS $REMOTE_USER@$REMOTE_HOST:$WORKSPACE_DIR/ $LOCAL_SRC/"
        
        if [ "$DRY_RUN" != "--dry-run" ] && [ "$DRY_RUN" != "-n" ]; then
            echo ""
            echo "✓ Files synced from remote server"
            echo "Review changes and commit if needed"
        fi
        ;;
        
    *)
        echo "Error: Invalid direction '$DIRECTION'"
        echo "Usage: $0 [--dry-run] [to-remote|from-remote]"
        exit 1
        ;;
esac