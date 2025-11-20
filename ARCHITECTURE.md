# AI Workspace Architecture

This document provides a visual overview of the ai-workspace directory structure, showing the organization of configuration files, agent definitions, scripts, and documentation.

## Directory Structure

```
ai-workspace/
│
├── .git/                           # Git repository metadata
│   ├── hooks/                      # Git hooks (standard samples)
│   ├── objects/                    # Git object database
│   ├── refs/                       # Git references (branches, tags)
│   ├── logs/                       # Reference logs
│   ├── config                      # Repository configuration
│   ├── HEAD                        # Current branch pointer
│   └── index                       # Staging area index
│
├── .claude/                        # Claude Code configuration directory
│   │
│   ├── agents/                     # Specialized agent configurations
│   │   └── session-closer.md      # Session closeout automation agent
│   │
│   └── commands/                   # Custom slash commands
│       └── closeout.md             # /closeout command definition
│
├── agents.md                       # Master agent coordination document
│                                   # Contains: system context, agent roles,
│                                   # learning log, and coordination protocols
│
├── claude.md -> agents.md          # Symlink for Claude AI access
│                                   # Provides context without duplication
│
├── gemini.md -> agents.md          # Symlink for Google Gemini access
│                                   # Same context, different AI tool
│
├── system-check.sh                 # System diagnostic script (executable)
│                                   # Verifies: git, symlinks, permissions
│
├── .gitignore                      # Git ignore patterns
│
└── ARCHITECTURE.md                 # This file - workspace documentation
```

## Component Descriptions

### Configuration Directories

**`.claude/`**
- Claude Code configuration root
- Contains agent definitions and custom commands
- Enables workflow automation and extensibility

**`.claude/agents/`**
- Houses specialized agent configuration files
- Each agent is self-contained with specific responsibilities
- Agents are invoked via Task tool with subagent_type='general-purpose'

**`.claude/commands/`**
- Custom slash commands for Claude Code
- Commands are invoked with `/command-name` syntax
- Each .md file defines a command prompt/workflow

### Core Files

**`agents.md`** (Master Document)
- Central coordination hub for AI collaboration
- **Sections:**
  - System Context: Healthcare/DevOps consulting background
  - Agent Roles: Specialized capabilities per AI tool
  - Recent Learnings: Session-by-session knowledge accumulation
  - Quick Reference: Command patterns and best practices
- Single source of truth for agent coordination

**`claude.md` → `agents.md`** (Symlink)
- Provides Claude AI with access to master document
- Eliminates duplication and version drift
- Automatically stays in sync with agents.md

**`gemini.md` → `agents.md`** (Symlink)
- Provides Google Gemini with access to master document
- Enables consistent context across AI tools
- Same pattern as claude.md for maintainability

**`system-check.sh`** (Executable Script)
- Validates workspace configuration
- **Checks:**
  - Git repository status
  - Symlink integrity (claude.md, gemini.md)
  - File permissions
  - Directory structure
- Returns diagnostic information for troubleshooting

**`.gitignore`**
- Standard Git ignore patterns
- Excludes temporary files and system artifacts
- Keeps repository clean

### Specialized Agents

**`.claude/agents/session-closer.md`**
- **Purpose:** Automated session closeout procedures
- **Responsibilities:**
  1. Context gathering (git status, diffs, commits)
  2. Session analysis and accomplishment identification
  3. Learning extraction and documentation
  4. Update agents.md with new learnings
  5. Git commit and push operations
  6. Comprehensive session reporting
- **Invocation:** `/closeout` slash command
- **Benefits:**
  - Reduces token consumption (~18K vs 50K+)
  - Ensures consistent closeout procedures
  - Maintains audit trail

### Custom Commands

**`.claude/commands/closeout.md`**
- **Command:** `/closeout`
- **Function:** Delegates to session-closer agent
- **Workflow:**
  1. User types `/closeout`
  2. Command reads session-closer.md configuration
  3. Agent executes full closeout procedure autonomously
  4. Returns comprehensive session report

## Architecture Patterns

### Single Source of Truth (Symlinks)
```
agents.md (master)
    ↑           ↑
    │           │
claude.md   gemini.md
(symlink)   (symlink)
```

