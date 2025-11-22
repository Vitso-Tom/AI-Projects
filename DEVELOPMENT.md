# DEVELOPMENT.md

This file provides stable development guidance for this workspace. For session history and context, see `agents.md` (accessed via `claude.md` and `gemini.md` symlinks).

## Purpose

This is a **reference guide** for development patterns, commands, and architecture rules in this AI agent orchestration workspace. Unlike `agents.md` which tracks evolving session history, this file contains stable instructions for how to work effectively in this repository.

## Repository Purpose

This is an AI agent orchestration workspace that provides specialized agents for healthcare/regulated environment DevOps consulting. It uses Claude Code's agent system with multi-AI delegation (Claude, Codex, Gemini) to reduce token consumption while maintaining quality.

## Key Architecture Concepts

### Agent Delegation System

This workspace implements a **3-tier AI delegation strategy** to optimize token usage:

1. **Claude** (Orchestration): Complex reasoning, healthcare context, planning
2. **Codex/GPT-5** (Technical depth): Optimization, test generation, code review
3. **Gemini** (Pattern detection): Security scanning, compliance checking

**Critical**: All agents source `/home/temlock/ai-workspace/.claude/lib/delegation.sh` which provides:
- `delegate_to_codex()` - Delegate tasks to Codex CLI
- `delegate_to_gemini()` - Delegate tasks to Gemini CLI
- `get_delegation_config()` - Get agent delegation preference (3-level override system)

Configuration priority: Environment variables → `.claude/ai-delegation.yml` → hardcoded defaults

### Report Generation System

All agents generate reports using `/home/temlock/ai-workspace/.claude/lib/reporting.sh`:

**IMPORTANT**: Reports are saved to OneDrive for cloud sync and client delivery:
```bash
REPORTS_DIR="/mnt/c/Users/thoma/onedrive/documents/AI-Workspace/Reports"
```

Report types generated:
- `security-audit_YYYY-MM-DD_HH-MM-SS.md`
- `code-review_YYYY-MM-DD_HH-MM-SS.md`
- `optimization_YYYY-MM-DD_HH-MM-SS.md`
- `test-execution_YYYY-MM-DD_HH-MM-SS.md`
- `documentation_YYYY-MM-DD_HH-MM-SS.md`

Functions available:
- `generate_security_report()` - Create security audit report
- `generate_code_review_report()` - Create code review report
- `generate_optimization_report()` - Create optimization report
- `generate_test_report()` - Create test execution report
- `generate_documentation_report()` - Create documentation report
- `send_report_email()` - Email report (if enabled)

## Custom Slash Commands

Six specialized agents are available via slash commands:

### `/security-audit`
Comprehensive security analysis with OWASP Top 10, HIPAA, SOC 2, NIST CSF compliance checking.
- **Delegation**: Gemini (pattern detection) + Claude (aggregation)
- **Token savings**: ~73% (8K vs 30K tokens)
- **Agent config**: `.claude/agents/security-analyzer.md`

### `/review`
Multi-perspective code review (architecture, security, performance).
- **Delegation**: Codex (architecture) + Gemini (security) + Claude (aggregation)
- **Token savings**: ~60%
- **Agent config**: `.claude/agents/code-reviewer.md`

### `/optimize`
Performance optimization analysis with before/after code examples.
- **Delegation**: Codex (analysis) + Claude (prioritization)
- **Token savings**: ~65%
- **Agent config**: `.claude/agents/optimizer.md`

### `/test`
Test execution, coverage analysis, and gap identification.
- **Delegation**: Bash (execution) + Codex (analysis)
- **Token savings**: ~50%
- **Agent config**: `.claude/agents/test-runner.md`

### `/document`
Documentation generation (README, API docs, architecture diagrams).
- **Delegation**: Codex (technical) + Claude (narrative/compliance)
- **Token savings**: ~55%
- **Agent config**: `.claude/agents/doc-generator.md`

### `/closeout`
Automated session closeout with git commits and learning log updates.
- **Delegation**: Claude only (requires full context)
- **Agent config**: `.claude/agents/session-closer.md`

## Development Commands

### Testing the Delegation System

