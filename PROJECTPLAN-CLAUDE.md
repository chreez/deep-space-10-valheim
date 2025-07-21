# 🚀 Project Plan: deep.space.10 Agent Orchestration System

```
╔══════════════════════════════════════════════════════════════╗
║    ·  · ✦  P R O J E C T   P L A N   M A T R I X  ✦ ·  ·   ║
║           Agent Coordination for Space Vikings               ║
╚══════════════════════════════════════════════════════════════╝
```

## ▪ MISSION OVERVIEW

This document provides structured instructions for Claude agents to complete deep.space.10 project tasks with minimal context overhead. Each phase includes specific context files and clear deliverables for autonomous agent execution.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## ▪ AGENT EXECUTION PROTOCOL

### ◆ Context File System
- **PRD**: `docs/prd.md` - Core architecture and vision
- **Style Guide**: Extract from PRD sections 🎨 Branding & Style Guidelines  
- **Docker Reference**: `docs/lloesche-valheim-server-docker-README.md`
- **Current Server Control**: `scripts/server_control.sh`
- **Mod Spec**: `docs/spec/archive/valheim-mod-support-v1.md`

### ◆ Agent Invocation Format
```bash
# Template for agent invocation
Task("<task_description>", prompt="""
<context_files>
- File: <filename> 
  Purpose: <why_this_file_is_needed>
</context_files>

<task_specifics>
Your mission: <specific_deliverable>
Requirements: <bullet_points>
Style: <viking_space_theme_requirements>
</task_specifics>

Context: <additional_context_if_needed>
""")
```

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## ▪ PHASE BREAKDOWN

### Phase 1: Documentation Foundation ✅ [COMPLETED]
**Status**: All tasks completed successfully
- ✅ README.md updated with Viking space theme
- ✅ PLACEHOLDER modpack setup guide added
- ✅ lloesche/valheim-server-docker README downloaded
- ✅ Core server control tool rewritten

### Phase 2: Server Control Optimization ✅ [COMPLETED]  
**Status**: Unified tool implemented
- ✅ Single server_control.sh with 3 core commands
- ✅ Docker-based health monitoring
- ✅ Deploy via sync_windows_wsl atomic tool
- ✅ Headless container restart functionality

### Phase 3: Modpack Distribution System [PENDING]
**Agent Context Required**:
- `docs/prd.md` (sections: Package Contents, Implementation Phases)
- `scripts/build_modpack.py` (current implementation)
- `src/modpack/` directory structure

**Agent Task**:
```bash
Task("Enhance modpack distribution", prompt="""
<context_files>
- File: docs/prd.md 
  Purpose: Understand modpack architecture and distribution requirements
- File: scripts/build_modpack.py
  Purpose: Current build system to enhance/modernize
- Directory: src/modpack/
  Purpose: Source files and structure for distribution
</context_files>

<task_specifics>
Your mission: Modernize modpack build and distribution system
Requirements:
- Update build_modpack.py to follow Viking theme UI
- Implement atomic download helper for BepInEx mods  
- Create manifest.json validator
- Add checksum verification for integrity
- Update to match server_control.sh style and output format
Style: Viking space theme with [OK] ✓, [!!] ▲, [XX] ✗ indicators
</task_specifics>

Context: Focus on simplicity and reliability for end users
""")
```

### Phase 4: Testing & Validation Framework [PENDING]
**Agent Context Required**:
- `tests/` directory (all Python test files)
- `scripts/server_control.sh` (new implementation)
- `docs/prd.md` (Testing Requirements section)

**Agent Task**:
```bash
Task("Update testing framework", prompt="""
<context_files>
- Directory: tests/
  Purpose: Existing test framework to modernize
- File: scripts/server_control.sh
  Purpose: New server control implementation to test
- File: docs/prd.md
  Purpose: Testing requirements and coverage goals
</context_files>

<task_specifics>
Your mission: Modernize test suite for Docker-based architecture
Requirements:
- Update tests to use Docker container validation
- Remove Python health_check.py dependencies  
- Test server_control.sh three core commands
- Add BepInEx mod loading verification tests
- Implement integration tests for sync_windows_wsl
Style: Viking theme output, clear pass/fail indicators
</task_specifics>

Context: Replace legacy Python-based testing with Docker-native approach
""")
```

