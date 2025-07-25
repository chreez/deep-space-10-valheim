# Concept 2: Server Admin Console Specification

## Overview

An interactive administrative console for Valheim server management that integrates with the "wait for server" monitoring system (Concept 1). This console provides a unified interface for server operations, combining initialization, monitoring, and administration into a cohesive workflow.

## Purpose

- **Unified Control**: Single entry point for all server administration tasks
- **Intelligent Startup**: Integrates Concept 1 script for reliable server initialization
- **Real-time Feedback**: Live status updates during operations
- **Safe Operations**: Prevents destructive actions without confirmation
- **Automation Ready**: Scriptable interface for CI/CD integration

## Success Criteria

### Core Functionality
1. **Server Lifecycle Management**: Start, stop, restart with integrated monitoring
2. **Status Visibility**: Real-time health metrics and player information
3. **Configuration Management**: Update server settings without manual file editing
4. **Backup Operations**: Create and restore world backups seamlessly
5. **Log Access**: Filtered log viewing for debugging and monitoring

### User Experience Requirements
1. **Menu-Driven Interface**: Clear numbered options for all operations
2. **Progress Feedback**: Visual indicators during long-running operations
3. **Error Recovery**: Graceful handling with actionable error messages
4. **Context Preservation**: Return to menu after operations complete
5. **Quick Actions**: Hotkeys for common tasks (R=restart, S=status, Q=quit)

## Technical Architecture

### Console Structure
```
╔══════════════════════════════════════════════╗
║      deep.space.10 Admin Console v2.0        ║
║         Server Status: [Running ✓]           ║
╚══════════════════════════════════════════════╝

[1] Start Server       [6] View Logs
[2] Stop Server        [7] Backup World
[3] Restart Server     [8] Restore Backup
[4] Server Status      [9] Update Config
[5] Player List        [0] Advanced Options

[Q] Quit  [R] Quick Restart  [S] Quick Status

Select operation:
```

### Integration with Concept 1

**Start Sequence:**
1. Execute Docker start command
2. Launch `wait_for_server.sh` in monitoring mode
3. Display progress inline: `Starting server... [Container: ✓] [BepInEx: 12/15] [Ready: ○]`
4. Return to menu on success or show error details on failure

**Restart Workflow:**
1. Confirm restart if players online
2. Send Discord notification (if configured)
3. Graceful shutdown with player warning
4. Execute start sequence with monitoring
5. Announce server ready status

### Command Implementation

#### 1. Start Server
```bash
start_server() {
    if server_running; then
        echo "Server already running"
        return
    fi
    
    echo "Starting Valheim server..."
    docker start $CONTAINER_NAME
    
    # Integrate Concept 1 monitoring
    ./scripts/wait_for_server.sh --inline
    
    if [ $? -eq 0 ]; then
        echo "✓ Server started successfully"
        send_discord_notification "Server is online"
    else
        echo "✗ Server startup failed - check logs"
    fi
}
```

#### 2. Stop Server
```bash
stop_server() {
    if ! server_running; then
        echo "Server not running"
        return
    fi
    
    player_count=$(get_player_count)
    if [ $player_count -gt 0 ]; then
        confirm_dialog "Stop server with $player_count players online?"
        [ $? -ne 0 ] && return
    fi
    
    echo "Stopping server gracefully..."
    send_rcon_command "say Server shutting down in 30 seconds"
    sleep 30
    
    docker stop --time 30 $CONTAINER_NAME
    echo "✓ Server stopped"
}
```

#### 3. Server Status Display
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SERVER STATUS REPORT
Generated: 2024-01-20 15:30:45
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Container:    ✓ Running (75c82d8082d5)
Uptime:       2 days, 14:32:15
CPU Usage:    23.4%
Memory:       2.1GB / 8.0GB (26.3%)
Disk Space:   145GB free

Network:      ✓ All ports listening
Players:      3 / 10 online
World Size:   478MB
Last Backup:  2 hours ago

Mods Loaded:  15 / 15 ✓
Discord:      ✓ Connected
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Advanced Operations Menu
```
╔══════════════════════════════════════════════╗
║         Advanced Administration Menu          ║
╚══════════════════════════════════════════════╝

[1] Update Mods          [6] Network Diagnostics
[2] Server Console       [7] Performance Tuning
[3] Ban Management       [8] Export Metrics
[4] Whitelist Control    [9] Emergency Recovery
[5] Event Scheduler      [0] Developer Tools

[B] Back to Main Menu

Select operation:
```

