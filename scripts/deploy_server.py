#!/usr/bin/env python3
"""
deep.space.10 Server Deployment Script
Handles automated deployment and verification of the Valheim server.
"""

import subprocess
import json
import time
import logging
import sys
import os
from pathlib import Path

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class ServerDeployer:
    def __init__(self, ssh_config_path="./config/ssh_config"):
        self.ssh_config = ssh_config_path
        self.remote_host = "windows-host"
        self.remote_user = "chris"
        self.workspace_dir = "/mnt/e/deep.space.10"
        
    def ssh_exec(self, command, check=True):
        """Execute command on remote host via SSH"""
        full_command = [
            os.path.expanduser("~/.dotfiles/bin/ssh_windows_wsl"),
            self.remote_user,
            "192.168.1.236",
            command
        ]
        logger.info(f"Executing: {command}")
        result = subprocess.run(full_command, capture_output=True, text=True, check=check)
        # Extract the actual output after the SSH tool messages
        output_lines = result.stdout.strip().split('\n')
        # Find where the actual command output starts
        for i, line in enumerate(output_lines):
            if line.startswith("🚀 Executing command"):
                # Return everything after this line
                return '\n'.join(output_lines[i+1:])
        return result.stdout.strip()
    
    def copy_files(self):
        """Copy server files to remote host"""
        logger.info("Copying server files...")
        subprocess.run([
            "rsync", "-avz", "--progress",
            "-e", os.path.expanduser("~/.dotfiles/bin/ssh_windows_wsl"),
            "./src/server/",
            f"{self.remote_user}@192.168.1.236:{self.workspace_dir}/server/"
        ], check=True)
        
    def configure_server(self):
        """Configure server settings"""
        logger.info("Configuring server...")
        
        # Copy server config
        with open("./config/server_config.json", "r") as f:
            config_content = f.read()
        self.ssh_exec(f"cat > {self.workspace_dir}/server/server_config.json << 'EOF'\n{config_content}\nEOF")
        
        # Set up BepInEx config
        bepinex_config = """[Logging.Console]
Enabled = true

[Preloader.Entrypoint]
Type = MonoBehaviour

[Chainloader]
HideManagerGameObject = false"""
        
        self.ssh_exec(f"mkdir -p {self.workspace_dir}/server/BepInEx/config")
        self.ssh_exec(f"echo '{bepinex_config}' > {self.workspace_dir}/server/BepInEx/config/BepInEx.cfg")
        
    def install_server_mods(self):
        """Install server-side mods"""
        logger.info("Installing server mods...")
        
        # Copy mod files if they exist
        mod_path = Path("./src/modpack/mods")
        if mod_path.exists():
            subprocess.run([
                "rsync", "-avz",
                "-e", os.path.expanduser("~/.dotfiles/bin/ssh_windows_wsl"),
                "./src/modpack/mods/",
                f"{self.remote_user}@192.168.1.236:{self.workspace_dir}/server/BepInEx/plugins/"
            ], check=True)
            
    def start_server(self):
        """Start the Valheim server"""
        logger.info("Starting server...")
        self.ssh_exec(f"cd {self.workspace_dir}/server && nohup ./start_server.bat > server.log 2>&1 &")
        time.sleep(5)  # Give server time to start
        
    def verify_server_status(self):
        """Verify server is running properly"""
        logger.info("Verifying server status...")
        
        try:
            # Check if process is running
            result = self.ssh_exec("tasklist | findstr valheim_server", check=False)
            if "valheim_server.exe" not in result:
                logger.error("Server process not found")
                return False
                
            # Check if ports are listening
            for port in [2456, 2457, 2458]:
                result = self.ssh_exec(f"netstat -an | findstr :{port}", check=False)
                if "LISTENING" not in result:
                    logger.warning(f"Port {port} not listening")
                    
            logger.info("Server verification completed")
            return True
            
        except Exception as e:
            logger.error(f"Server verification failed: {e}")
            return False
    
    def deploy(self):
        """Execute full deployment pipeline"""
        logger.info("Starting deployment...")
        
        try:
            # Skip file copying for now since files already exist
            logger.info("Skipping file copy - using existing server files")
            
            self.configure_server()
            # Skip mod installation for now
            # self.install_server_mods()
            
            # Don't auto-start, let user do it manually
            logger.info("Configuration complete. Use './scripts/server_control.sh start' to start the server.")
            
            # Quick verification
            result = self.ssh_exec("ls -la /mnt/f/ds10/server/valheim_server.x86_64", check=False)
            if "valheim_server.x86_64" in result:
                logger.info("✓ Server executable found")
                return True
            else:
                logger.error("✗ Server executable not found")
                return False
                
        except Exception as e:
            logger.error(f"Deployment failed: {e}")
            return False

if __name__ == "__main__":
    deployer = ServerDeployer()
    success = deployer.deploy()
    sys.exit(0 if success else 1)