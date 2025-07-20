#!/usr/bin/env python3
"""
deep.space.10 Modpack Builder
Creates distribution packages for the modpack.
"""

import json
import zipfile
import hashlib
import shutil
import logging
from pathlib import Path
from datetime import datetime

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

def collect_mod_files():
    """Collect all mod files and dependencies"""
    logger.info("Collecting mod files...")
    
    mod_dir = Path("./src/modpack/mods")
    config_dir = Path("./config")
    manifest_file = Path("./src/modpack/manifest.json")
    
    files_to_include = []
    
    # Add manifest
    if manifest_file.exists():
        files_to_include.append(("manifest.json", manifest_file))
    
    # Add mod files
    if mod_dir.exists():
        for mod_file in mod_dir.rglob("*"):
            if mod_file.is_file():
                relative_path = f"mods/{mod_file.relative_to(mod_dir)}"
                files_to_include.append((relative_path, mod_file))
    
    # Add install script
    install_script = Path("./src/modpack/install.cmd")
    if install_script.exists():
        files_to_include.append(("install.cmd", install_script))
    
    logger.info(f"Collected {len(files_to_include)} files")
    return files_to_include

def generate_manifest():
    """Update manifest with current timestamp and file list"""
    logger.info("Generating manifest...")
    
    manifest_path = Path("./src/modpack/manifest.json")
    if not manifest_path.exists():
        logger.error("Manifest file not found")
        return False
    
    with open(manifest_path) as f:
        manifest = json.load(f)
    
    # Update build info
    manifest["build_date"] = datetime.now().isoformat()
    manifest["build_number"] = int(datetime.now().timestamp())
    
    # Save updated manifest
    with open(manifest_path, 'w') as f:
        json.dump(manifest, f, indent=2)
    
    return True

def create_install_script():
    """Ensure install script is ready"""
    logger.info("Preparing install script...")
    
    install_script = Path("./src/modpack/install.cmd")
    return install_script.exists()

def package_zip(filename):
    """Create the distribution ZIP file"""
    logger.info(f"Creating package: {filename}")
    
    files = collect_mod_files()
    output_path = Path("./deploy") / filename
    output_path.parent.mkdir(exist_ok=True)
    
    with zipfile.ZipFile(output_path, 'w', zipfile.ZIP_DEFLATED) as zf:
        for archive_name, file_path in files:
            zf.write(file_path, archive_name)
            logger.debug(f"Added: {archive_name}")
    
    logger.info(f"Package created: {output_path}")
    return output_path.exists()

def generate_checksums():
    """Generate checksums for verification"""
    logger.info("Generating checksums...")
    
    deploy_dir = Path("./deploy")
    checksum_file = deploy_dir / "checksums.txt"
    
    checksums = []
    for zip_file in deploy_dir.glob("*.zip"):
        with open(zip_file, 'rb') as f:
            content = f.read()
            md5_hash = hashlib.md5(content).hexdigest()
            sha256_hash = hashlib.sha256(content).hexdigest()
            
        checksums.append(f"MD5 ({zip_file.name}) = {md5_hash}")
        checksums.append(f"SHA256 ({zip_file.name}) = {sha256_hash}")
    
    with open(checksum_file, 'w') as f:
        f.write('\n'.join(checksums))
    
    logger.info(f"Checksums written to: {checksum_file}")
    return True

def build_modpack(version=None):
    """Build distribution package"""
    if not version:
        # Read version from manifest
        manifest_path = Path("./src/modpack/manifest.json")
        if manifest_path.exists():
            with open(manifest_path) as f:
                manifest = json.load(f)
                version = manifest.get("version", "1.0.0")
        else:
            version = "1.0.0"
    
    logger.info(f"Building modpack version {version}")
    
    steps = [
        collect_mod_files,
        generate_manifest,
        create_install_script,
        lambda: package_zip(f"deep.space.10-v{version}.zip"),
        generate_checksums
    ]
    
    for i, step in enumerate(steps, 1):
        logger.info(f"Step {i}/{len(steps)}: {step.__name__}")
        if not step():
            logger.error(f"Step {i} failed: {step.__name__}")
            return False
    
    logger.info("✓ Modpack build completed successfully")
    return True

if __name__ == "__main__":
    import sys
    version = sys.argv[1] if len(sys.argv) > 1 else None
    success = build_modpack(version)
    sys.exit(0 if success else 1)