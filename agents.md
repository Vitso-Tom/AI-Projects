# Project: Multi-AI Terminal Workspace

## Overview
Learning and experimentation workspace for integrating multiple AI tools (Claude Code, Gemini CLI, Codex) into a unified terminal workflow.

## Primary User: Tom Vitso
- **Role**: Fractional CIO/CISO/CTO (Vitso consultancy)
- **Background**: CISSP, 20+ years in healthcare/regulated environments
- **Current Focus**: Learning AI tool integration for consulting work
- **Industries**: Healthcare, regulated (SOC 2, HIPAA, NIST, FDA)

## Environment
- **OS**: WSL Ubuntu
- **Location**: /home/temlock/ai-workspace
- **AI Tools**: Claude Code, Gemini CLI, Codex/OpenAI CLI
- **Version Control**: Git

## Workspace Goals
1. Learn terminal-based AI workflows
2. Understand multi-AI collaboration patterns
3. Develop reusable patterns for client engagements
4. Maintain security and privacy best practices
5. Build expertise to advise teams on AI adoption

## Standards
- **Security First**: No sensitive client data in this workspace
- **Documentation**: All decisions logged in context files
- **Version Control**: Regular commits to track learning
- **Context Sync**: Keep all three .md files aligned

## AI Assistant Guidelines
- This is a learning environment - explain clearly
- Relate examples to healthcare/security when relevant
- Focus on practical, production-ready patterns
- Consider MLSecOps and security implications

## Current Learning Focus
- Multi-AI terminal workflow setup
- Context file management across tools
- Agent delegation patterns
- Session management and automation
- Git-based audit trails

## Recent Learnings
_Log insights here as you work_

## Recent Milestones
- **2025-11-19**: Multi-AI workspace operational - Claude Code, Gemini CLI, and Codex all authenticated and reading context files

## Recent Milestones
- **2025-11-19**: Multi-AI workspace operational - Claude Code, Gemini CLI, and Codex all authenticated and reading context files
- **2025-11-19**: Implemented symlinks for context files - agents.md is master, claude.md and gemini.md are symbolic links for automatic synchronization

## Recent Learnings
- **Symlink verification (2025-11-19)**: All three AI tools successfully read through symlinks. Claude, Gemini, and Codex all demonstrate deep understanding of project context from single source file.

- **Multi-AI code review chain (2025-11-19)**: Successfully demonstrated collaborative workflow:
  - Claude: Created system-check.sh with colors and health monitoring
  - Gemini: Security review found no critical vulnerabilities, noted minor terminal escape consideration
  - Codex: Identified 6 optimization opportunities (defensive shell options, reducing subprocess overhead, better parsing)
  - Pattern validated: Each AI brings different perspective to same artifact

- **Cross-AI delegation research (2025-11-19)**: Explored delegation capabilities. Claude Code has /agents for internal sub-agents and /mcp for external tool connections. Need to research MCP server setup for cross-platform AI delegation (Claude → OpenAI). Next: Review NetworkChuck video to understand exact implementation pattern.

- **Codex optimization implementation (2025-11-20)**: Implemented all 6 optimization suggestions from Codex's code review:
  1. Added defensive shell options (`set -euo pipefail`) for error handling
  2. Replaced external commands (seq, awk, grep) with pure bash solutions
  3. Direct /proc/meminfo parsing instead of multiple `free` calls
  4. Process substitution for df parsing to avoid subshells
  5. Eliminated UUOC patterns (useless use of cat)
  6. Native string manipulation for path truncation
  - Result: More robust, efficient, portable script with fewer subprocess calls

- **Claude Code slash commands (2025-11-20)**: Created custom `/closeout` command for session management automation. Stored in `.claude/commands/closeout.md`. Pattern learned: Slash commands provide reusable workflows for repetitive tasks like session summaries, git operations, and documentation updates.

- **Specialized agent architecture (2025-11-20)**: Created session-closer agent to handle closeouts independently and preserve main orchestrator tokens. Pattern implemented:
  1. Agent definition stored in `.claude/agents/session-closer.md` with full responsibilities and procedures
  2. Slash command `/closeout` delegates to the specialized agent
  3. Agent reads its own config file for instructions (self-contained)
  4. Benefits: Token efficiency, reusability, separation of concerns
  - Architecture: Lightweight slash command → Task delegation → Autonomous specialized agent
  - Agent handles: context gathering, analysis, documentation updates, git operations, reporting
  - Pattern applicable to other specialized tasks: code review, testing, security analysis, optimization

