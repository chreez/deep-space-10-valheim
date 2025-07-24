# Valheim Server Windows Firewall Configuration

## Quick Setup

The Valheim server ports (27500-27502 UDP) need to be opened in Windows Firewall for players to connect.

### Option 1: Run the Batch Script (Recommended)

1. The firewall setup scripts have been synced to: `E:\valheim-server\scripts\`
2. On your Windows machine:
   - Open File Explorer and navigate to `E:\valheim-server\scripts\`
   - Right-click on `setup_firewall.bat`
   - Select **"Run as administrator"** (IMPORTANT: Admin rights required)
   - The script will automatically configure all necessary firewall rules

### Option 2: Manual PowerShell Setup

1. Open PowerShell as Administrator
2. Navigate to the scripts folder:
   ```powershell
   cd E:\valheim-server\scripts
   ```
3. Run the PowerShell script:
   ```powershell
   .\setup_firewall.ps1
   ```

### Option 3: Manual Windows Defender Firewall Setup

1. Open Windows Defender Firewall with Advanced Security
   - Press `Win + R`, type `wf.msc`, press Enter
   
2. Create Inbound Rules:
   - Click "Inbound Rules" → "New Rule..."
   - Select "Port" → Next
   - Select "UDP" and enter port: 27500
   - Select "Allow the connection" → Next
   - Apply to all profiles → Next
   - Name: "Valheim Server Port 27500"
   - Repeat for ports 27501 and 27502

3. Create Outbound Rules:
   - Click "Outbound Rules" → "New Rule..."
   - Follow same steps as inbound rules for ports 27500-27502

## Verify Firewall Configuration

From PowerShell (run as Administrator):
```powershell
# Check if rules exist
Get-NetFirewallRule | Where-Object {$_.DisplayName -like "*Valheim*"} | Format-Table DisplayName, Direction, Action, Enabled

# Or using netsh
netsh advfirewall firewall show rule name="Valheim Server Port 27500"
netsh advfirewall firewall show rule name="Valheim Server Port 27501"
netsh advfirewall firewall show rule name="Valheim Server Port 27502"
```

## Router Port Forwarding

Don't forget to also configure your router to forward these ports:
- Port Range: 27500-27502
- Protocol: UDP
- Forward to: Your server's local IP (192.168.1.236)

## Current Status

✅ Ports are listening on the server (verified via ss command)
🔧 Windows Firewall rules need to be applied using one of the methods above
📡 Router port forwarding may also be required for external connections