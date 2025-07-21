# Server Control Status Detection Issues - Specification

## Root Cause Analysis

**Issue**: `health_check.py` contains outdated SSH command format causing false positives.

**Line 28-32 in health_check.py**:
```python
full_command = [
    os.path.expanduser("~/.dotfiles/bin/ssh_windows_wsl"),
    self.remote_user,
    "192.168.1.236", 
    command
]
```

**Problem**: Uses old positional arguments instead of new `--command` flag format.

## Issues Found

1. **Outdated SSH Command Format** - `health_check.py:28-32`
   - Current: `ssh_windows_wsl user ip command`
   - Required: `ssh_windows_wsl --command "command"`

2. **Wrong Port Check Command** - `health_check.py:81`
   - Uses `netstat` (not available in WSL)
   - Should use `ss -tlnp`

3. **Process Check Logic Gap** - `health_check.py:54`
   - Assumes command success means server running
   - Doesn't validate actual process existence

## Specification for Fixes

### 1. Update SSH Command Format
**File**: `scripts/health_check.py:25-50`
```python
def ssh_exec(self, command, check=True):
    """Execute command on remote host via SSH"""
    full_command = [
        os.path.expanduser("~/.dotfiles/bin/ssh_windows_wsl"),
        "--command", command
    ]
    # ... rest unchanged
```

### 2. Fix Port Detection
**File**: `scripts/health_check.py:76-84`
```python
def check_ports_open(self):
    """Check if game ports are listening"""
    port_status = {}
    
    for port in [2456, 2457, 2458]:
        stdout, stderr, returncode = self.ssh_exec(f"ss -tlnp | grep :{port}", check=False)
        port_status[port] = str(port) in stdout and returncode == 0
        
    return port_status
```

### 3. Strengthen Process Validation  
**File**: `scripts/health_check.py:52-74`
```python
def check_process_running(self):
    """Check if server process is running"""
    stdout, stderr, returncode = self.ssh_exec(
        "ps aux | grep valheim_server.x86_64 | grep -v grep", 
        check=False
    )
    
    if returncode == 0 and stdout.strip() and "valheim_server.x86_64" in stdout:
        # Process validation logic unchanged
        # ...
    else:
        return {"status": "not_running"}
```

### 4. Add Connection Validation
**File**: `scripts/health_check.py` (new method)
```python
def validate_ssh_connection(self):
    """Validate SSH connection before health checks"""
    stdout, stderr, returncode = self.ssh_exec("echo 'connection_test'", check=False)
    return returncode == 0 and "connection_test" in stdout
```

## Testing Requirements

1. **Test with server stopped** - Should report "not_running"
2. **Test with server running** - Should report accurate PID/stats  
3. **Test with SSH down** - Should handle gracefully
4. **Test port detection** - Should work with `ss` command

## Implementation Priority

1. **Critical**: Fix SSH command format (breaks all checks)
2. **High**: Fix port detection (uses wrong command)  
3. **Medium**: Strengthen process validation
4. **Low**: Add connection validation