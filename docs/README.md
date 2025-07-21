# deep.space.10 Documentation

## 📁 Documentation Structure

This directory contains the complete documentation for the deep.space.10 Valheim modpack and server system.

### 📊 Current Documentation

| File | Purpose | Status |
|------|---------|--------|
| **[prd.md](prd.md)** | Main project requirements and architecture | ✅ Active |
| **[server-setup.spec](server-setup.spec)** | Docker-based server deployment guide | ✅ Active |
| **[gslt-token-guide.md](gslt-token-guide.md)** | Steam token authentication guide | ✅ Active |

### 📁 Archived Documentation

Historical documentation and deprecated specifications are stored in the [`archived/`](archived/) directory:

- `install.spec` - Legacy manual installation (superseded by Docker)
- `july.20.diagnoses.spec.md` - Historical diagnosis from July 20, 2025
- `tool.spec.md` - SSH tool patterns (superseded by Docker approach)
- `server-debug.spec.md` - Debug findings (consolidated into main specs)
- `fix-server-status.spec.md` - Legacy health check fixes

## 🚀 Quick Start

1. **Read the PRD**: Start with [prd.md](prd.md) for project overview and goals
2. **Server Setup**: Follow [server-setup.spec](server-setup.spec) for Docker deployment
3. **Token Configuration**: Use [gslt-token-guide.md](gslt-token-guide.md) for Steam authentication

## 🔐 Security Notes

- Server passwords and tokens are stored in `.env` (git-ignored)
- All deployment uses Docker containers for isolation
- No direct Windows environment modification required

## 🐳 Docker-First Approach

The current system is built around containerized deployment:
- **Server**: `lloesche/valheim-server` Docker image
- **Storage**: Persistent volumes mounted to `/mnt/e/deep.space.10/server`
- **Configuration**: Environment variables from `.env` file
- **Management**: SSH commands via `~/.dotfiles/bin/ssh_windows_wsl`

---

*Last updated: January 2025 - Docker migration complete*