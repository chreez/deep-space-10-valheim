# Specification: get_valheim_mods

## Purpose
Extract and display comprehensive mod information from r2modman Valheim profile

## Input Parameters
- `--profile`: Profile name (default: "DS10")
- `--format`: Output format (text/json/csv, default: text)
- `--sort`: Sort by (name/date/enabled, default: name)
- `--filter`: Filter (all/enabled/disabled, default: all)

## Output Formats

### Text Format (Default)
```
=== VALHEIM MOD LIST (45 mods) ===

[ENABLED MODS - 44]

AAA_Crafting (1.6.6)
Author: Azumatt
Dependencies: BepInExPack_Valheim
Installed: 2024-01-25

AdventureBackpacks (1.7.10)
Author: Vapok
Dependencies: BepInExPack_Valheim
Installed: 2024-01-25

[... alphabetized list ...]

[DISABLED MODS - 1]

ModName (version)
Author: AuthorName
Dependencies: [list]
Installed: date

=== DEPENDENCY TREE ===

BepInExPack_Valheim (5.4.2202)
├── AAA_Crafting (1.6.6)
├── AdventureBackpacks (1.7.10)
└── [... other dependents]

=== STATISTICS ===
- Total mods: 45
- Enabled: 44
- Disabled: 1
- Core dependencies: 4
```

### JSON Format
```json
{
  "profile": "DS10",
  "total_mods": 45,
  "enabled_count": 44,
  "disabled_count": 1,
  "mods": [
    {
      "name": "AAA_Crafting",
      "full_name": "Azumatt-AAA_Crafting",
      "version": "1.6.6",
      "enabled": true,
      "installed_date": "2024-01-25T12:34:56Z",
      "dependencies": ["BepInExPack_Valheim"],
      "description": "Anti-arthritis crafting...",
      "author": "Azumatt"
    }
  ],
  "dependency_tree": {
    "BepInExPack_Valheim": {
      "version": "5.4.2202",
      "dependents": ["AAA_Crafting", "AdventureBackpacks"]
    }
  }
}
```

### CSV Format
```csv
name,full_name,version,enabled,author,dependencies,installed_date
AAA_Crafting,Azumatt-AAA_Crafting,1.6.6,true,Azumatt,BepInExPack_Valheim,2024-01-25
AdventureBackpacks,Vapok-AdventureBackpacks,1.7.10,true,Vapok,BepInExPack_Valheim,2024-01-25
```

## Implementation Details

### Location
`~/.dotfiles/bin/get_valheim_mods`

### Approach
1. SSH to Windows system to access r2modman files
2. Parse mods.yml using awk/sed (no external dependencies)
3. Build dependency tree from parsed data
4. Format output based on --format parameter
5. Apply sorting and filtering as requested

### Key Features
- Auto-discovery of r2modman installation path
- Support for multiple profiles
- Complete dependency resolution
- Version tracking for all mods
- Installation date tracking
- Multiple export formats for different use cases

### Error Handling
- Check SSH connection to Windows
- Verify profile exists
- Handle missing or corrupted mods.yml
- Provide helpful error messages

## Usage Examples

```bash
# Basic usage - text output
get_valheim_mods

# JSON for processing
get_valheim_mods --format json > mods.json

# Filter only enabled mods
get_valheim_mods --filter enabled

# Sort by install date
get_valheim_mods --sort date

# Different profile
get_valheim_mods --profile "MyOtherProfile"

# CSV for spreadsheet
get_valheim_mods --format csv > mods.csv
```

## Notes
- Tool focuses on reporting installed mods only (no update checking)
- Dependency versions are stripped in text format for readability
- Full dependency information preserved in JSON format
- Compatible with Claude Code CLI via Bash tool