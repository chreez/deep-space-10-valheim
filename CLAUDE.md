## Git Best Practices

- Make logical commits between changes always

## Mod Management (r2modman)

**IMPORTANT**: Mods are no longer maintained in this repository. All mod management is handled through r2modman.

**r2modman Profile Code**: `01983a2e-22a5-26ae-35a4-8858c59c0849`

### Mod Deployment Process

1. **Configure mods in r2modman** using the profile code above
2. **Export BepInEx folder** from r2modman when ready to deploy
3. **Manual server deployment** - copy exported folder to server
4. **Update profile code** in documentation if configuration changes

### Documentation Updates

When the r2modman profile is updated:

1. Update the profile code in README.md and CLAUDE.md
2. Add changelog entry noting profile updates
3. Test deployment to ensure compatibility
4. Document any manual configuration steps required

**Note**: Individual mod documentation is maintained by r2modman. This repository focuses on server infrastructure and deployment.

## Client Installation (r2modman)

**Client Setup**: Use r2modman for all client mod installation

**Profile Code**: `01983a2e-22a5-26ae-35a4-8858c59c0849`

### Installation Steps

1. **Install r2modman** from Thunderstore
2. **Select Valheim** as the game
3. **Import profile** using the code above
4. **Launch game via r2modman** to ensure mods load correctly

### Windows Client Path (Reference Only)

- **WSL Path**: `/mnt/d/SteamLibrary/steamapps/common/Valheim`
- **Windows Path**: `D:\SteamLibrary\steamapps\common\Valheim`

**Note**: Direct file manipulation is no longer recommended. Use r2modman for all client-side mod management.

## Read-Only Windows Client Profile

- Profile located at `C:\Users\Chris\AppData\Roaming\r2modmanPlus-local\Valheim\profiles\DS10`
- Used exclusively to analyze windows "client" game install modpack installation
- Contains `mods.yml` file which serves as reference for "Player's game files" or client-side installation details