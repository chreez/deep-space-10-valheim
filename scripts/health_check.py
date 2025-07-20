#!/usr/bin/env python3
"""
deep.space.10 Health Check Script
Monitors server health and provides status reports.
"""

import subprocess
import json
import time
import logging
from datetime import datetime, timedelta
from pathlib import Path

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class HealthMonitor:
    def __init__(self, ssh_config_path="./config/ssh_config"):
        self.ssh_config = ssh_config_path
        self.remote_host = "windows-host"
        self.remote_user = "steam"
        self.workspace_dir = "/mnt/c/deep.space.10"
        
    def ssh_exec(self, command, check=True):
        """Execute command on remote host via SSH"""
        full_command = [
            "ssh", "-F", self.ssh_config,
            f"{self.remote_user}@{self.remote_host}",
            command
        ]
        try:
            result = subprocess.run(full_command, capture_output=True, text=True, check=check, timeout=30)
            return result.stdout.strip(), result.stderr.strip(), result.returncode
        except subprocess.TimeoutExpired:
            return "", "Command timed out", 1
        except Exception as e:
            return "", str(e), 1
    
    def check_process_running(self):
        """Check if server process is running"""
        stdout, stderr, returncode = self.ssh_exec("tasklist | findstr valheim_server", check=False)
        
        if returncode == 0 and "valheim_server.exe" in stdout:
            # Extract process info
            lines = stdout.split('\n')
            for line in lines:
                if "valheim_server.exe" in line:
                    parts = line.split()
                    if len(parts) >= 5:
                        pid = parts[1]
                        memory = parts[4]
                        return {
                            "status": "running",
                            "pid": pid,
                            "memory_usage": memory
                        }
            return {"status": "running", "pid": "unknown", "memory_usage": "unknown"}
        else:
            return {"status": "not_running"}
    
    def check_ports_open(self):
        """Check if game ports are listening"""
        port_status = {}
        
        for port in [2456, 2457, 2458]:
            stdout, stderr, returncode = self.ssh_exec(f"netstat -an | findstr :{port}", check=False)
            port_status[port] = "LISTENING" in stdout
            
        return port_status
    
    def check_memory_usage(self):
        """Check system memory usage"""
        stdout, stderr, returncode = self.ssh_exec("wmic OS get TotalVisibleMemorySize,FreePhysicalMemory /value", check=False)
        
        if returncode == 0:
            total_mem = 0
            free_mem = 0
            
            for line in stdout.split('\n'):
                if "TotalVisibleMemorySize=" in line:
                    total_mem = int(line.split('=')[1]) * 1024  # Convert to bytes
                elif "FreePhysicalMemory=" in line:
                    free_mem = int(line.split('=')[1]) * 1024
            
            if total_mem > 0:
                used_mem = total_mem - free_mem
                usage_percent = (used_mem / total_mem) * 100
                
                return {
                    "total_mb": total_mem // (1024 * 1024),
                    "used_mb": used_mem // (1024 * 1024),
                    "free_mb": free_mem // (1024 * 1024),
                    "usage_percent": round(usage_percent, 2)
                }
        
        return {"error": "Could not determine memory usage"}
    
    def check_disk_space(self):
        """Check available disk space"""
        stdout, stderr, returncode = self.ssh_exec("wmic logicaldisk get size,freespace,caption", check=False)
        
        if returncode == 0:
            lines = stdout.split('\n')
            for line in lines:
                if 'C:' in line:
                    parts = line.split()
                    if len(parts) >= 3:
                        caption = parts[0]
                        free_space = int(parts[1]) // (1024 * 1024 * 1024)  # Convert to GB
                        total_space = int(parts[2]) // (1024 * 1024 * 1024)
                        used_space = total_space - free_space
                        usage_percent = (used_space / total_space) * 100
                        
                        return {
                            "drive": caption,
                            "total_gb": total_space,
                            "used_gb": used_space,
                            "free_gb": free_space,
                            "usage_percent": round(usage_percent, 2)
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
            # Get process start time (simplified)
            stdout, stderr, returncode = self.ssh_exec(
                f"wmic process where processid={process_info['pid']} get CreationDate", 
                check=False
            )
            if returncode == 0:
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
            report.append(f"{emoji} Disk Usage: {disk['usage_percent']}% ({disk['free_gb']}GB free)")
        
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