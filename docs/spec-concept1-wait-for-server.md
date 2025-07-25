# Concept 1: Wait for Server Up Script Specification

## Overview

A specialized monitoring script that efficiently waits for Valheim server startup completion, optimized for agentic workflows while providing excellent human user experience. The script bridges the gap between server restart and readiness for player connections or administrative commands.

## Purpose

- **Agentic Optimization**: Minimize context window usage with condensed, meaningful output
- **Reliable Detection**: Use log patterns and Docker status rather than unreliable port checking
- **User Experience**: Provide satisfying progress feedback during server initialization
- **Integration Ready**: Serve as a building block for higher-level server management tools

## Success Criteria

### Primary Success Conditions
1. **Server Process Running**: Docker container status shows "Up" and `valheim_server.x86_64` process is active
2. **BepInEx Loaded**: All expected mods loaded successfully (detected via `Loading [` pattern count)
3. **Network Ready**: Ports 27500-27502 are listening and accepting connections
4. **Game Server Connected**: Canonical ready message `"Game server connected"` appears in logs
5. **Clean Exit**: Script exits with code 0 when all conditions met, code 1 on timeout/failure

### Output Format Requirements

**Standard Progress Display:**
```
Waiting for server to load..
[Container: ✓] [BepInEx: ▣ 12 mods] [Network: ○] [Ready: ○]
... Waiting 5 seconds.. Time till timeout: 8 minutes 45 seconds
```