- **Agent configuration refinement (2025-11-20)**: Updated session-closer agent documentation to use absolute file paths instead of relative paths. Changed references from `agents.md` to `/home/temlock/ai-workspace/agents.md`. Prevents path resolution errors when agent operates from different working directories. Small but important improvement for reliability in agent-based automation where cwd may vary between bash calls.

- **Architecture documentation (2025-11-20)**: Created comprehensive ARCHITECTURE.md with visual directory structure diagrams using ASCII tree art. Documents complete workspace layout including .claude/ configuration, symlink patterns, specialized agents, design principles, and token efficiency patterns. Provides single reference for understanding workspace organization and maintenance procedures.

- **Session-closer agent validation (2025-11-20)**: Successfully tested session-closer agent workflow. Agent autonomously read its configuration file, gathered context via parallel git operations, analyzed repository state, and executed closeout procedures. Validated the autonomous agent pattern: configuration-driven, self-contained, token-efficient. Agent correctly identified clean working tree and provided comprehensive session analysis. Pattern proves valuable for routine automation tasks while preserving main orchestrator context window.

- **Remote mobile access roadmap (2025-11-20)**: Designed Phase 3 architecture for secure remote workspace interaction from mobile devices. Dual-access pattern combining Tailscale mesh VPN (full SSH terminal access) with n8n webhook automation (quick browser-based commands). Key innovation: Zero-trust security model with no exposed public ports - all traffic routed through encrypted Tailscale mesh. Architecture supports future extensibility via Telegram bot integration. Security controls include mesh VPN, webhook auth tokens, rate limiting, MFA, and git-based audit trails. Pattern applicable to consulting: demonstrate remote AI orchestration capabilities to clients while maintaining enterprise security posture. Validates healthcare/regulated environment requirements.

## Next Session: n8n Integration

**Goal**: Build functional n8n workflow that provides both visual diagram AND working automation

**Planned Tasks**:
1. Install Docker in WSL Ubuntu
2. Deploy n8n container
3. Build AI orchestration workflow (Claude → Gemini → Codex delegation)
4. Configure as MCP server for Claude Code
5. Achieve beautiful n8n visual representation of architecture

**Expected Benefits**:
- Visual interface for multi-AI workflows
- Functional automation layer on top of existing architecture
- MCP server integration with Claude Code
- Reusable workflow patterns for client consulting
- Living diagram that mirrors ARCHITECTURE.md
- Monitoring and tracking of AI task delegation

**Integration Pattern**:
```
User Request → Claude Code → n8n Workflow Orchestrator
                                      ↓
                              ┌───────┼───────┐
                              ↓       ↓       ↓
                           Claude  Gemini  Codex
                              ↓       ↓       ↓
                              └───────┼───────┘
                                      ↓
                              Aggregated Result
```

**Reference**: See ROADMAP.md for detailed implementation steps

## Phase 3: Remote Mobile Access

**Goal**: Enable secure remote interaction with AI workspace from mobile devices

**Approach**: Tailscale + n8n webhooks for two access patterns:
1. **Direct CLI access** via Tailscale mesh VPN (full terminal from phone)
2. **Webhook-based task automation** (quick commands via mobile browser or future Telegram bot)

**Planned Tasks**:
1. Install Tailscale on WSL Ubuntu and mobile device
2. Configure secure mesh network
3. Test SSH access from phone to WSL
4. Set up n8n webhook authentication
5. Create mobile-friendly webhook endpoints for common tasks (system check, closeout, code review)

**Security Controls**:
- Tailscale zero-trust mesh network (no exposed public ports)
- n8n authentication tokens for webhook access
- Rate limiting on webhook endpoints
- Audit logging via git commits
- MFA on Tailscale account
- Device authorization and deauthorization controls

**Expected Benefits**:
- Access AI workspace from anywhere securely
- Run automation and workflows remotely
- Quick status checks from mobile browser
- Maintain security posture (zero-trust, encrypted mesh)
- Future extensibility: Telegram bot integration
- Consulting demo capability: show clients remote AI orchestration

**Architecture Pattern**:
```
Mobile Device (authorized on Tailscale)
    ↓
Tailscale Mesh VPN (encrypted tunnel)
    ↓
┌─────────────────────────────────┐
│  WSL Ubuntu (workspace)         │
│  ├─ SSH (full terminal access)  │
│  └─ n8n webhooks (automation)   │
└─────────────────────────────────┘
```

**Use Cases**:
- Quick `/closeout` from phone after session
- Run `system-check.sh` remotely
- Trigger multi-AI code review from mobile browser
- SSH in for full terminal access when needed
- Future: Telegram bot → n8n webhook → AI workflow

