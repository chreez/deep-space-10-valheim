#!/bin/bash
set -e

echo "╔══════════════════════════════════════════════╗"
echo "║   deep.space.10 Continuous Health Monitor    ║"
echo "╚══════════════════════════════════════════════╝"

# Configuration
CHECK_INTERVAL=${1:-300}  # 5 minutes default
LOG_DIR="./logs"
ALERT_EMAIL=${ALERT_EMAIL:-""}
ALERT_WEBHOOK=${ALERT_WEBHOOK:-""}

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Initialize counters
check_count=0
consecutive_failures=0
start_time=$(date)

echo "Starting continuous health monitoring..."
echo "Check interval: ${CHECK_INTERVAL} seconds"
echo "Start time: $start_time"
echo "Logs directory: $LOG_DIR"
echo ""

# Function to send alert
send_alert() {
    local message="$1"
    local severity="$2"
    
    echo "[$(date)] ALERT [$severity]: $message"
    
    # Log to file
    echo "[$(date)] ALERT [$severity]: $message" >> "$LOG_DIR/alerts.log"
    
    # Send email if configured
    if [ -n "$ALERT_EMAIL" ]; then
        echo "$message" | mail -s "deep.space.10 Alert: $severity" "$ALERT_EMAIL" 2>/dev/null || echo "Failed to send email alert"
    fi
    
    # Send webhook if configured
    if [ -n "$ALERT_WEBHOOK" ]; then
        curl -X POST "$ALERT_WEBHOOK" \
            -H "Content-Type: application/json" \
            -d "{\"text\":\"deep.space.10 Alert: $message\"}" \
            2>/dev/null || echo "Failed to send webhook alert"
    fi
}

# Function to check server health
check_health() {
    local timestamp=$(date)
    local log_file="$LOG_DIR/monitor_$(date +%Y%m%d).log"
    
    echo "[$(date)] Running health check #$((++check_count))..." | tee -a "$log_file"
    
    # Run health check
    if python3 scripts/health_check.py > "$LOG_DIR/latest_health.txt" 2>&1; then
        echo "[$(date)] ✓ Health check passed" | tee -a "$log_file"
        consecutive_failures=0
        
        # Display summary
        if [ $((check_count % 12)) -eq 0 ]; then  # Every hour with 5-min intervals
            echo ""
            echo "=== Hourly Summary ==="
            echo "Checks completed: $check_count"
            echo "Runtime: $(( ($(date +%s) - $(date -d "$start_time" +%s)) / 60 )) minutes"
            echo "Last check: $(date)"
            echo "======================"
            echo ""
        fi
        
        return 0
    else
        echo "[$(date)] ✗ Health check failed" | tee -a "$log_file"
        consecutive_failures=$((consecutive_failures + 1))
        
        # Send alerts based on failure count
        if [ $consecutive_failures -eq 1 ]; then
            send_alert "Server health check failed (attempt 1)" "WARNING"
        elif [ $consecutive_failures -eq 3 ]; then
            send_alert "Server health check failed 3 times consecutively" "CRITICAL"
        elif [ $consecutive_failures -eq 10 ]; then
            send_alert "Server health check failed 10 times - server may be down" "CRITICAL"
        fi
        
        # Show recent failure info
        echo "Consecutive failures: $consecutive_failures"
        if [ -f "$LOG_DIR/latest_health.txt" ]; then
            echo "Last error output:"
            tail -10 "$LOG_DIR/latest_health.txt" | sed 's/^/  /'
        fi
        
        return 1
    fi
}

# Function to handle shutdown
cleanup() {
    echo ""
    echo "Stopping health monitor..."
    echo "Final statistics:"
    echo "  Total checks: $check_count"
    echo "  Runtime: $(( ($(date +%s) - $(date -d "$start_time" +%s)) / 60 )) minutes"
    echo "  Consecutive failures at exit: $consecutive_failures"
    exit 0
}

# Set up signal handlers
trap cleanup SIGINT SIGTERM

# Main monitoring loop
echo "Health monitor active. Press Ctrl+C to stop."
echo ""

while true; do
    check_health
    
    # Sleep with interruptible wait
    sleep "$CHECK_INTERVAL" &
    wait $!
done