**Context Window Optimized Features:**
- Single-line status updates (overwrite, don't append)
- Condensed log samples (2-3 critical lines maximum)
- Progressive disclosure (detail only when problems occur)
- Minimal final output (success/failure message only)

### Animation Elements

**Subtle Progress Indicators:**
1. **Spinner Animation** (for active phases):
   - Frames: `⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏` (braille pattern)
   - Alternative: `◐ ◓ ◑ ◒` (quarter circles)
   - Usage: `[BepInEx: ⠸ Loading...]` rotates during mod loading

2. **Progress Bars** (for countable items):
   - Mod loading: `[BepInEx: ▓▓▓▓▓▓▓░░░ 12/15]`
   - Time remaining: `[████████░░░░░░░░] 8:45`
   - Subtle fill: `[••••••••○○○○○○○○]`

3. **Pulsing Indicators** (for waiting states):
   - Network pending: `[Network: ◯]` → `[Network: ◉]` → `[Network: ◯]`
   - Container starting: `[Container: ◇]` → `[Container: ◆]` → `[Container: ◇]`
   - Subtle opacity: Use dim/bright alternation if terminal supports

4. **State Transitions** (smooth status changes):
   - Pending → Active: `○` → `◐` → `◑` → `◒` → `◓` → `●` → `✓`
   - Loading progress: `░` → `▒` → `▓` → `█` → `✓`
   - Failed state: `○` → `◐` → `⚠` → `✗`

**Implementation Details:**
```bash
# Animation frame arrays
SPINNER_FRAMES=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
PULSE_FRAMES=("◯" "◉" "◯")
PROGRESS_BLOCKS=("░" "▒" "▓" "█")

# Update function with frame cycling
update_animation() {
    local phase=$1
    local frame_index=$((POLL_COUNT % ${#SPINNER_FRAMES[@]}))
    echo -ne "\r${SPINNER_FRAMES[$frame_index]} $phase"
}
```

**Terminal Compatibility:**
- Fallback to ASCII: `[*]` for Unicode-challenged terminals
- Color support detection: Use colors only when available
- Width-aware: Truncate animations for narrow terminals
- Performance: Animation updates only on poll intervals (not continuous)

## Technical Requirements

### Core Monitoring Logic

**Phase 1: Container Status**
- Command: `docker ps --filter name=valheim-server --format "{{.Status}}"`
- Success: Status contains "Up"
- Failure: Container not found or stopped

**Phase 2: BepInEx Loading**
- Command: `docker logs valheim-server | grep -c "Loading \["`
- Success: Count matches expected mod count (from manifest or configuration)
- Progress: Show current mod count as it increases

**Phase 3: Network Readiness**
- Commands: `ss -tlnp | grep :27500`, `:27501`, `:27502`
- Success: All three ports show LISTENING status
- Validation: Avoid false positives from other processes

**Phase 4: Server Ready Signal**
- Command: `docker logs valheim-server | grep "Game server connected"`
- Success: Message appears in recent logs
- Final: This is the definitive "server ready" indicator

### Configuration Parameters

```bash
POLL_INTERVAL=5           # Seconds between status checks
TIMEOUT=600              # Total timeout in seconds (10 minutes)
CONTAINER_NAME="valheim-server"
EXPECTED_MOD_COUNT=12    # Expected number of BepInEx mods
MIN_UPTIME=30           # Minimum seconds before considering stable
```

### Status Indicators

- `✓` Phase complete and stable
- `▣` Phase in progress
- `○` Phase pending/not started
- `✗` Phase failed
- `[N]` Progress counter (mod count, seconds, etc.)

### Error Handling

**Timeout Scenarios:**
- Container fails to start: Exit with detailed Docker error
- BepInEx hangs: Report last loaded mod and suggest investigation
- Network binding fails: Check for port conflicts
- Server crashes during startup: Report crash logs

**Recovery Suggestions:**
- Container issues: Check Docker daemon, resource availability
- Mod loading failures: Verify mod compatibility and dependencies
- Network problems: Check firewall rules and port availability
- Generic failures: Point to log files and troubleshooting guides

## Integration Dependencies

### Required Tools
- `~/.dotfiles/bin/ssh_windows_wsl` for remote command execution
- `docker` command access on remote host
- Standard UNIX utilities: `grep`, `wc`, `ss`/`netstat`

### Environment Variables
- Load from `.env` file: `SERVER_NAME`, `CONTAINER_NAME`
- Optional: `DISCORD_WEBHOOK` for startup notifications
- Configuration: `WORKSPACE_DIR`, SSH connection details

### File Dependencies
- `./src/modpack/manifest.json` for expected mod count
- Docker container logs via `docker logs $CONTAINER_NAME`
- Remote BepInEx logs: `$WORKSPACE_DIR/server/BepInEx/LogOutput.log`

## Implementation Details

### Script Structure
```bash
#!/bin/bash
# wait_for_server.sh - Agentic-optimized server startup monitor

load_environment()     # Source .env and validate prerequisites
validate_prerequisites() # Check SSH connection and Docker access
monitor_startup_phases() # Main monitoring loop with status display
check_container_status() # Phase 1: Docker container running
check_bepinex_loading()  # Phase 2: Mod loading progress
check_network_ready()    # Phase 3: Port binding verification
check_server_ready()     # Phase 4: Game server connected message
update_progress_display() # Single-line status update
handle_timeout()         # Cleanup and error reporting
```

### Output Management
- Use `\r` for same-line updates to minimize scrollback
- Color coding: Green (✓), Yellow (▣), Red (✗), Blue (info)
- Preserve last few log lines in case of failure
- JSON output mode for programmatic consumption

### Performance Considerations
- Cache SSH connections where possible
- Batch log parsing to reduce remote command frequency
- Use efficient grep patterns to minimize processing overhead
- Implement exponential backoff for repeated failures

## Testing Scenarios

### Success Path Testing
1. **Normal Startup**: Fresh server start with all mods loading correctly
2. **Quick Start**: Server already running when script executes
3. **Mod Loading**: Various mod counts and loading speeds
4. **Network Delays**: Slow port binding scenarios

### Failure Path Testing
1. **Container Failure**: Docker daemon issues, resource exhaustion
2. **Mod Failures**: Missing dependencies, conflicting mods
3. **Network Issues**: Port conflicts, firewall blocking
4. **Timeout Handling**: Various timeout scenarios and cleanup
5. **SSH Failures**: Connection drops, authentication issues

### Edge Cases
1. **Rapid Restart**: Server stop/start during monitoring
2. **Log Rotation**: Large log files or log truncation
3. **Resource Constraints**: Low memory/CPU affecting startup time
4. **Concurrent Access**: Multiple monitoring instances

## Example Usage

```bash
# Basic usage - wait for server with default timeout
./scripts/wait_for_server.sh

# With custom timeout and verbose mode
./scripts/wait_for_server.sh --timeout 900 --verbose

# JSON output for programmatic use
./scripts/wait_for_server.sh --json

# Integration with restart workflow
./scripts/server_control.sh restart && ./scripts/wait_for_server.sh
```

## Success Metrics

### Performance Targets
- **Startup Detection**: < 30 seconds after server becomes ready
- **Resource Usage**: < 1% CPU usage during monitoring
- **Network Overhead**: < 10 SSH commands per monitoring cycle
- **Context Efficiency**: < 20 lines of output for successful startup

### Reliability Requirements
- **False Negative Rate**: < 1% (missing ready servers)
- **False Positive Rate**: < 0.1% (reporting ready when not)
- **Timeout Accuracy**: ±5 seconds of configured timeout
- **Error Recovery**: Graceful handling of 95% of failure scenarios

This specification provides the foundation for a robust, efficient server monitoring tool that serves both human operators and automated systems effectively.