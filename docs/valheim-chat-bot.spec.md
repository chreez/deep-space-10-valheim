# Valheim Chat Bot System Specification

**Version**: 1.0  
**Date**: 2025-01-23  
**Status**: Draft

## Executive Summary

The Valheim Chat Bot system provides AI-powered assistance to players through in-game chat monitoring and intelligent response generation. The system maintains conversation history, provides context-aware help, and integrates with modern AI APIs while respecting player privacy and server performance.

## System Goals

1. **Automated Assistance**: Provide helpful, contextual responses to player questions
2. **Conversation Memory**: Track player interactions for improved future responses
3. **Minimal Intrusion**: Operate without disrupting gameplay or server performance
4. **Flexible Architecture**: Support multiple chat capture methods and AI providers
5. **Admin Control**: Maintain server admin oversight of bot interactions

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        Valheim Server                           │
│  ┌─────────────────┐                    ┌──────────────────┐   │
│  │  Game Process   │ ──── Chat ───────> │ Chat Capture ???  │   │
│  └─────────────────┘      Events        └──────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                                                   │
                                                   │ Chat Data
                                                   ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Chat Bot System                            │
│  ┌─────────────────┐     ┌──────────────┐    ┌──────────────┐ │
│  │ Chat Monitor    │────>│ Message      │───>│ AI Response  │ │
│  │ (Heartbeat)     │     │ Processor    │    │ Generator    │ │
│  └─────────────────┘     └──────────────┘    └──────────────┘ │
│           │                      │                     │        │
│           ▼                      ▼                     ▼        │
│  ┌─────────────────┐     ┌──────────────┐    ┌──────────────┐ │
│  │ Player History  │     │ Game         │    │ Response     │ │
│  │ Database        │     │ Knowledge    │    │ Queue        │ │
│  └─────────────────┘     └──────────────┘    └──────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                                                   │
                                                   ▼
                                         ┌──────────────────┐
                                         │ Admin Interface  │
                                         │ (Manual/Auto)    │
                                         └──────────────────┘
```

## Component Specifications

### 1. Chat Capture Layer (Open Question)

**Purpose**: Extract player chat messages from the running Valheim server

**Potential Approaches**:
1. **Docker Log Parsing**
   - Parse container stdout/stderr
   - Pros: No server modifications needed
   - Cons: Fragile, dependent on log format

2. **BepInEx Server Plugin**
   - Custom plugin to intercept chat events
   - Pros: Direct access to chat events
   - Cons: Requires server-side mod development

3. **File-Based Logging**
   - Server mod writes chat to file
   - Pros: Simple, reliable
   - Cons: Requires server mod

4. **Network Packet Inspection**
   - Monitor UDP traffic for chat packets
   - Pros: No server modification
   - Cons: Complex, may break with updates

5. **RCON Integration**
   - Use RCON protocol if available
   - Pros: Standard protocol
   - Cons: Valheim RCON support unclear

**Decision Criteria**:
- Reliability and maintenance burden
- Server performance impact
- Ease of implementation
- Update resilience

### 2. Chat Monitor Service

**Functionality**:
- Heartbeat monitoring (configurable interval, default 5s)
- Message deduplication
- Player identification
- Timestamp tracking

**Implementation**:
```python
class ChatMonitor:
    def __init__(self, config):
        self.heartbeat_interval = config.get('heartbeat_interval', 5)
        self.processed_messages = set()
        self.last_check = datetime.now()
    
    def fetch_new_messages(self) -> List[ChatMessage]:
        # Implementation depends on chat capture method
        pass
```

### 3. Player History Database

**Schema**:
```sql
-- Player profiles
CREATE TABLE players (
    player_id TEXT PRIMARY KEY,  -- Steam ID or unique identifier
    player_name TEXT,
    first_seen TIMESTAMP,
    last_seen TIMESTAMP,
    total_messages INTEGER DEFAULT 0,
    preferences JSON  -- Store player-specific settings
);

-- Chat messages
CREATE TABLE messages (
    message_id INTEGER PRIMARY KEY AUTOINCREMENT,
    player_id TEXT,
    player_name TEXT,
    message TEXT,
    timestamp TIMESTAMP,
    processed BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (player_id) REFERENCES players(player_id)
);