```bash
# Load delegation library
source /home/temlock/ai-workspace/.claude/lib/delegation.sh

# Check agent delegation config
get_delegation_config "security-analyzer"  # Returns: gemini

# Override for current session
export AI_DELEGATION_SECURITY_ANALYZER=codex

# Run system diagnostics
bash /home/temlock/ai-workspace/system-check.sh

# Run BATS tests
bats /home/temlock/ai-workspace/tests/system-check.bats
```

### Report Management

```bash
# Source reporting library
source /home/temlock/ai-workspace/.claude/lib/reporting.sh

# List all reports
list_reports

# Get latest security audit report
get_latest_report "security-audit"

# Archive old reports (30+ days)
archive_old_reports 30

# Convert report to HTML (requires pandoc)
convert_report_to_html "/path/to/report.md"
```

### Configuration Override Examples

```bash
# Session-level override (environment variable)
export AI_DELEGATION_OPTIMIZER=claude
export AI_DELEGATION_SECURITY_ANALYZER=codex

# Persistent override (config file)
cp .claude/ai-delegation.yml.template .claude/ai-delegation.yml
# Edit .claude/ai-delegation.yml:
#   agents:
#     security-analyzer: codex
#     optimizer: gemini
```

## Agent Development Patterns

### Creating a New Agent

1. Create agent definition: `.claude/agents/new-agent.md`
2. Define delegation strategy in agent config
3. Source libraries at the top:
   ```bash
   source /home/temlock/ai-workspace/.claude/lib/delegation.sh
   source /home/temlock/ai-workspace/.claude/lib/reporting.sh
   ```
4. Use delegation functions appropriately
5. Generate report before completion
6. Create slash command: `.claude/commands/new-command.md`

### Agent Structure Template

```markdown
# Agent Name

## Delegation Strategy
- Primary AI: [codex|gemini|claude|multi]
- Fallback: claude
- Token target: <10K Claude tokens

## Procedure
1. Source delegation and reporting libraries
2. Gather input files
3. Delegate heavy analysis to appropriate AI
4. Aggregate findings (Claude)
5. Generate report using reporting library
6. Return report path

## Report Format
- Use generate_*_report() from reporting.sh
- Include severity levels (P0/P1/P2/P3)
- Provide actionable remediation steps
- Reference compliance frameworks (HIPAA, SOC 2, NIST)
```

### Multi-AI Orchestration Pattern

For agents using multiple AIs (like code-reviewer):

```bash
# Step 1: Parallel delegation
CODEX_RESULT=$(delegate_to_codex "code-review" "$code_path" "$arch_prompt")
GEMINI_RESULT=$(delegate_to_gemini "security-scan" "$code_path" "$sec_prompt")

# Step 2: Wait for completion and parse results
parse_codex_findings "$CODEX_RESULT"
parse_gemini_findings "$GEMINI_RESULT"

# Step 3: Claude aggregates and cross-references
aggregate_findings_by_priority
cross_reference_issues

# Step 4: Generate comprehensive report
generate_code_review_report "$aggregated_content" "$codebase" "$issue_count"
```

## Healthcare/Compliance Context

This workspace is designed for **healthcare and regulated environments**. All agents consider:

- **HIPAA** §164.312 Technical Safeguards
- **SOC 2** Common Criteria (Security, Availability, Confidentiality)
- **NIST Cybersecurity Framework** control mapping
- **OWASP Top 10** vulnerability detection
- **PHI/PII** exposure prevention

When working in this repository:
- Never suggest storing credentials in code
- Always recommend encryption for sensitive data
- Consider audit logging requirements
- Flag potential PHI exposure in code/configs
- Reference compliance frameworks in security findings

## File Organization

```
ai-workspace/
├── .claude/
│   ├── agents/              # Agent definitions (6 specialized agents)
│   ├── commands/            # Slash command definitions
│   ├── lib/
│   │   ├── delegation.sh    # Multi-AI delegation library
│   │   └── reporting.sh     # Report generation library
│   └── ai-delegation.yml    # Agent delegation configuration
├── reports/                 # Legacy local reports (not used)
├── tests/
│   └── system-check.bats    # BATS test suite
├── agents.md                # Master coordination document
├── claude.md → agents.md    # Symlink (single source of truth)
├── gemini.md → agents.md    # Symlink (single source of truth)
└── system-check.sh          # Diagnostic script

# OneDrive Reports (primary location)
/mnt/c/Users/thoma/onedrive/documents/AI-Workspace/Reports/
```

