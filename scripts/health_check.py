#!/usr/bin/env python3
"""
deep.space.10 Health Check Script
Monitors server health and provides status reports.
"""

import subprocess
import json
import time
import logging
import os
from datetime import datetime, timedelta
from pathlib import Path

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class HealthMonitor:
    def __init__(self, ssh_config_path="./config/ssh_config"):
        self.ssh_config = ssh_config_path
        self.remote_host = "windows-host"
        self.remote_user = "chris"
        self.workspace_dir = "/mnt/e/deep.space.10"
        
    def ssh_exec(self, command, check=True):
        """Execute command on remote host via SSH"""
        full_command = [
            os.path.expanduser("~/.dotfiles/bin/ssh_windows_wsl"),
            "--command", command
        ]
        try:
            result = subprocess.run(full_command, capture_output=True, text=True, check=check, timeout=30)
            # Extract the actual output after the SSH tool messages
            output_lines = result.stdout.strip().split('\n')
            actual_output = []
            
            # Find the last occurrence of "🚀 Executing command" line
            last_exec_index = -1
            for i, line in enumerate(output_lines):
                if line.startswith("🚀 Executing command") and ":" in line:
                    last_exec_index = i
            
            # Capture everything after the last execution line
            if last_exec_index >= 0 and last_exec_index + 1 < len(output_lines):
                actual_output = output_lines[last_exec_index + 1:]
            
            stdout = '\n'.join(actual_output) if actual_output else ""
            return stdout, result.stderr.strip(), result.returncode
        except subprocess.TimeoutExpired:
            return "", "Command timed out", 1
        except Exception as e:
            return "", str(e), 1
    
    def validate_ssh_connection(self):
        """Validate SSH connection before health checks"""
        stdout, stderr, returncode = self.ssh_exec("echo 'connection_test'", check=False)
        return returncode == 0 and "connection_test" in stdout
    
    def check_process_running(self):
        """Check if server process is running"""
        stdout, stderr, returncode = self.ssh_exec(
            "ps aux | grep valheim_server.x86_64 | grep -v grep", 
            check=False
        )
        
        if returncode == 0 and stdout.strip() and "valheim_server.x86_64" in stdout:
            # Extract process info from ps output
            lines = stdout.split('\n')
            for line in lines:
                if "valheim_server.x86_64" in line and "grep" not in line:
                    parts = line.split()
                    if len(parts) >= 11:
                        pid = parts[1]
                        cpu = parts[2]
                        memory = parts[3]
                        return {
                            "status": "running",
                            "pid": pid,
                            "cpu_usage": cpu + "%",
                            "memory_usage": memory + "%"
                        }
            # If we get here, the grep found something but no valid process line
            return {"status": "not_running"}
        else:
            return {"status": "not_running"}
    
    def check_ports_open(self):
        """Check if game ports are listening"""
        port_status = {}
        
        for port in [27500, 27501, 27502]:
            stdout, stderr, returncode = self.ssh_exec(f"ss -tlnp | grep :{port}", check=False)
            port_status[port] = returncode == 0 and stdout.strip() and str(port) in stdout
            
        return port_status
    
    def check_memory_usage(self):
        """Check system memory usage"""
        stdout, stderr, returncode = self.ssh_exec("free -m", check=False)
        
        if returncode == 0:
            lines = stdout.split('\n')
            for line in lines:
                if line.startswith('Mem:'):
                    parts = line.split()
                    if len(parts) >= 4:
                        total_mb = int(parts[1])
                        used_mb = int(parts[2])
                        free_mb = int(parts[3])
                        usage_percent = (used_mb / total_mb) * 100
                        
                        return {
                            "total_mb": total_mb,
                            "used_mb": used_mb,
                            "free_mb": free_mb,
                            "usage_percent": round(usage_percent, 2)
                        }
        
        return {"error": "Could not determine memory usage"}
    
    def check_disk_space(self):
        """Check available disk space"""
        stdout, stderr, returncode = self.ssh_exec("df -h /mnt/e", check=False)
        
        if returncode == 0:
            lines = stdout.split('\n')
            for line in lines:
                if '/mnt/e' in line:
                    parts = line.split()
                    if len(parts) >= 6:
                        total = parts[1]
                        used = parts[2]
                        free = parts[3]
                        usage_percent = parts[4].strip('%')
                        
                        return {
                            "drive": "/mnt/e",
                            "total": total,
                            "used": used,
                            "free": free,
                            "usage_percent": float(usage_percent)
                        }
        
        return {"error": "Could not determine disk space"}
    
    def get_player_count(self):
        """Get current player count (simplified)"""
        # This would need integration with Valheim's server API or log parsing
        # For now, return placeholder
        return {"current_players": 0, "max_players": 10}
    
    def get_server_uptime(self):
        """Get server uptime"""
        process_info = self.check_process_running()
        if process_info["status"] == "running" and "pid" in process_info:
            # Get process start time using ps
            stdout, stderr, returncode = self.ssh_exec(
                f"ps -p {process_info['pid']} -o etime=", 
                check=False
            )
            if returncode == 0 and stdout.strip():
                return {"uptime": stdout.strip(), "status": "running"}
            else:
                return {"uptime": "Unknown", "status": "running"}
        
        return {"uptime": "0", "status": "not_running"}
    
    def verify_mod_versions(self):
        """Verify mod versions match manifest"""
        manifest_path = Path("./src/modpack/manifest.json")
        if not manifest_path.exists():
            return {"status": "no_manifest"}
        
        try:
            with open(manifest_path) as f:
                manifest = json.load(f)
            
            expected_mods = {mod["name"]: mod["version"] for mod in manifest.get("mods", [])}
            
            # Check if BepInEx log contains mod loading info
            stdout, stderr, returncode = self.ssh_exec(
                f"type {self.workspace_dir}/server/BepInEx/LogOutput.log",
                check=False
            )
            
            if returncode == 0:
                loaded_mods = []
                for line in stdout.split('\n'):
                    if "plugin" in line.lower() and "loaded" in line.lower():
                        loaded_mods.append(line.strip())
                
                return {
                    "status": "verified",
                    "expected_mods": len(expected_mods),
                    "loaded_indicators": len(loaded_mods)
                }
            else:
                return {"status": "no_log_file"}
                
        except Exception as e:
            return {"status": "error", "message": str(e)}
    
    def server_health_check(self):
        """Perform comprehensive health check"""
        logger.info("Starting health check...")
        
        health_data = {
            "timestamp": datetime.now().isoformat(),
            "process": self.check_process_running(),
            "ports": self.check_ports_open(),
            "memory": self.check_memory_usage(),
            "disk": self.check_disk_space(),
            "players": self.get_player_count(),
            "uptime": self.get_server_uptime(),
            "mods": self.verify_mod_versions()
        }
        
        # Determine overall health
        issues = []
        if health_data["process"]["status"] != "running":
            issues.append("Server process not running")
        
        if not all(health_data["ports"].values()):
            issues.append("Some ports not listening")
        
        if "usage_percent" in health_data["memory"] and health_data["memory"]["usage_percent"] > 90:
            issues.append("High memory usage")
        
        if "usage_percent" in health_data["disk"] and health_data["disk"]["usage_percent"] > 95:
            issues.append("Low disk space")
        
        health_data["overall_health"] = "healthy" if not issues else "issues"
        health_data["issues"] = issues
        
        return health_data
    
    def generate_report(self, health_data):
        """Generate human-readable health report"""
        report = []
        report.append("=" * 60)
        report.append("deep.space.10 Server Health Report")
        report.append(f"Generated: {health_data['timestamp']}")
        report.append("=" * 60)
        
        # Overall status
        status_emoji = "🟢" if health_data["overall_health"] == "healthy" else "🔴"
        report.append(f"\nOverall Status: {status_emoji} {health_data['overall_health'].upper()}")
        
        if health_data["issues"]:
            report.append("\nIssues Found:")
            for issue in health_data["issues"]:
                report.append(f"  ⚠️  {issue}")
        
        # Process status
        process = health_data["process"]
        if process["status"] == "running":
            report.append(f"\n✅ Server Process: Running (PID: {process.get('pid', 'unknown')})")
            if "memory_usage" in process:
                report.append(f"   Memory: {process['memory_usage']}")
        else:
            report.append("\n❌ Server Process: Not running")
        
        # Port status
        report.append("\nPort Status:")
        for port, listening in health_data["ports"].items():
            status = "✅ Open" if listening else "❌ Closed"
            report.append(f"  Port {port}: {status}")
        
        # Memory usage
        memory = health_data["memory"]
        if "usage_percent" in memory:
            emoji = "🟢" if memory["usage_percent"] < 80 else "🟡" if memory["usage_percent"] < 90 else "🔴"
            report.append(f"\n{emoji} Memory Usage: {memory['usage_percent']}% ({memory['used_mb']}MB / {memory['total_mb']}MB)")
        
        # Disk space
        disk = health_data["disk"]
        if "usage_percent" in disk:
            emoji = "🟢" if disk["usage_percent"] < 80 else "🟡" if disk["usage_percent"] < 95 else "🔴"
            report.append(f"{emoji} Disk Usage: {disk['usage_percent']}% ({disk['free']} free of {disk['total']})")
        
        # Mod status
        mods = health_data["mods"]
        if mods["status"] == "verified":
            report.append(f"\n✅ Mods: {mods['expected_mods']} expected, {mods['loaded_indicators']} load indicators found")
        elif mods["status"] == "no_log_file":
            report.append("\n⚠️  Mods: No log file found (server may not have started)")
        else:
            report.append(f"\n❌ Mods: Status unknown ({mods['status']})")
        
        report.append("\n" + "=" * 60)
        
        return "\n".join(report)

def main():
    monitor = HealthMonitor()
    
    try:
        health_data = monitor.server_health_check()
        
        # Generate and display report
        report = monitor.generate_report(health_data)
        print(report)
        
        # Save detailed data to file
        output_file = Path("./logs") / f"health_check_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        output_file.parent.mkdir(exist_ok=True)
        
        with open(output_file, 'w') as f:
            json.dump(health_data, f, indent=2)
        
        logger.info(f"Detailed health data saved to: {output_file}")
        
        # Exit with appropriate code
        return 0 if health_data["overall_health"] == "healthy" else 1
        
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        return 1

if __name__ == "__main__":
    import sys
    sys.exit(main())