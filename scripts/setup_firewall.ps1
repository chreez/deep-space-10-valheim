# Valheim Server Firewall Configuration Script
# This script creates Windows Firewall rules for Valheim server ports 27500-27502 UDP

Write-Host "Setting up Windows Firewall rules for Valheim Server..." -ForegroundColor Green

# Remove existing Valheim rules if any exist
Write-Host "Removing any existing Valheim firewall rules..." -ForegroundColor Yellow
Remove-NetFirewallRule -DisplayName "Valheim Server*" -ErrorAction SilentlyContinue

# Create Inbound Rules
Write-Host "Creating inbound firewall rules..." -ForegroundColor Cyan

# Port 27500 - Main game port
New-NetFirewallRule -DisplayName "Valheim Server Port 27500 (Inbound)" `
    -Direction Inbound `
    -Protocol UDP `
    -LocalPort 27500 `
    -Action Allow `
    -Profile Any `
    -Description "Allows inbound UDP traffic on port 27500 for Valheim game server"

# Port 27501 - Query port
New-NetFirewallRule -DisplayName "Valheim Server Port 27501 (Inbound)" `
    -Direction Inbound `
    -Protocol UDP `
    -LocalPort 27501 `
    -Action Allow `
    -Profile Any `
    -Description "Allows inbound UDP traffic on port 27501 for Valheim server query"

# Port 27502 - Steam port
New-NetFirewallRule -DisplayName "Valheim Server Port 27502 (Inbound)" `
    -Direction Inbound `
    -Protocol UDP `
    -LocalPort 27502 `
    -Action Allow `
    -Profile Any `
    -Description "Allows inbound UDP traffic on port 27502 for Valheim Steam integration"

# Create Outbound Rules
Write-Host "Creating outbound firewall rules..." -ForegroundColor Cyan

# Port 27500 - Main game port
New-NetFirewallRule -DisplayName "Valheim Server Port 27500 (Outbound)" `
    -Direction Outbound `
    -Protocol UDP `
    -LocalPort 27500 `
    -Action Allow `
    -Profile Any `
    -Description "Allows outbound UDP traffic on port 27500 for Valheim game server"

# Port 27501 - Query port
New-NetFirewallRule -DisplayName "Valheim Server Port 27501 (Outbound)" `
    -Direction Outbound `
    -Protocol UDP `
    -LocalPort 27501 `
    -Action Allow `
    -Profile Any `
    -Description "Allows outbound UDP traffic on port 27501 for Valheim server query"

# Port 27502 - Steam port
New-NetFirewallRule -DisplayName "Valheim Server Port 27502 (Outbound)" `
    -Direction Outbound `
    -Protocol UDP `
    -LocalPort 27502 `
    -Action Allow `
    -Profile Any `
    -Description "Allows outbound UDP traffic on port 27502 for Valheim Steam integration"

# Verify the rules were created
Write-Host "`nVerifying firewall rules..." -ForegroundColor Green
$rules = Get-NetFirewallRule | Where-Object {$_.DisplayName -like "Valheim Server*"} | 
    Select-Object DisplayName, Direction, Action, Enabled

if ($rules) {
    Write-Host "`nSuccessfully created the following firewall rules:" -ForegroundColor Green
    $rules | Format-Table -AutoSize
} else {
    Write-Host "`nError: Failed to create firewall rules!" -ForegroundColor Red
}

Write-Host "`nFirewall configuration complete!" -ForegroundColor Green
Write-Host "Note: Make sure your router is also configured to forward ports 27500-27502 UDP to this machine." -ForegroundColor Yellow