## Git Best Practices

- Make logical commits between changes always

## Mod Documentation Format

When mods are added, removed, or otherwise modified, always update the README.md "MODPACK CONTENTS" section with this exact format:

```
- **ModName** [Tag] - Brief description under 200 characters
```

Where:
- **ModName**: The exact mod name in bold
- [Tag]: One of [Server], [Client], or [Both] indicating installation requirements
- Description: Concise explanation of what the mod does (< 200 chars)

Organize mods by these categories:
1. Framework & Dependencies
2. Building & Construction  
3. Inventory & Storage
4. Gameplay & Content
5. Quality of Life
6. Environment & Nature
7. Economy & Trading
8. Server Administration

Keep entries alphabetically sorted within each category for consistency.

## Mod Changelog Format

When mods are added, removed, or modified, always:

1. Update the "MODPACK CONTENTS" section with the current mod list
2. Add a new entry to the "MODPACK CHANGELOG" section with:
   - Version number (increment appropriately)
   - Date in YYYY-MM-DD format
   - List of changes under **Added X new mods:**, **Removed X mods:**, or **Updated X mods:**
   - Each mod entry must include:
     - **ModName** - Brief description of features/changes (< 200 chars)

Example changelog entry:
```
### ◆ Version X.X.X - YYYY-MM-DD
**Added 3 new mods:**
- **ExampleMod** - Adds new crafting recipes and improves inventory management
- **AnotherMod** - Enhanced building system with snap points and rotation helpers
- **ThirdMod** - Quality of life improvements for farming and resource gathering
```

## Windows Client Installation Path

The Valheim client installation on the Windows host is located at:
- **WSL Path**: `/mnt/d/SteamLibrary/steamapps/common/Valheim`
- **Windows Path**: `D:\SteamLibrary\steamapps\common\Valheim`

When deploying mods to the client:
1. Backup existing BepInEx directory first
2. Copy dist/BepInEx.zip to temp location
3. Extract to client directory
4. This is the same modpack that goes to the server