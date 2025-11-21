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
│   │   ├── session-closer.md      # Session closeout automation agent
│   │   ├── code-reviewer.md       # Multi-AI code review orchestration
│   │   ├── security-analyzer.md   # Security & compliance auditing
│   │   ├── optimizer.md           # Performance optimization analysis
│   │   ├── test-runner.md         # Test execution and coverage analysis
│   │   └── doc-generator.md       # Documentation generation and maintenance
│   │
│   └── commands/                   # Custom slash commands
│       ├── closeout.md             # /closeout command definition
│       ├── review.md               # /review command definition
│       ├── security-audit.md       # /security-audit command definition
│       ├── optimize.md             # /optimize command definition
│       ├── test.md                 # /test command definition
│       └── document.md             # /document command definition
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
├── ARCHITECTURE.md                 # This file - workspace documentation
│
├── ROADMAP.md                      # Implementation roadmap for n8n integration
│
└── n8n-docker/                     # (Planned) n8n workflow automation
    ├── docker-compose.yml          # n8n container configuration
    ├── .env                        # Environment variables (not in git)
    ├── n8n-mcp-server.js          # MCP server for Claude Code integration
    └── workflows/                  # n8n workflow exports (JSON)
        └── multi-ai-review.json    # Multi-AI orchestration workflow
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

**`ROADMAP.md`**
- Implementation guide for n8n integration
- **Contains:**
  - Docker installation steps for WSL Ubuntu
  - n8n deployment configuration
  - AI orchestration workflow design
  - MCP server setup instructions
  - Security considerations for regulated environments
  - Troubleshooting guide
- Detailed roadmap for next development phase

**`n8n-docker/`** (Planned Infrastructure)
- Docker-based n8n workflow automation platform
- **Purpose:** Visual workflow orchestration + MCP server integration
- **Components:**
  - `docker-compose.yml`: Container orchestration config
  - `.env`: Secure credential storage (excluded from git)
  - `n8n-mcp-server.js`: Bridge between Claude Code and n8n
  - `workflows/`: Exportable workflow definitions (JSON)
- **Integration:** Provides visual representation of multi-AI coordination
- **Benefits:** Living diagram of architecture + functional automation

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

**`.claude/agents/code-reviewer.md`**
- **Purpose:** Multi-AI code review orchestration
- **Responsibilities:**
  1. Code discovery and analysis (architecture, security, performance)
  2. Multi-perspective review coordination
  3. Findings aggregation by priority (P0/P1/P2)
  4. Actionable feedback generation
- **Invocation:** `/review` slash command
- **Benefits:**
  - Comprehensive code analysis from multiple angles
  - Structured reports with line-number references
  - Healthcare/compliance-aware reviews (HIPAA, SOC 2)

**`.claude/agents/security-analyzer.md`**
- **Purpose:** Security auditing and compliance analysis
- **Responsibilities:**
  1. OWASP Top 10 vulnerability scanning
  2. HIPAA technical safeguards verification
  3. SOC 2 and NIST CSF control mapping
  4. PHI/PII exposure detection
  5. Hardcoded credential scanning
- **Invocation:** `/security-audit` slash command
- **Benefits:**
  - Healthcare-focused security posture assessment
  - Compliance gap identification
  - Severity-based prioritization (P0-P3)
  - Remediation roadmap generation

**`.claude/agents/optimizer.md`**
- **Purpose:** Performance optimization analysis
- **Responsibilities:**
  1. Algorithmic complexity analysis (Big O)
  2. Database query optimization (N+1 detection)
  3. Caching opportunity identification
  4. Resource utilization assessment
  5. Code-level optimization suggestions
- **Invocation:** `/optimize` slash command
- **Benefits:**
  - Measurable performance improvement estimates
  - Before/after code examples
  - Impact-based prioritization (high/medium/low)
  - Balance between performance and readability

**`.claude/agents/test-runner.md`**
- **Purpose:** Test execution and coverage analysis
- **Responsibilities:**
  1. Test framework detection and execution
  2. Coverage percentage calculation
  3. Failure categorization and root cause analysis
  4. Test quality assessment
  5. Gap identification and test suggestions
- **Invocation:** `/test` slash command
- **Benefits:**
  - Comprehensive test reporting
  - Healthcare-critical code coverage verification
  - Flaky test detection
  - Test improvement recommendations

**`.claude/agents/doc-generator.md`**
- **Purpose:** Documentation generation and maintenance
- **Responsibilities:**
  1. Documentation discovery and gap analysis
  2. README.md generation and updates
  3. API documentation creation (docstrings, JSDoc)
  4. Architecture diagram generation (ASCII, Mermaid)
  5. CHANGELOG.md maintenance
  6. Code comment quality assessment
  7. HIPAA/compliance documentation verification
- **Invocation:** `/document` slash command
- **Benefits:**
  - Comprehensive project documentation
  - Client-ready professional formatting
  - Compliance documentation (HIPAA §164.312 references)
  - Onboarding and knowledge transfer support
  - Documentation gap identification

### Custom Commands