## Token Optimization Strategy

Target token consumption per agent execution:
- With delegation: ~8-12K Claude tokens
- Without delegation: ~30K Claude tokens
- **Goal**: 60-70% token reduction across all agents

**When to delegate**:
- Pattern detection → Gemini
- Code optimization → Codex
- Security scanning → Gemini
- Test generation → Codex
- Technical documentation → Codex

**When NOT to delegate**:
- Healthcare context interpretation → Claude
- Compliance narrative → Claude
- Multi-source aggregation → Claude
- Complex reasoning → Claude

## Common Workflows

### Running a Security Audit

```bash
# Option 1: Use slash command (recommended)
/security-audit

# Option 2: Direct agent invocation via Task tool
# Use Task tool with subagent_type='general-purpose'
# Prompt: "Read .claude/agents/security-analyzer.md and execute security audit"
```

### Testing with Intentional Vulnerabilities

```bash
# Create test app with security issues
mkdir -p /tmp/test-security-app
cat > /tmp/test-security-app/app.py <<'EOF'
import os

# Hardcoded credential (should be detected as P0)
API_KEY = "sk_live_1234567890"

def get_user(user_id):
    # SQL injection vulnerability (should be detected as P0)
    query = "SELECT * FROM users WHERE id = " + user_id
    return execute(query)
EOF

# Run security audit
/security-audit /tmp/test-security-app
```

### Overriding Delegation for Testing

```bash
# Force all agents to use Claude (no delegation)
export AI_DELEGATION_SECURITY_ANALYZER=claude
export AI_DELEGATION_OPTIMIZER=claude
export AI_DELEGATION_CODE_REVIEWER=claude

# Run agents and compare token usage
/security-audit

# Restore delegation
unset AI_DELEGATION_SECURITY_ANALYZER
unset AI_DELEGATION_OPTIMIZER
unset AI_DELEGATION_CODE_REVIEWER
```

## Debugging

### View Delegation Logs

```bash
# Real-time monitoring
tail -f /tmp/ai-delegation.log

# View last 50 entries
tail -50 /tmp/ai-delegation.log

# Search for errors
grep -i error /tmp/ai-delegation.log

# Enable debug mode
export AI_DELEGATION_DEBUG=1
```

### Verify CLI Tools

```bash
# Check Codex installation
which codex
codex --version

# Check Gemini installation
which gemini
gemini --version

# Test basic delegation
echo "print('hello')" | codex exec -
```

### Troubleshooting Reports

```bash
# Check if reports directory exists and is writable
ls -la /mnt/c/Users/thoma/onedrive/documents/AI-Workspace/Reports/

# Verify reporting library loads
source /home/temlock/ai-workspace/.claude/lib/reporting.sh
echo "Reports directory: $REPORTS_DIR"

# List recent reports
ls -lht /mnt/c/Users/thoma/onedrive/documents/AI-Workspace/Reports/*.md | head -10
```

## Design Principles

1. **Token Efficiency**: Delegate heavy analysis to specialized AIs
2. **Quality Maintained**: Validate all delegated output meets professional standards
3. **Healthcare Focus**: All security/compliance checks consider HIPAA, SOC 2, NIST
4. **Automation**: Slash commands and agents reduce manual work
5. **Single Source of Truth**: Symlinks (claude.md → agents.md) eliminate duplication
6. **Separation of Concerns**: Specialized agents for specific tasks
7. **Observable**: Comprehensive logging for debugging and monitoring

## Important Notes

- **Always source libraries**: Delegation and reporting functionality requires sourcing the respective library files
- **Reports go to OneDrive**: Never hardcode report paths; always use `$REPORTS_DIR` from reporting.sh
- **Delegation is configurable**: Users can override defaults per-session or persistently
- **Claude handles aggregation**: Even when delegating, Claude performs final aggregation and formatting
- **Healthcare context**: This workspace specializes in HIPAA/regulated environments; maintain that context

## Version Information

- **Architecture Version**: 1.0.0
- **Delegation Library**: 1.0.0
- **Reporting Library**: 1.0.0
- **Last Updated**: 2025-11-21
