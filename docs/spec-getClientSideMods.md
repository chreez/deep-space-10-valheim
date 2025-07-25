# getClientSideMods - Source URL Discovery Specification

## AI Usage Guide

**Token Optimization Strategy**: Less tokens by default → Use additional parameters to expand

### Quick Reference
```bash
# Read from Windows r2modman profile (instant, only installed mods):
getClientSideMods --profile DS10 --silent --format json

# Ultra-minimal tokens (names + versions only - 77% smaller):
getClientSideMods --minimal --silent --format json

# Regular output (all fields except source URLs):
getClientSideMods --silent --format json

# Single mod with source:
getClientSideMods --filter-mod "ModName" --with-source --silent --format json

# Profile mods with source discovery:
getClientSideMods --profile DS10 --with-source --silent --format json

# All mods with sources (WARNING: slow, rate limited):
getClientSideMods --with-source --silent --format json
```

### Token Usage
- **With --profile**: ~5-20KB JSON (instant, only installed mods from Windows)
- **With --minimal**: ~794KB JSON (names + versions only, 77% reduction)
- **Without --with-source**: ~3.4MB JSON (all fields, no API calls)
- **With --with-source**: ~3.5MB JSON + 300ms throttle per mod
- **Recommendation**: Use --profile for installed mods, --minimal for all mods, filter when source URLs needed

## Overview
Test cases for verifying the source URL discovery implementation, with specific mods that require each discovery method.

## Default Behavior
- **Progress Display**: Shows current mod being processed with status updates
- **Quiet Logging**: Default output shows only progress, no verbose logs
- **API Throttling**: 300ms delay between GitHub API calls to respect rate limits
- **Best Effort Discovery**: Attempts all methods to maximize source URL coverage

## Profile Mode (NEW)
- **Windows Integration**: Reads r2modman profiles via SSH from Windows server
- **Instant Results**: No API calls needed, reads local mods.yml file
- **Filtered List**: Shows only enabled mods from the specified profile
- **Path**: `/mnt/c/Users/Chris/AppData/Roaming/r2modmanPlus-local/Valheim/profiles/{profile}/mods.yml`
- **Usage**: `getClientSideMods --profile DS10`

## Test Cases by Discovery Method

### Method 1: Thunderstore API Direct
**Mods where `website_url` contains GitHub URL directly**

| Mod ID | Expected URL | Test Command |
|--------|--------------|--------------|
| `ValheimModding-Jotunn` | `https://github.com/Valheim-Modding/Jotunn` | `getClientSideMods --filter-mod "ValheimModding-Jotunn"` |
| `Vapok-AdventureBackpacks` | `https://github.com/Vapok/AdventureBackpacks` | `getClientSideMods --filter-mod "Vapok-AdventureBackpacks"` |
| `Smoothbrain-Farming` | `https://github.com/blaxxun-boop/Farming` | `getClientSideMods --filter-mod "Smoothbrain-Farming"` |

**Expected Log Output:**
```
[INFO] Discovering source URL for ValheimModding-Jotunn
[INFO] Method 1: Found GitHub URL in Thunderstore API
[INFO] Source URL: https://github.com/Valheim-Modding/Jotunn
```

### Method 2: README Extraction Required
**Mods where GitHub URL is in README/description but not in `website_url`**

| Mod ID | Website URL | Expected GitHub URL | Test Command |
|--------|-------------|-------------------|--------------|
| `Azumatt-WardIsLove` | `https://discord.gg/Pb6bVMnFb2` | `https://github.com/AzumattDev/WardIsLove` | `getClientSideMods --filter-mod "Azumatt-WardIsLove"` |
| `MSchmoecker-PieceManager` | *(empty)* | `https://github.com/MSchmoecker/PieceManager` | `getClientSideMods --filter-mod "MSchmoecker-PieceManager"` |
| `Advize-PlantEverything` | `https://www.nexusmods.com/valheim/mods/1042` | `https://github.com/advize/Valheim-PlantEverything` | `getClientSideMods --filter-mod "Advize-PlantEverything"` |

**Expected Log Output:**
```
[INFO] Discovering source URL for Azumatt-WardIsLove
[INFO] Method 1: No GitHub URL in Thunderstore API (found: https://discord.gg/Pb6bVMnFb2)
[INFO] Method 2: Extracting from README content
[INFO] Method 2: Found GitHub URL in README
[INFO] Source URL: https://github.com/AzumattDev/WardIsLove
```

### Method 3: GitHub Search Required
**Mods where GitHub URL must be discovered via search**

| Mod ID | Website URL | Expected Search Result | Test Command |
|--------|-------------|----------------------|--------------|
| `RandyKnapp-EquipmentAndQuickSlots` | `https://discord.gg/...` | `https://github.com/RandyKnapp/ValheimMods` | `getClientSideMods --filter-mod "RandyKnapp-EquipmentAndQuickSlots"` |
| `Nexus-FarmGrid` | `https://www.nexusmods.com/valheim/mods/449` | *(May find via search)* | `getClientSideMods --filter-mod "Nexus-FarmGrid"` |

**Expected Log Output:**
```
[INFO] Discovering source URL for RandyKnapp-EquipmentAndQuickSlots
[INFO] Method 1: No GitHub URL in Thunderstore API
[INFO] Method 2: No GitHub URL found in README
[INFO] Method 3: Searching GitHub API for "EquipmentAndQuickSlots valheim"
[INFO] Method 3: Found potential match
[INFO] Source URL: https://github.com/RandyKnapp/ValheimMods
```

### Method 4: No GitHub URL Available
**Mods where no GitHub URL can be found**

