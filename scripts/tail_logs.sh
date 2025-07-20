#!/bin/bash

echo "╔══════════════════════════════════════════════╗"
echo "║       deep.space.10 Log Viewer Tool          ║"
echo "╚══════════════════════════════════════════════╝"

# Configuration
REMOTE_HOST="windows-host"
REMOTE_USER="steam"
WORKSPACE_DIR="/mnt/c/deep.space.10"

# Options
LOG_TYPE=${1:-"server"}  # server, bepinex, or error
LINES=${2:-50}           # number of lines to show

case "$LOG_TYPE" in
    "server")
        echo "Viewing server output logs..."
        LOG_PATH="$WORKSPACE_DIR/server/logs/output.log"
        ;;
        
    "bepinex")
        echo "Viewing BepInEx logs..."
        LOG_PATH="$WORKSPACE_DIR/server/BepInEx/LogOutput.log"
        ;;
        
    "error")
        echo "Viewing error logs..."
        LOG_PATH="$WORKSPACE_DIR/server/logs/error.log"
        ;;
        
    "all")
        echo "Viewing all available logs..."
        echo ""
        echo "=== Server Output Log ==="
        ssh $REMOTE_USER@$REMOTE_HOST "tail -$LINES $WORKSPACE_DIR/server/logs/output.log 2>/dev/null || echo 'No server output log found'"
        echo ""
        echo "=== BepInEx Log ==="
        ssh $REMOTE_USER@$REMOTE_HOST "tail -$LINES $WORKSPACE_DIR/server/BepInEx/LogOutput.log 2>/dev/null || echo 'No BepInEx log found'"
        echo ""
        echo "=== Error Log ==="
        ssh $REMOTE_USER@$REMOTE_HOST "tail -$LINES $WORKSPACE_DIR/server/logs/error.log 2>/dev/null || echo 'No error log found'"
        exit 0
        ;;
        
    "list")
        echo "Available log files:"
        ssh $REMOTE_USER@$REMOTE_HOST "find $WORKSPACE_DIR -name '*.log' -type f -exec ls -lh {} \;" 2>/dev/null || echo "Could not list log files"
        exit 0
        ;;
        
    *)
        echo "Error: Invalid log type '$LOG_TYPE'"
        echo "Usage: $0 [server|bepinex|error|all|list] [lines]"
        echo ""
        echo "Log types:"
        echo "  server   - Server output and console logs"
        echo "  bepinex  - BepInEx mod framework logs"
        echo "  error    - Error and crash logs"
        echo "  all      - Show all log types"
        echo "  list     - List available log files"
        exit 1
        ;;
esac

# Check if log file exists and show it
if ssh $REMOTE_USER@$REMOTE_HOST "test -f $LOG_PATH"; then
    echo "Showing last $LINES lines of: $LOG_PATH"
    echo "Press Ctrl+C to stop following..."
    echo ""
    echo "$(ssh $REMOTE_USER@$REMOTE_HOST "wc -l $LOG_PATH") total lines"
    echo "───────────────────────────────────────────────────"
    
    # Follow log in real-time
    ssh $REMOTE_USER@$REMOTE_HOST "tail -f -n $LINES $LOG_PATH"
else
    echo "Log file not found: $LOG_PATH"
    echo ""
    echo "Available log files:"
    ssh $REMOTE_USER@$REMOTE_HOST "find $WORKSPACE_DIR -name '*.log' -type f 2>/dev/null | head -10" || echo "No log files found"
fi