### Phase 5: Configuration Management [PENDING]
**Agent Context Required**:
- `config/` directory structure
- `docs/gslt-token-guide.md` (GSLT setup)
- `.env` file patterns from Docker examples

**Agent Task**:
```bash
Task("Streamline configuration management", prompt="""
<context_files>
- Directory: config/
  Purpose: Current configuration structure
- File: docs/gslt-token-guide.md
  Purpose: GSLT token setup process
- File: scripts/server_control.sh
  Purpose: Environment variable usage patterns
</context_files>

<task_specifics>
Your mission: Create unified configuration system
Requirements:
- Consolidate all config into .env file approach
- Create config validation in server_control.sh
- Add setup wizard for first-time configuration
- Document all required environment variables
- Add .env.template with examples
Style: Viking theme with clear validation messages
</task_specifics>

Context: Simplify setup process for Space Vikings
""")
```

### Phase 6: CI/CD Pipeline Modernization [PENDING]
**Agent Context Required**:
- `.github/workflows/` directory
- `docs/prd.md` (CI/CD Pipeline section)
- Current GitHub Actions configuration

**Agent Task**:
```bash
Task("Update CI/CD for Docker architecture", prompt="""
<context_files>
- Directory: .github/workflows/
  Purpose: Current GitHub Actions workflows
- File: docs/prd.md
  Purpose: CI/CD requirements and pipeline goals
- File: scripts/server_control.sh
  Purpose: New deployment and testing interface
</context_files>

<task_specifics>
Your mission: Modernize CI/CD for Docker-first approach
Requirements:
- Update workflows to use server_control.sh commands
- Add Docker container testing in CI
- Implement automated modpack building
- Add deployment validation steps
- Remove Python dependencies from CI pipeline
Style: Viking theme in workflow names and descriptions
</task_specifics>

Context: Align automation with new simplified architecture
""")
```

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## ▪ AGENT COORDINATION BEST PRACTICES

### ◆ Context Minimization Strategy
1. **Pre-read required files** - Agents should read specified context files first
2. **Focus on deliverables** - Each task has specific, measurable outputs
3. **Style consistency** - All outputs must follow Viking space theme
4. **Atomic operations** - Each phase can be completed independently

### ◆ Handoff Protocol
```bash
# Between agent sessions:
1. Check completion status of previous phase
2. Validate deliverables match specifications
3. Update this project plan with [COMPLETED] status
4. Note any deviations or additional requirements discovered
```

### ◆ Quality Gates
- All Viking theme elements must be present
- Docker-first approach maintained throughout
- No new Python dependencies introduced
- Atomic tool integration preserved

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## ▪ VALIDATION CHECKLIST

### ◆ Phase Completion Criteria
- [ ] Phase 3: Modpack system follows server_control.sh style
- [ ] Phase 4: Tests validate Docker containers directly  
- [ ] Phase 5: Single .env configuration approach
- [ ] Phase 6: CI/CD uses server_control.sh commands

### ◆ System Integration Tests
- [ ] `./scripts/server_control.sh health` works end-to-end
- [ ] `./scripts/server_control.sh deploy` uses sync_windows_wsl  
- [ ] `./scripts/server_control.sh restart` creates headless container
- [ ] All outputs follow Viking space theme consistently

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## ▪ EMERGENCY PROTOCOLS

### ◆ Agent Context Overload
If agent requires too many context files:
1. Split task into smaller phases
2. Create intermediate summary documents
3. Use previous agent outputs as context instead of raw files

### ◆ Style Drift Prevention
Include this validation in every agent prompt:
```
Validation: Ensure all output uses:
- [OK] ✓ for success
- [!!] ▲ for warnings  
- [XX] ✗ for errors
- [..] ◦ for progress
- ▸ for details/examples
- ◆ for sections
- ▪ for major headings
- ━ for dividers
```

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

```
[ PROJECT PLAN COMPLETE ]

           ·  · ✦  Agent Coordination Matrix  ✦ ·  ·
             For Space Vikings Across the Void

              Autonomous Task Execution Protocol
                      deep.space.10 Command
```