| Mod ID | Website URL | Expected Result | Test Command |
|--------|-------------|----------------|--------------|
| `OdinPlus-OdinTracker` | *(empty)* | `null` | `getClientSideMods --filter-mod "OdinPlus-OdinTracker"` |
| `Digitalroot-Digitalroots_Slope_Combat_Assistance` | `https://discord.gg/...` | `null` | `getClientSideMods --filter-mod "Digitalroot-Digitalroots_Slope_Combat_Assistance"` |

**Expected Log Output:**
```
[INFO] Discovering source URL for OdinPlus-OdinTracker
[INFO] Method 1: No GitHub URL in Thunderstore API
[INFO] Method 2: No GitHub URL found in README
[INFO] Method 3: No results from GitHub search
[INFO] Method 4: No GitHub URL found for author's other mods
[INFO] Source URL: null
```

## User Experience

### Default Progress Display
```
Working on mod: [ValheimModding-Jotunn]
Status: Getting GitHub URL (throttled)
Result of mod source repo: https://github.com/Valheim-Modding/Jotunn

Working on mod: [Azumatt-WardIsLove]
Status: Getting GitHub URL (throttled)
Result of mod source repo: https://github.com/AzumattDev/WardIsLove
```

### Silent Mode for LLMs
```bash
# Silent mode - only JSON output, no progress messages
getClientSideMods --silent --format json
```

## Logging Configuration

### Log Levels
```bash
# Verbose logging (for debugging)
getClientSideMods --log-level debug

# Info logging (shows method attempts)
getClientSideMods --log-level info

# Default: Progress display only (no logs)
getClientSideMods

# Silent mode (no output except results)
getClientSideMods --silent
```

### Log Format
```
[TIMESTAMP] [LEVEL] [METHOD] Message
```

Example:
```
[2024-01-25 10:30:45] [INFO] [Method 2] Extracting from README content
```

## Performance Acceptance Criteria

### Speed Requirements
- Method 1: < 0.1s per mod (already fetched)
- Method 2: < 0.5s per mod
- Method 3: < 1.0s per mod (respecting rate limits)
- Method 4: < 2.0s per mod
- **API Throttling**: 300ms delay between GitHub API calls
- **Total for 50 mods**: < 30 seconds with caching

### User Experience Requirements
- **Default Progress Display**: Shows current mod being processed
- **Quiet Default Logging**: No verbose logs unless requested
- **Throttle Indication**: Shows "(throttled)" when rate limiting active
- **Clear Results**: Shows source URL result for each mod
- **Silent Mode**: Available for programmatic/LLM usage

### Accuracy Requirements
- Method 1: 100% accuracy (direct from API)
- Method 2: > 95% accuracy (validate GitHub URLs)
- Method 3: > 80% accuracy (verify repository exists)
- Overall: > 85% of mods with GitHub repos should be discovered

### Success Criteria
1. **AI Optimization**: Default mode returns minimal data (~50KB)
2. **Progressive Enhancement**: --with-source flag enables full discovery
3. **Silent Mode**: Clean JSON output for programmatic usage
4. **Progress Display**: Human-friendly progress updates by default
5. **Rate Limiting**: 300ms throttle prevents API abuse
6. **Frontmatter Documentation**: Tool includes AI usage guide in source
7. **Profile Support**: --profile flag reads from Windows r2modman profiles
8. **Alphabetical Sorting**: All output sorted by full_name
9. **Minimal Mode**: --minimal reduces output by 77%

## Integration Test Script

```bash
#!/bin/bash
# test_source_discovery.sh

# Test each method with known cases
test_method_1() {
    echo "Testing Method 1: Direct API"
    result=$(getClientSideMods --filter-mod "ValheimModding-Jotunn" --silent --format json | jq -r '.mods[0].source_url')
    [[ "$result" == "https://github.com/Valheim-Modding/Jotunn" ]] && echo "✓ PASS" || echo "✗ FAIL: $result"
}

test_method_2() {
    echo "Testing Method 2: README Extraction"
    result=$(getClientSideMods --filter-mod "Azumatt-WardIsLove" --silent --format json | jq -r '.mods[0].source_url')
    [[ "$result" == "https://github.com/AzumattDev/WardIsLove" ]] && echo "✓ PASS" || echo "✗ FAIL: $result"
}

test_method_3() {
    echo "Testing Method 3: GitHub Search"
    result=$(getClientSideMods --filter-mod "RandyKnapp-EquipmentAndQuickSlots" --silent --format json | jq -r '.mods[0].source_url')
    [[ "$result" =~ github\.com ]] && echo "✓ PASS" || echo "✗ FAIL: $result"
}

test_method_4() {
    echo "Testing Method 4: No URL Available"
    result=$(getClientSideMods --filter-mod "OdinPlus-OdinTracker" --silent --format json | jq -r '.mods[0].source_url')
    [[ "$result" == "null" ]] && echo "✓ PASS" || echo "✗ FAIL: $result"
}

# Run all tests
test_method_1
test_method_2
test_method_3
test_method_4
```

## Cache Validation Test

```bash
# First run - populate cache
time getClientSideMods --silent --format json > first_run.json

# Second run - should be much faster
time getClientSideMods --silent --format json > second_run.json

# Verify cache was used
diff first_run.json second_run.json || echo "Results match"

# Force refresh
getClientSideMods --refresh-source-urls --silent --format json > refreshed.json
```

## Edge Cases to Test

1. **Malformed URLs**: Ensure validation catches invalid GitHub URLs
2. **Rate Limiting**: Verify graceful handling when GitHub API is rate limited
3. **Network Failures**: Test offline mode with cached data
4. **Multiple GitHub URLs**: Ensure correct repo is selected from multiple mentions
5. **Non-GitHub Source URLs**: Handle GitLab, Bitbucket, etc. appropriately