## Phase 4: Infrastructure as Code & Multi-Node Vision

**Goal**: Transform workspace into push-button deployable infrastructure

### Phase 4A - Containerization

**Objective**: Full workspace as orchestrated containers

**Implementation**:
- Create comprehensive `docker-compose.yml` orchestrating:
  - n8n workflow engine
  - Tailscale sidecar container
  - AI tool containers (where applicable)
  - Shared workspace volume
- Volume mount strategy for data persistence:
  - `/workspace` → AI workspace data
  - `n8n_data` → Workflow definitions and execution history
  - `tailscale_config` → VPN state and configuration
- Environment variable configuration:
  - `.env.template` for required variables
  - Secrets management pattern
  - API key injection
- **Result**: Single command deployment (`docker-compose up`)

### Phase 4B - Reproducibility

**Objective**: Enable deployment on fresh systems

**Implementation**:
- Installation scripts:
  - `setup-workspace.sh` - Full system bootstrap
  - `install-dependencies.sh` - Prerequisites (Docker, git, etc.)
  - `configure-environment.sh` - User-specific configuration
- Configuration templates:
  - `.env.template` for environment variables
  - `config.template.yml` for application settings
  - SSH key generation and Tailscale auth helpers
- Documentation for replication:
  - Step-by-step deployment guide
  - Prerequisites checklist
  - Troubleshooting common issues
  - Security hardening procedures

**Deliverables**:
- Clone repo → Run script → Workspace operational
- Configuration wizard for first-time setup
- Validation script to confirm successful deployment

### Phase 4C - Multi-Node Vision (Future)

**Objective**: Scalable, distributed AI infrastructure

**Architecture**:
```
┌──────────────────────────────────────────────────┐
│         Tailscale Mesh Network (overlay)         │
└──────────────────────────────────────────────────┘
         │              │              │
    ┌────┴───┐     ┌────┴───┐    ┌────┴───┐
    │ Node 1 │     │ Node 2 │    │ Node 3 │
    │ (Orch) │     │(Worker)│    │(Worker)│
    └────────┘     └────────┘    └────────┘
         │              │              │
    n8n Central    Claude Node    Gemini Node
    Orchestrator   + GPU (opt)    + Codex
```

**Implementation Strategy**:
- **Terraform modules** for infrastructure provisioning:
  - Cloud provider agnostic (AWS, Azure, GCP)
  - On-premises support (bare metal, Proxmox)
  - Automated network configuration
- **Distributed AI workers** across multiple systems:
  - Dedicated nodes for compute-intensive AI operations
  - GPU-enabled nodes for local model inference (future)
  - Resource allocation and load balancing
- **Centralized n8n orchestrator**:
  - Single source of truth for workflows
  - Delegates tasks to appropriate worker nodes
  - Aggregates results from distributed execution
- **Tailscale mesh** connecting all nodes:
  - Zero-configuration node discovery
  - Encrypted communication between nodes
  - NAT traversal for mixed environments (cloud + on-prem)
  - Access control lists (ACLs) for node-to-node permissions

**Use Cases**:
- **Healthcare Client Deployment**: Compliant, auditable AI workflows
  - On-premises deployment meets data residency requirements
  - Audit trail across all nodes
  - HIPAA-compliant architecture patterns
- **Scalable Processing**: Parallel AI task execution
  - Code review across large repositories
  - Batch document analysis
  - Multi-model inference for comparison
- **Development/Production Separation**:
  - Dev node for testing workflows
  - Production nodes for client work
  - Isolated environments with mesh connectivity

**Technology Stack**:
- **Terraform**: Infrastructure provisioning and state management
- **Ansible** (optional): Configuration management
- **Docker Swarm or Kubernetes**: Container orchestration
- **Tailscale**: Secure mesh networking
- **n8n**: Centralized workflow orchestration
- **Prometheus + Grafana** (optional): Monitoring and observability

**Expected Benefits**:
- Consulting-grade architecture ready for client presentations
- Client-deployable solution with minimal customization
- Fully documented infrastructure pattern (IaC)
- Scalability from single laptop to distributed cluster
- Compliance-ready audit trails and security controls
- Vendor-agnostic deployment model
- Professional service offering foundation

**Compliance Considerations**:
- SOC 2 Type II architecture patterns
- HIPAA technical safeguards alignment
- NIST Cybersecurity Framework mapping
- Audit logging at infrastructure and application layers
- Data encryption in transit and at rest
- Access control and authentication enforcement

---
**Implementation Note**: agents.md is the master file; claude.md and gemini.md are symbolic links