-- Bot responses
CREATE TABLE responses (
    response_id INTEGER PRIMARY KEY AUTOINCREMENT,
    message_id INTEGER,
    player_id TEXT,
    response_text TEXT,
    response_type TEXT,  -- 'ai', 'fallback', 'error'
    ai_model TEXT,
    timestamp TIMESTAMP,
    delivered BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (message_id) REFERENCES messages(message_id),
    FOREIGN KEY (player_id) REFERENCES players(player_id)
);

-- Player context for better responses
CREATE TABLE player_context (
    context_id INTEGER PRIMARY KEY AUTOINCREMENT,
    player_id TEXT,
    context_type TEXT,  -- 'location', 'progress', 'interest'
    context_value TEXT,
    timestamp TIMESTAMP,
    FOREIGN KEY (player_id) REFERENCES players(player_id)
);
```

### 4. Message Processor

**Responsibilities**:
- Determine if message requires response
- Extract intent and keywords
- Load player conversation history
- Build context for AI

**Response Triggers**:
```python
QUESTION_INDICATORS = ['?', 'how', 'where', 'what', 'why', 'when', 'help']
BOT_MENTIONS = ['claude', 'bot', 'assistant', 'help']
GAME_KEYWORDS = [
    'pickaxe', 'bronze', 'iron', 'portal', 'boss',
    'tame', 'build', 'craft', 'sail', 'farm'
]

def should_respond(message: ChatMessage, player_history: List[ChatMessage]) -> bool:
    # Direct mention always triggers
    if any(mention in message.text.lower() for mention in BOT_MENTIONS):
        return True
    
    # Question detection
    if any(indicator in message.text.lower() for indicator in QUESTION_INDICATORS):
        return True
    
    # Keyword + confusion detection
    if any(keyword in message.text.lower() for keyword in GAME_KEYWORDS):
        if detect_confusion(message, player_history):
            return True
    
    return False
```

### 5. AI Response Generator

**Configuration**:
```python
class AIConfig:
    providers = ['claude', 'openai', 'fallback']
    
    claude_config = {
        'api_key': os.getenv('CLAUDE_API_KEY'),
        'model': 'claude-3-haiku-20240307',
        'max_tokens': 150,
        'temperature': 0.7
    }
    
    openai_config = {
        'api_key': os.getenv('OPENAI_API_KEY'),
        'model': 'gpt-3.5-turbo',
        'max_tokens': 150,
        'temperature': 0.7
    }
```

**Context Building**:
```python
def build_context(player_id: str, message: str) -> str:
    # Load last 10 messages from player
    history = get_player_history(player_id, limit=10)
    
    # Load player context (location, progress)
    context = get_player_context(player_id)
    
    # Build prompt
    prompt = f"""You are a helpful Viking assistant in Valheim.
    
Player Context:
- Previous conversations: {format_history(history)}
- Known progress: {context.get('progress', 'Unknown')}
- Current focus: {context.get('interest', 'General')}

Current Question: {message}

Provide a brief, helpful response (under 100 chars preferred).
Be encouraging and maintain Viking theme. Don't spoil discoveries."""
    
    return prompt
