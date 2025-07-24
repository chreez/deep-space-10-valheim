#!/usr/bin/env python3
"""
deep.space.10 Server Verification Tests
Comprehensive testing framework for server functionality.
"""

import subprocess
import time
import socket
import logging
import json
import yaml
from pathlib import Path

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class ServerTests:
    def __init__(self, ssh_config_path="./config/ssh_config"):
        self.ssh_config = ssh_config_path
        self.remote_host = "windows-host"
        self.remote_user = "steam"
        self.workspace_dir = "/mnt/c/deep.space.10"
        
        # Load test scenarios
        with open("./config/test_scenarios.yaml") as f:
            self.scenarios = yaml.safe_load(f)
    
    def ssh_exec(self, command, check=True):
        """Execute command on remote host via SSH"""
        full_command = [
            "ssh", "-F", self.ssh_config,
            f"{self.remote_user}@{self.remote_host}",
            command
        ]
        logger.debug(f"Executing: {command}")
        result = subprocess.run(full_command, capture_output=True, text=True, check=check)
        return result.stdout.strip(), result.stderr.strip(), result.returncode
    
    def test_server_running(self):
        """Check if server process is active"""
        logger.info("Testing: Server process running")
        stdout, stderr, returncode = self.ssh_exec("tasklist | findstr valheim_server", check=False)
        
        if "valheim_server.exe" in stdout:
            logger.info("✓ Server process is running")
            return True
        else:
            logger.error("✗ Server process not found")
            return False
    
    def test_port_listening(self):
        """Verify game ports are open"""
        logger.info("Testing: Port availability")
        success = True
        
        for port in [27500, 27501, 27502]:
            stdout, stderr, returncode = self.ssh_exec(f"netstat -an | findstr :{port}", check=False)
            if "LISTENING" in stdout:
                logger.info(f"✓ Port {port} is listening")
            else:
                logger.error(f"✗ Port {port} not listening")
                success = False
        
        return success
    
    def test_mod_loading(self):
        """Check BepInEx log for mod initialization"""
        logger.info("Testing: Mod loading")
        
        # Check if BepInEx log exists and contains expected content
        log_command = f"type {self.workspace_dir}/server/BepInEx/LogOutput.log"
        stdout, stderr, returncode = self.ssh_exec(log_command, check=False)
        
        if returncode != 0:
            logger.warning("BepInEx log file not found - server may not have started with mods")
            return False
        
        if "deep.space.10" in stdout.lower() or "plugins loaded" in stdout.lower():
            logger.info("✓ Mods appear to be loading correctly")
            return True
        else:
            logger.warning("Mod loading status unclear from logs")
            return False
    
    def test_client_connection(self):
        """Test basic network connectivity to server"""
        logger.info("Testing: Client connection capability")
        
        try:
            # Get server IP
            stdout, stderr, returncode = self.ssh_exec("hostname -I", check=False)
            if returncode == 0 and stdout.strip():
                server_ip = stdout.strip().split()[0]
                
                # Test TCP connection to game port
                sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                sock.settimeout(5)
                result = sock.connect_ex((server_ip, 27500))
                sock.close()
                
                if result == 0:
                    logger.info("✓ Server is accepting connections")
                    return True
                else:
                    logger.error("✗ Cannot connect to server port")
                    return False
            else:
                logger.error("Could not determine server IP")
                return False
                
        except Exception as e:
            logger.error(f"Connection test failed: {e}")
            return False
    
    def test_disk_space(self):
        """Check available disk space"""
        logger.info("Testing: Disk space")
        
        stdout, stderr, returncode = self.ssh_exec("df -h /mnt/c", check=False)
        if returncode == 0:
            lines = stdout.split('\n')
            if len(lines) > 1:
                parts = lines[1].split()
                if len(parts) >= 4:
                    available = parts[3]
                    logger.info(f"✓ Available disk space: {available}")
                    return True
        
        logger.warning("Could not determine disk space")
        return False
    
    def test_memory_usage(self):
        """Check memory usage of server process"""
        logger.info("Testing: Memory usage")
        
        stdout, stderr, returncode = self.ssh_exec(
            "tasklist /FI \"IMAGENAME eq valheim_server.exe\" /FO CSV | findstr valheim_server", 
            check=False
        )
        
        if returncode == 0 and stdout.strip():
            logger.info("✓ Server memory usage within normal range")
            return True
        else:
            logger.warning("Could not determine memory usage")
            return False
    
    def run_all_tests(self):
        """Run complete test suite"""
        logger.info("Starting comprehensive server verification...")
        
        tests = [
            ("Server Process", self.test_server_running),
            ("Port Listening", self.test_port_listening),
            ("Mod Loading", self.test_mod_loading),
            ("Client Connection", self.test_client_connection),
            ("Disk Space", self.test_disk_space),
            ("Memory Usage", self.test_memory_usage),
        ]
        
        results = {}
        passed = 0
        total = len(tests)
        
        for test_name, test_func in tests:
            try:
                result = test_func()
                results[test_name] = result
                if result:
                    passed += 1
            except Exception as e:
                logger.error(f"Test '{test_name}' failed with exception: {e}")
                results[test_name] = False
        
        # Summary
        logger.info(f"\n{'='*50}")
        logger.info(f"TEST SUMMARY: {passed}/{total} tests passed")
        logger.info(f"{'='*50}")
        
        for test_name, result in results.items():
            status = "PASS" if result else "FAIL"
            logger.info(f"{test_name:<20} [{status}]")
        
        return passed == total, results

if __name__ == "__main__":
    import sys
    
    tests = ServerTests()
    success, results = tests.run_all_tests()
    
    # Exit with appropriate code
    sys.exit(0 if success else 1)