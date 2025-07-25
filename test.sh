#!/bin/bash

# Check multiple popular Valheim mods for GitHub URLs

set -euo pipefail

# List of popular mods to check
MODS=(
    "ValheimModding-Jotunn"
    "denikson-BepInExPack_Valheim"
    "Azumatt-AAA_Crafting"
    "Vapok-AdventureBackpacks"
    "RandyKnapp-EpicLoot"
    "Smoothbrain-CreatureLevelAndLootControl"
    "ValheimModding-HookGenPatcher"
    "OdinPlus-OdinTracker"
    "Advize-PlantEverything"
    "MSchmoecker-MultiUserChest"
)

echo "=== Checking website_urls for popular Valheim mods ==="
echo

for MOD_ID in "${MODS[@]}"; do
    URL=$(curl -s "https://thunderstore.io/c/valheim/api/v1/package/" | \
          jq -r ".[] | select(.full_name==\"${MOD_ID}\") | .versions[0].website_url // \"not found\"" 2>/dev/null || echo "error")
    
    printf "%-45s %s\n" "$MOD_ID:" "$URL"
done

echo
echo "=== Mods with GitHub URLs ==="
echo

for MOD_ID in "${MODS[@]}"; do
    URL=$(curl -s "https://thunderstore.io/c/valheim/api/v1/package/" | \
          jq -r ".[] | select(.full_name==\"${MOD_ID}\") | .versions[0].website_url // \"\"" 2>/dev/null || echo "")
    
    if [[ "$URL" == *"github"* ]]; then
        printf "%-45s %s\n" "$MOD_ID:" "$URL"
    fi
done