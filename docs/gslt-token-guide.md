# Steam Game Server Login Token (GSLT) Guide for Valheim

## 🎯 Overview
This guide explains how to properly set up and use Steam Game Server Login Tokens (GSLT) for your deep.space.10 Valheim dedicated server running in Docker containers.

## 🔐 What is a GSLT?
A **Game Server Login Token** is a persistent authentication token that Steam uses to:
- **Identify your server** uniquely across IP address changes
- **Verify game ownership** (you must own Valheim to create tokens)
- **Prevent fake servers** from cluttering the server browser
- **Enable player favorites** to work even when you change hosting providers

## ✅ Prerequisites for GSLT Creation

### Steam Account Requirements
Your Steam account must meet these criteria:
- ✅ **Not community banned or locked**
- ✅ **Not a limited account**
- ✅ **Has a verified phone number**
- ✅ **Owns Valheim** (AppID: 892970)
- ✅ **Under 1000 total game server accounts**

### Valheim-Specific Information
- **Game AppID**: 892970 (Valheim)
- **Dedicated Server AppID**: 896660 (used by SteamCMD)
- **Docker Image**: Uses AppID 896660 internally for server files

## 🚀 Creating a GSLT for Valheim

### Step 1: Access Steam's GSLT Management
1. Go to [Steam Game Server Account Management](https://steamcommunity.com/dev/managegameservers)
2. Log in with your Steam account that owns Valheim

### Step 2: Create New Token
1. Click **"Create a Game Server Account"**
2. **App ID**: Enter `892970` (Valheim's AppID)
3. **Memo**: Enter descriptive text like `deep.space.10 Valheim Server`
4. Click **"Create"**

### Step 3: Record Your Token
- Copy the generated token (format: letters and numbers, ~32 characters)
- Example format: `E604789482D21A6DBD8BC97ECAA7538F`
- **⚠️ Keep this secure** - treat it like a password

## 🐳 Using GSLT with Docker Container

### Environment Variable Configuration
Add your GSLT to the `.env` file:

```bash
# Steam Game Server Login Token (GSLT)
# This token allows the server to authenticate with Steam
SERVER_TOKEN=E604789482D21A6DBD8BC97ECAA7538F
```

### Docker Run Command Integration
The lloesche/valheim-server container uses the `SERVER_TOKEN` environment variable:

```bash
docker run -d --name valheim-server \
  -p 2456-2458:2456-2458/udp \
  -v /mnt/e/deep.space.10/server:/config \
  -e SERVER_TOKEN="${SERVER_TOKEN}" \
  -e SERVER_NAME="DeepSpace10" \
  -e WORLD_NAME="DeepSpace10" \
  -e SERVER_PASS="your_password" \
  -e PUBLIC=0 \
  lloesche/valheim-server
```

## 🔍 Validation & Troubleshooting

### Verifying GSLT is Working
Check container logs for successful authentication:

```bash
# Look for successful Steam authentication
docker logs valheim-server | grep -i "steam"
docker logs valheim-server | grep -i "token"
```

### Expected Log Messages
✅ **Good signs**:
- `Game server connected to Steam successfully`
- `Steam authentication successful`
- No authentication errors in logs

❌ **Problem signs**:
- `Steam authentication failed`
- `Invalid game server login token`
- `Token has expired`

### Common Issues and Solutions

#### Issue: "Invalid game server login token"
**Causes**:
- Token typo in `.env` file
- Token created for wrong AppID
- Token has expired from disuse

**Solutions**:
1. Verify token copied correctly from Steam
2. Ensure you used AppID `892970` when creating
3. Regenerate token if expired

#### Issue: "Access denied" or authentication failures
**Causes**:
- Steam account doesn't own Valheim
- Account is community banned/limited
- Multiple servers using same token

**Solutions**:
1. Verify Valheim ownership on Steam account
2. Check account standing in Steam
3. Create unique token for each server instance

#### Issue: Server not visible in server browser
**Causes**:
- GSLT not properly configured
- `PUBLIC=0` in environment (intentional for private servers)
- Network/firewall issues

**Solutions**:
1. Set `PUBLIC=1` for public visibility
2. Verify GSLT authentication in logs
3. Check port forwarding (2456-2458 UDP)

## 🔄 Token Management Best Practices

### Token Security
- **Store in .env file** (git-ignored)
- **Never commit tokens** to version control
- **Use environment variables** in production
- **Rotate tokens periodically** for security

### Multiple Servers
- **One token per server** - never share tokens between instances
- **Unique container names** for each server
- **Different port mappings** for each container

### Token Lifecycle
- **Tokens expire** if unused for extended periods
- **Password resets invalidate** all tokens
- **Regenerate expired tokens** through Steam management page
- **Monitor logs** for authentication issues

## 📊 Monitoring GSLT Status

### Automated Health Checks
Include GSLT validation in your health check scripts:

```python
def check_steam_authentication():
    """Check if GSLT authentication is working"""
    logs = subprocess.run([
        '~/.dotfiles/bin/ssh_windows_wsl', 
        '--command', 
        'docker logs valheim-server | tail -50'
    ], capture_output=True, text=True)
    
    return "Steam authentication successful" in logs.stdout
```

### Log Monitoring
Set up alerts for authentication failures:

```bash
# Monitor for authentication issues
~/.dotfiles/bin/ssh_windows_wsl --command \
  "docker logs valheim-server | grep -i 'authentication failed'"
```

## 🎮 Player Experience Benefits

With properly configured GSLT:
- **Persistent server identity** across IP changes
- **Reliable favorites** - players can bookmark your server
- **Better discoverability** in server browser
- **Professional server presentation** with verified authentication

## 🔮 Advanced Configuration

### Multiple World Support
For servers hosting multiple worlds, each needs its own GSLT:

```bash
# World 1: DeepSpace10
SERVER_TOKEN_1=E604789482D21A6DBD8BC97ECAA7538F

# World 2: TestWorld
SERVER_TOKEN_2=F604789482D21A6DBD8BC97ECAA7538E
```

### Load Balancing Considerations
If running multiple server instances:
- Each instance needs unique GSLT
- Use different container names and ports
- Monitor each instance's authentication status

---

## 📚 Additional Resources

- [Steam Game Server Account Management](https://steamcommunity.com/dev/managegameservers)
- [lloesche/valheim-server Documentation](https://github.com/lloesche/valheim-server-docker)
- [Valheim Dedicated Server Wiki](https://valheim.fandom.com/wiki/Dedicated_servers)

*This guide ensures your deep.space.10 Valheim server has proper Steam authentication for optimal player experience.*