**Benefits:**
- No content duplication
- Atomic updates across all AI tools
- Reduced maintenance overhead
- Guaranteed consistency

### Specialized Agent Delegation
```
User → /closeout → closeout.md → Task Tool → session-closer agent
                                                      ↓
                                          session-closer.md (config)
                                                      ↓
                                          Autonomous execution
```

**Benefits:**
- Separation of concerns
- Token efficiency through delegation
- Reusable specialized behaviors
- Scalable architecture

### Learning Accumulation Loop
```
Session Work → Learnings → agents.md → Next Session Context
       ↑                                        ↓
       └────────────── Improved Efficiency ────┘
```

**Benefits:**
- Continuous improvement
- Context preservation across sessions
- Pattern recognition over time
- Reduced rework

## File Statistics

| File/Directory | Type | Purpose | Lines/Size |
|----------------|------|---------|------------|
| `.claude/agents/session-closer.md` | Agent Config | Session automation | ~200 lines |
| `.claude/commands/closeout.md` | Slash Command | Closeout trigger | ~30 lines |
| `agents.md` | Documentation | Master coordination | ~180 lines |
| `claude.md` | Symlink | Claude context | → agents.md |
| `gemini.md` | Symlink | Gemini context | → agents.md |
| `system-check.sh` | Script | Diagnostics | ~300 lines |
| `.gitignore` | Config | Git exclusions | ~5 lines |

## Design Principles

1. **DRY (Don't Repeat Yourself)**: Symlinks eliminate duplication
2. **Separation of Concerns**: Specialized agents for specific tasks
3. **Automation**: Slash commands and agents reduce manual work
4. **Documentation as Code**: Configuration files are self-documenting
5. **Version Control**: All changes tracked in Git with clear commit messages
6. **Token Efficiency**: Delegation reduces token consumption
7. **Scalability**: Architecture supports adding new agents and commands

## Extension Points

### Adding New Agents
1. Create `.claude/agents/new-agent-name.md`
2. Define agent responsibilities and procedures
3. Create corresponding slash command in `.claude/commands/`
4. Document in agents.md under "Recent Learnings"

### Adding New Slash Commands
1. Create `.claude/commands/command-name.md`
2. Define command prompt and workflow
3. Invoke with `/command-name`
4. Test and document behavior

### Adding AI Tool Support
1. Create new symlink: `ai-tool-name.md -> agents.md`
2. Verify symlink with `system-check.sh`
3. Test access from new AI tool
4. Document in agents.md

## Maintenance

### Regular Tasks
- Run `system-check.sh` to verify workspace integrity
- Review agents.md for outdated learnings
- Update agent configurations based on usage patterns
- Commit changes with descriptive messages
- Use `/closeout` at end of sessions

### Git Workflow
- Branch: `main` (primary development)
- Commit pattern: Descriptive messages with context
- Push frequency: After each significant change or session
- All commits include Claude Code attribution

## Token Efficiency

This architecture is designed for token efficiency:

- **Symlinks**: Share context without duplicating tokens
- **Agent Delegation**: Specialized agents use fewer tokens than main orchestrator
- **Learning Log**: Accumulated knowledge reduces repeated discovery
- **Automation**: Scripts handle repetitive tasks without token cost

**Example Savings:**
- Session closeout: 18K tokens (agent) vs 50K+ tokens (manual)
- Symlink context: ~180 lines vs 540 lines (3x duplication)

## Security & Permissions

```
File Permissions:
-rw-r--r--  agents.md, ARCHITECTURE.md, .gitignore
-rw-------  session-closer.md (private agent config)
-rwxr-xr-x  system-check.sh, closeout.md (executable)
lrwxrwxrwx  claude.md, gemini.md (symlinks)

Directory Permissions:
drwxr-xr-x  .claude/, .claude/agents/, .claude/commands/
```

**Rationale:**
- Agent configs are private (600) to prevent unauthorized access
- Scripts are executable (755) for direct invocation
- Documentation is world-readable (644) for collaboration
- Symlinks have standard permissions (777)

---

**Last Updated:** 2025-11-20
**Maintained By:** Claude Code + Human collaboration
**Version:** 1.0.0