```

### 6. Game Knowledge Base

**Structure**:
```json
{
  "topics": {
    "pickaxe": {
      "keywords": ["pick", "mine", "antler", "copper"],
      "hints": [
        "Craft workbench first, then Antler Pickaxe needs Hard Antlers from Eikthyr!",
        "The first boss drops what you need for mining. Bring a bow!"
      ],
      "context": {
        "required_progress": "pre_eikthyr",
        "biome": "meadows"
      }
    },
    "bronze": {
      "keywords": ["bronze", "alloy", "copper", "tin"],
      "hints": [
        "2 Copper + 1 Tin at the Forge makes Bronze, young Viking!",
        "Tin is found near water in the Black Forest. Look for small rocks!"
      ],
      "context": {
        "required_progress": "post_eikthyr",
        "biome": "black_forest"
      }
    }
  },
  "progression": {
    "pre_eikthyr": ["workbench", "weapons", "food", "shelter"],
    "post_eikthyr": ["pickaxe", "mining", "bronze", "forge"],
    "post_elder": ["iron", "swamp", "crypts", "poison"]
  }
}
```

### 7. Response Delivery System

**Phase 1: Manual Admin Delivery**
- Log responses to file with formatting
- Admin dashboard shows pending responses
- Copy/paste interface for in-game delivery

**Phase 2: Semi-Automated**
- Web interface for one-click approval
- Response templates with placeholders
- Batch response management

**Phase 3: Fully Automated** (Future)
- Direct server integration
- RCON or custom mod for chat injection
- Rate limiting and spam prevention

## Data Privacy & Security

1. **Player Consent**
   - Server rules should mention chat monitoring
   - Option to opt-out via chat command

2. **Data Retention**
   - Messages older than 30 days auto-deleted
   - Player can request data deletion

3. **API Key Security**
   - Keys stored in .env file, never in code
   - Separate keys for dev/prod environments
   - Rate limiting to prevent abuse

## Performance Considerations

1. **Resource Usage**
   - SQLite for low memory footprint
   - Async processing for API calls
   - Configurable heartbeat interval

2. **Scalability**
   - Message queue for high-traffic servers
   - Caching for common responses
   - Database indexing on player_id, timestamp

## Configuration File

```env
# API Configuration
CLAUDE_API_KEY=your_key_here
OPENAI_API_KEY=your_key_here

# Bot Settings
BOT_NAME=Claude
HEARTBEAT_INTERVAL=5
RESPONSE_DELAY=2
MAX_RESPONSE_LENGTH=150

# Server Connection
SSH_HOST=192.168.1.236
SSH_USER=chris
CONTAINER_NAME=valheim-server

# Database
DB_PATH=./data/chat_history.db
DB_BACKUP_INTERVAL=86400

# Feature Flags
ENABLE_AI_RESPONSES=true
ENABLE_FALLBACK_RESPONSES=true
ENABLE_PLAYER_HISTORY=true
ENABLE_CONTEXT_TRACKING=true
```

## Implementation Phases

### Phase 1: MVP (Week 1)
- [ ] Basic chat monitoring (Docker logs)
- [ ] SQLite database setup
- [ ] Simple keyword-based responses
- [ ] Manual response delivery

### Phase 2: AI Integration (Week 2)
- [ ] Claude/OpenAI API integration
- [ ] Player history tracking
- [ ] Context-aware responses
- [ ] Admin dashboard

### Phase 3: Enhanced Features (Week 3-4)
- [ ] Improved chat capture method
- [ ] Advanced context tracking
- [ ] Response analytics
- [ ] Performance optimization

### Phase 4: Automation (Future)
- [ ] Server-side integration
- [ ] Auto-response capability
- [ ] Multi-language support
- [ ] Plugin ecosystem

## Open Questions

1. **Chat Capture Method**
   - Which approach provides best reliability vs complexity?
   - Can we develop a lightweight BepInEx plugin?
   - Is there an existing mod we can leverage?

2. **Response Delivery**
   - Is RCON available in current Valheim version?
   - Can we inject chat via server console?
   - Should we build a companion client mod?

3. **Scaling Concerns**
   - How many concurrent players expected?
   - Should we implement response rate limiting?
   - Cloud deployment vs local hosting?

4. **Legal/Ethical**
   - Terms of service compliance?
   - Player data handling regulations?
   - Opt-in vs opt-out approach?

## Success Metrics

1. **Response Quality**
   - Player satisfaction (manual feedback)
   - Response relevance score
   - Follow-up question rate

2. **System Performance**
   - Response latency < 3 seconds
   - Uptime > 99%
   - Memory usage < 512MB

3. **Adoption**
   - % of players interacting with bot
   - Questions answered per day
   - Repeat usage rate

## Conclusion

This specification outlines a flexible, scalable chat bot system for Valheim servers. The modular architecture allows for iterative development while keeping critical decisions (like chat capture method) open for optimal implementation based on testing and requirements.

The focus on player history and context-aware responses will provide a superior experience compared to simple keyword matching, while the phased implementation approach ensures quick delivery of value with room for enhancement.