## Configuration Management

### Settings Interface
```yaml
# Server configuration update interface
Current Settings:
- Server Name: DeepSpace10
- Password: ******* [Hidden]
- Max Players: 10
- World Name: DeepSpace10
- Public: No

[E] Edit Setting  [R] Reset to Default  [S] Save & Apply
```

### Hot-Reload Capabilities
- Settings that require restart: Clearly marked with [R]
- Live-updatable settings: Apply without restart
- Validation: Prevent invalid configurations
- Rollback: Automatic backup before changes

## Error Handling & Recovery

### Common Error Scenarios
1. **Docker Daemon Issues**
   - Detection: Check Docker service status
   - Recovery: Suggest daemon restart steps
   - Fallback: Direct SSH commands if available

2. **Network Conflicts**
   - Detection: Port binding failures
   - Recovery: Find conflicting processes
   - Resolution: Kill or reassign ports

3. **Mod Loading Failures**
   - Detection: BepInEx error logs
   - Recovery: Disable problematic mods
   - Verification: Rerun with minimal mod set

4. **World Corruption**
   - Detection: Server crash on world load
   - Recovery: Automatic backup restore prompt
   - Prevention: Regular backup verification

### Emergency Recovery Mode
```bash
./admin_console.sh --emergency
```
- Bypasses normal startup checks
- Direct access to recovery tools
- Force stop/start capabilities
- Database repair utilities

## Performance Optimization

### Resource Monitoring
- Real-time CPU/Memory graphs
- Network bandwidth utilization
- Disk I/O patterns
- Player activity correlation

### Auto-Scaling Features
- Dynamic memory allocation based on player count
- Automatic restart scheduling during low activity
- Resource limit warnings before critical thresholds
- Performance profile switching (Low/Medium/High)

## Security Features

### Access Control
- Optional authentication for console access
- Role-based permissions (Admin/Moderator/Viewer)
- Audit logging for all administrative actions
- IP whitelist for remote administration

### Secure Operations
- Encrypted password storage
- Secure token handling for Steam/Discord
- Backup encryption options
- Network isolation settings

## Integration Points

### Discord Integration
- Server status commands
- Player notifications
- Admin alerts for issues
- Backup completion notices

### Monitoring Systems
- Prometheus metrics export
- Health check endpoints
- SNMP trap support
- Custom webhook alerts

### Automation APIs
- REST API for remote control
- WebSocket for real-time updates
- CLI mode for scripting
- Environment variable overrides

## Testing Requirements

### Functional Testing
1. **Happy Path**: All menu operations work correctly
2. **Error Paths**: Graceful handling of failures
3. **Integration**: Concept 1 script integration verified
4. **Performance**: Operations complete within SLA
5. **Security**: Access controls properly enforced

### User Experience Testing
1. **Navigation**: Menu flow is intuitive
2. **Feedback**: Clear progress indicators
3. **Recovery**: Easy return from errors
4. **Help**: Context-sensitive assistance
5. **Efficiency**: Common tasks are quick

### Load Testing
1. **Concurrent Access**: Multiple admin sessions
2. **Large Logs**: Performance with GB+ log files
3. **Many Players**: Scaling with full server
4. **Rapid Operations**: Quick command sequences
5. **Resource Limits**: Behavior under constraints

## Implementation Roadmap

### Phase 1: Core Console (MVP)
- Basic menu system
- Start/Stop/Restart with Concept 1 integration
- Simple status display
- Error handling framework

### Phase 2: Enhanced Features
- Advanced operations menu
- Configuration management
- Backup/Restore functionality
- Player management tools

### Phase 3: Enterprise Features
- Multi-server support
- Role-based access control
- API/Automation interfaces
- Performance analytics

### Phase 4: Cloud Native
- Kubernetes operator mode
- Auto-scaling capabilities
- Distributed backups
- High availability options

## Success Metrics

### Operational Efficiency
- **Task Completion Time**: 50% reduction vs manual operations
- **Error Rate**: < 1% for standard operations
- **Recovery Time**: < 2 minutes for common issues
- **User Satisfaction**: > 90% positive feedback

### System Reliability
- **Uptime**: 99.9% console availability
- **Data Integrity**: Zero backup corruption
- **Security Incidents**: Zero unauthorized access
- **Performance**: < 100ms menu response time

This specification defines a comprehensive administrative interface that transforms Valheim server management from a collection of scripts into a professional-grade operations console.