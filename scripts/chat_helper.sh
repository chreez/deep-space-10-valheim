#!/bin/bash

echo "╔══════════════════════════════════════════════╗"
echo "║      Valheim Chat Helper Assistant           ║"
echo "║    Manual Trigger Question/Answer System     ║"
echo "╚══════════════════════════════════════════════╝"

# Configuration
REMOTE_HOST="192.168.1.236"
REMOTE_USER="chris"
SSH_CMD="$HOME/.dotfiles/bin/ssh_windows_wsl"
CONTAINER_NAME="valheim-server"

# Game knowledge base
declare -A HINTS=(
    ["pickaxe"]="First craft a workbench, then look for the Antler Pickaxe recipe (requires Hard Antlers from Eikthyr)"
    ["bronze"]="Combine 2 Copper + 1 Tin at the Forge to make Bronze"
    ["iron"]="Iron is found in Muddy Scrap Piles in the Swamp biome crypts"
    ["portal"]="Portals need Fine Wood, Greydwarf Eyes, and Surtling Cores. Both sides need the same tag!"
    ["boar"]="Drop mushrooms, raspberries, or blueberries near boars to tame them. Stay hidden!"
    ["cart"]="Carts need Bronze Nails and a Workbench nearby. They're great for hauling ore!"
    ["comfort"]="Add different furniture near your bed to increase comfort level and rested bonus duration"
    ["honey"]="Find beehives in abandoned houses. Break them for Queen Bees to start your own hives"
    ["sailing"]="Hold backwards (S) to lower sails and stop. Use rudder (A/D) to turn"
)

# Function to monitor chat
monitor_chat() {
    echo ""
    echo "▪ MONITORING CHAT MESSAGES"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "[..] ◦ Watching for recent questions..."
    echo ""
    
    # Get last 30 lines of chat
    CHAT_LOGS=$($SSH_CMD --command "docker logs --tail 30 $CONTAINER_NAME 2>&1 | grep -E 'Say:|Got character' | tail -10")
    
    if [ -n "$CHAT_LOGS" ]; then
        echo "[OK] ✓ Recent chat messages:"
        echo "$CHAT_LOGS" | sed 's/^/    /'
        
        # Look for questions
        echo ""
        echo "[..] ◦ Detected questions:"
        echo "$CHAT_LOGS" | grep -iE '\?|how|where|what|help' | sed 's/^/    > /'
    else
        echo "[!!] ▲ No recent chat messages found"
    fi
}

# Function to suggest responses
suggest_response() {
    local KEYWORD=$1
    
    echo ""
    echo "▪ RESPONSE SUGGESTIONS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    if [ -z "$KEYWORD" ]; then
        echo "[!!] ▲ Usage: $0 suggest <keyword>"
        echo "Available topics:"
        for key in "${!HINTS[@]}"; do
            echo "  - $key"
        done
        return
    fi
    
    # Search for matching hints
    local FOUND=false
    for key in "${!HINTS[@]}"; do
        if [[ "$KEYWORD" == *"$key"* ]] || [[ "$key" == *"$KEYWORD"* ]]; then
            echo "[OK] ✓ Topic: $key"
            echo "▸ Suggested response:"
            echo "  \"${HINTS[$key]}\""
            echo ""
            FOUND=true
        fi
    done
    
    if [ "$FOUND" = false ]; then
        echo "[XX] ✗ No hints found for: $KEYWORD"
        echo "[!!] ▲ Add new hints to the knowledge base"
    fi
}

# Function to show response format
show_format() {
    echo ""
    echo "▪ IN-GAME RESPONSE FORMAT"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "As an admin in-game, you can type:"
    echo ""
    echo "Examples:"
    echo '  "Hey [Player], for pickaxe: craft workbench first, then Antler Pickaxe needs Hard Antlers from Eikthyr"'
    echo '  "@[Player] Iron tip: Check Swamp crypts for Muddy Scrap Piles!"'
    echo '  "Pro tip: Portals need matching tags on both sides :)"'
    echo ""
    echo "[!!] ▲ Keep responses friendly and hint-based (not full spoilers)"
}

# Function to add new hint
add_hint() {
    local TOPIC=$1
    shift
    local HINT="$@"
    
    if [ -z "$TOPIC" ] || [ -z "$HINT" ]; then
        echo "[XX] ✗ Usage: $0 add <topic> <hint text>"
        return
    fi
    
    echo ""
    echo "▪ ADDING NEW HINT"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "[..] ◦ Topic: $TOPIC"
    echo "[..] ◦ Hint: $HINT"
    echo ""
    echo "[!!] ▲ Add this to the HINTS array in the script:"
    echo "    [\"$TOPIC\"]=\"$HINT\""
}

# Main command handling
ACTION=${1:-"help"}

case "$ACTION" in
    "monitor")
        monitor_chat
        ;;
        
    "suggest")
        suggest_response "$2"
        ;;
        
    "format")
        show_format
        ;;
        
    "add")
        shift
        add_hint "$@"
        ;;
        
    "topics")
        echo ""
        echo "▪ AVAILABLE HELP TOPICS"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        for key in "${!HINTS[@]}"; do
            printf "%-15s - %s\n" "$key" "${HINTS[$key]:0:50}..."
        done
        ;;
        
    "help"|"")
        echo ""
        echo "▪ CHAT HELPER COMMANDS"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "  monitor       - Show recent chat messages and questions"
        echo "  suggest <kw>  - Get response suggestions for keyword"
        echo "  topics        - List all available help topics"
        echo "  format        - Show in-game response format examples"
        echo "  add           - Add new hint to knowledge base"
        echo ""
        echo "▸ Usage: $0 [command] [args]"
        echo "▸ Example: $0 suggest pickaxe"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "WORKFLOW:"
        echo "  1. Run 'monitor' to see recent questions"
        echo "  2. Run 'suggest <keyword>' for response ideas"
        echo "  3. Log into game as admin"
        echo "  4. Type helpful response in chat"
        ;;
        
    *)
        echo "[XX] ✗ Unknown command: '$ACTION'"
        echo "▸ Use '$0 help' to see available commands"
        exit 1
        ;;
esac

echo ""
echo "[ TRANSMISSION END ]"