**`.claude/commands/closeout.md`**
- **Command:** `/closeout`
- **Function:** Delegates to session-closer agent
- **Workflow:**
  1. User types `/closeout`
  2. Command reads session-closer.md configuration
  3. Agent executes full closeout procedure autonomously
  4. Returns comprehensive session report

**`.claude/commands/review.md`**
- **Command:** `/review`
- **Function:** Delegates to code-reviewer agent
- **Usage:** `/review` or `/review src/` or `/review *.py`
- **Output:** Structured code review with architecture, security, and performance findings

**`.claude/commands/security-audit.md`**
- **Command:** `/security-audit`
- **Function:** Delegates to security-analyzer agent
- **Usage:** `/security-audit`
- **Output:** Security audit report with OWASP, HIPAA, SOC 2, and NIST CSF findings

**`.claude/commands/optimize.md`**
- **Command:** `/optimize`
- **Function:** Delegates to optimizer agent
- **Usage:** `/optimize`
- **Output:** Performance analysis with high/medium/low impact optimization opportunities

**`.claude/commands/test.md`**
- **Command:** `/test`
- **Function:** Delegates to test-runner agent
- **Usage:** `/test`
- **Output:** Test execution results with coverage analysis and improvement recommendations

**`.claude/commands/document.md`**
- **Command:** `/document`
- **Function:** Delegates to doc-generator agent
- **Usage:** `/document`
- **Output:** Documentation generation report with README, API docs, architecture diagrams, and gap analysis

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
| **Specialized Agents** | | | |
| `.claude/agents/session-closer.md` | Agent Config | Session closeout automation | ~200 lines |
| `.claude/agents/code-reviewer.md` | Agent Config | Multi-AI code review | ~300 lines |
| `.claude/agents/security-analyzer.md` | Agent Config | Security & compliance audit | ~450 lines |
| `.claude/agents/optimizer.md` | Agent Config | Performance optimization | ~350 lines |
| `.claude/agents/test-runner.md` | Agent Config | Test execution & coverage | ~400 lines |
| `.claude/agents/doc-generator.md` | Agent Config | Documentation generation | ~500 lines |
| **Slash Commands** | | | |
| `.claude/commands/closeout.md` | Slash Command | `/closeout` trigger | ~30 lines |
| `.claude/commands/review.md` | Slash Command | `/review` trigger | ~25 lines |
| `.claude/commands/security-audit.md` | Slash Command | `/security-audit` trigger | ~25 lines |
| `.claude/commands/optimize.md` | Slash Command | `/optimize` trigger | ~25 lines |
| `.claude/commands/test.md` | Slash Command | `/test` trigger | ~25 lines |
| `.claude/commands/document.md` | Slash Command | `/document` trigger | ~25 lines |
| **Core Files** | | | |
| `agents.md` | Documentation | Master coordination | ~300 lines |
| `claude.md` | Symlink | Claude context | → agents.md |
| `gemini.md` | Symlink | Gemini context | → agents.md |
| `system-check.sh` | Script | Diagnostics | ~300 lines |
| `ARCHITECTURE.md` | Documentation | Workspace structure | ~400 lines |
| `ROADMAP.md` | Documentation | n8n integration guide | ~800 lines |
| `.gitignore` | Config | Git exclusions | ~5 lines |
| `n8n-docker/` | Directory (Planned) | Workflow automation | TBD |

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

### n8n Workflow Integration (Planned)

**Overview:**
Integrate n8n as a visual workflow orchestration layer with MCP server connectivity.

**Implementation Steps:**
1. **Docker Setup**
   - Install Docker in WSL Ubuntu
   - Verify system requirements (4GB RAM, 10GB disk)
   - Configure Docker service auto-start

2. **n8n Deployment**
   - Create `n8n-docker/` directory
   - Configure `docker-compose.yml` with security settings
   - Set up `.env` for credentials (add to .gitignore)
   - Deploy container: `docker compose up -d`
   - Access UI: `http://localhost:5678`

3. **Build AI Orchestration Workflows**
   - Create webhook-triggered workflows
   - Integrate Claude, Gemini, and Codex APIs
   - Add aggregation and error handling
   - Export workflows to `workflows/` directory
   - Version control workflow JSON files

4. **MCP Server Configuration**
   - Create `n8n-mcp-server.js` proxy server
   - Configure Claude Code MCP settings
   - Test workflow invocation from Claude Code
   - Document available workflows

5. **Visual Enhancement**
   - Organize workflow canvas with clear layout
   - Add documentation sticky notes
   - Color-code nodes by function
   - Screenshot workflows for documentation

**Security Considerations:**
- Change default n8n passwords
- Store API keys in environment variables only
- Never commit `.env` files to git
- Restrict n8n to localhost (127.0.0.1:5678)
- Regular backups of n8n data volume
- Audit trail via execution history

**Benefits:**
- Visual representation of multi-AI workflows
- Reusable automation patterns
- Direct integration with Claude Code via MCP
- Execution monitoring and logging
- Easy workflow modifications without code changes

**Reference:** See `ROADMAP.md` for detailed implementation guide.

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
