# Snapshot Utils API Reference

**Library**: `.claude/lib/snapshot-utils.sh`
**Version**: 1.0.0
**Status**: Production Ready
**Security Level**: Hardened (9/9 P0-P1 vulnerabilities fixed)

Complete API documentation for the snapshot utility library used by snapshot and rollback agents, and available for integration into other agents.

---

## Table of Contents

1. [Overview](#overview)
2. [Getting Started](#getting-started)
3. [Input Validation Functions](#input-validation-functions)
4. [Snapshot Check Functions](#snapshot-check-functions)
5. [Snapshot Creation Functions](#snapshot-creation-functions)
6. [Utility Functions](#utility-functions)
7. [Error Handling](#error-handling)
8. [Integration Guide](#integration-guide)
9. [Security Considerations](#security-considerations)
10. [Examples](#examples)

---

## Overview

The snapshot utilities library provides a comprehensive set of functions for:

- Validating snapshot operations with whitelist-based security
- Checking for recent snapshots across the codebase
- Creating automatic snapshots with multiple safety checks
- Logging snapshots to audit trail
- Generating snapshot reports for documentation

### Core Features

- **Whitelist Validation**: Agent names, snapshot types, and file paths validated against known values
- **Safety Checks**: Repository validation, disk space verification, uncomitted change detection
- **Audit Logging**: Append-only audit trail with sanitized content
- **TOCTOU Protection**: Timestamp re-validation prevents race conditions
- **Error Handling**: Comprehensive error reporting with actionable messages

### Architecture

```
┌─────────────────────────────────┐
│   Calling Agent (e.g., optimize) │
└──────────────┬──────────────────┘
               │ source lib
┌──────────────▼──────────────────┐
│    snapshot-utils.sh Library     │
├──────────────────────────────────┤
│ • Validation Functions           │
│ • Check Functions                │
│ • Creation Functions             │
│ • Logging Functions              │
│ • Report Functions               │
└──────────────┬──────────────────┘
               │
     ┌─────────┼─────────┐
     │         │         │
     ▼         ▼         ▼
   .git    agents.md  Config
```

---

## Getting Started

### Source the Library

```bash
#!/bin/bash
source .claude/lib/snapshot-utils.sh

# Now all functions are available
```

### Minimal Integration

```bash
#!/bin/bash
source .claude/lib/snapshot-utils.sh

# Check if recent snapshot exists
if check_recent_snapshot; then
    echo "Recent snapshot found: $SNAPSHOT_NAME"
    proceed_with_operation
else
    echo "No recent snapshot"
    exit 1
fi
```

### Full Integration Pattern

```bash
#!/bin/bash
source .claude/lib/snapshot-utils.sh

# Run safety check with snapshot creation
if snapshot_safety_check "my-agent" "auto" "branch" "my operation"; then
    echo "Snapshot ready: $SAFETY_SNAPSHOT_NAME"
    perform_risky_operation

    # Add snapshot info to report
    get_snapshot_report_section "$SAFETY_SNAPSHOT_NAME" "my-agent"
else
    echo "Safety check failed"
    exit 1
fi
```

---

## Input Validation Functions

### validate_agent_name()

Validates agent name against whitelist.

**Usage**:
```bash
validate_agent_name "code-reviewer" || exit 1
```

**Parameters**:
- `$1` (string): Agent name to validate

**Valid Values**:
- `code-reviewer`
- `security-analyzer`
- `optimizer`
- `snapshot`
- `rollback`
- `doc-generator`
- `test-runner`

**Returns**:
- `0`: Valid agent name
- `1`: Invalid agent name (error message to stderr)

**Error Output**:
```
✗ Invalid agent name: unknown-agent
Valid agents: code-reviewer, security-analyzer, optimizer, snapshot, rollback
```

**Example**:
```bash
if validate_agent_name "$agent"; then
    echo "Agent valid, proceeding..."
else
    echo "Invalid agent - exiting"
    exit 1
fi
```

**Security Notes**:
- Uses whitelist approach (not regex patterns)
- Prevents command injection via agent name
- O(1) validation time (no file lookups)

---

### validate_snapshot_type()

Validates snapshot type against whitelist.

**Usage**:
```bash
validate_snapshot_type "branch" || exit 1
```

**Parameters**:
- `$1` (string): Snapshot type to validate

**Valid Values**:
- `tag`: Quick snapshot using git tag
- `branch`: Recovery branch
- `full`: Git bundle backup

**Returns**:
- `0`: Valid snapshot type
- `1`: Invalid snapshot type (error message to stderr)

**Example**:
```bash
case "$snapshot_type" in
    tag|branch|full)
        validate_snapshot_type "$snapshot_type" || exit 1
        ;;
    *)
        echo "Unknown type: $snapshot_type"
        exit 1
        ;;
esac
```

---

### validate_snapshot_name()

Validates snapshot name for safe git operations.

**Usage**:
```bash
validate_snapshot_name "pre-optimization" || exit 1
```

**Parameters**:
- `$1` (string): Snapshot name to validate

**Validation Rules**:
- **Characters**: Only letters (a-z, A-Z), numbers (0-9), hyphens (-), underscores (_)
- **Max length**: 200 characters
- **Format**: `^[a-zA-Z0-9_-]+$`

**Returns**:
- `0`: Valid snapshot name
- `1`: Invalid snapshot name (error message to stderr)

**Error Examples**:
```
✗ Invalid snapshot name: must contain only letters, numbers, hyphens, underscores
✗ Snapshot name too long (max 200 characters)
```

**Example**:
```bash
local name="before-optimization-$(date +%Y%m%d-%H%M%S)"
validate_snapshot_name "$name" || exit 1
```

---

### sanitize_markdown()

Sanitizes text for markdown logging to prevent injection attacks.

**Usage**:
```bash
safe_text=$(sanitize_markdown "$untrusted_input")
echo "Reason: $safe_text" >> agents.md
```

**Parameters**:
- `$1` (string): Text to sanitize

**Sanitization Operations**:
1. Escapes markdown special characters: `\ [ ] # * _ \``
2. Removes control characters: newlines, carriage returns, tabs
3. Truncates to 500 characters max
4. Safe to include in markdown files without injection risk

**Returns**: Stdout - sanitized text

**Example**:
```bash
read -p "Snapshot reason: " reason
safe_reason=$(sanitize_markdown "$reason")

# Safe to use in markdown
cat >> agents.md << EOF
- **Reason**: $safe_reason
EOF
```

**Security Notes**:
- Escapes all markdown control characters
- Prevents markdown injection (nested commands, etc.)
- Removes newlines to keep single-line format
- Truncates excessively long inputs

---

## Snapshot Check Functions

### check_recent_snapshot()

Checks if a recent snapshot exists within threshold time.

**Usage**:
```bash
if check_recent_snapshot 25; then
    echo "Recent snapshot: $SNAPSHOT_NAME (${SNAPSHOT_AGE_MINUTES}min old)"
fi
```

**Parameters**:
- `$1` (optional int): Threshold in minutes (default: 25)

**Exported Variables** (on success):
- `SNAPSHOT_NAME`: Name of recent snapshot found
- `SNAPSHOT_AGE_MINUTES`: Age of snapshot in minutes
- `SNAPSHOT_TIMESTAMP`: Unix timestamp of snapshot creation

**Returns**:
- `0`: Recent snapshot exists (within threshold)
- `1`: No recent snapshot OR snapshot too old

**Error Handling**:
- Returns 1 if not a git repository
- Returns 1 if git tag query fails
- Returns 1 if no snapshots exist at all

**Example - Basic Check**:
```bash
if check_recent_snapshot; then
    echo "✓ Found: $SNAPSHOT_NAME"
else
    echo "No recent snapshot available"
fi
```

**Example - Custom Threshold**:
```bash
# Check if snapshot is less than 5 minutes old
if check_recent_snapshot 5; then
    echo "Very fresh snapshot"
else
    echo "Snapshot is more than 5 minutes old"
fi
```

**TOCTOU Protection**:
The function timestamps the snapshot at check time and re-validates at use time. Variables `SNAPSHOT_TIMESTAMP` and `SNAPSHOT_AGE_MINUTES` can be re-checked before operations.

---

### validate_git_repository()

Comprehensive validation of git repository before snapshot operations.

**Usage**:
```bash
validate_git_repository || exit 1
```

**Parameters**: None

**Validation Checks**:
1. Git command is installed
2. Current directory is a git repository
3. Repository is not corrupted
4. HEAD exists (at least one commit)

**Returns**:
- `0`: Repository is valid
- `1`: Repository invalid (error message to stderr)

**Error Examples**:
```
✗ Git is not installed
Install git: sudo apt-get install git

✗ Not a git repository
Current directory: /home/user/mydir
Initialize with: git init

✗ Git repository is corrupted
Try: git fsck --full

✗ No commits in repository yet
Create initial commit before using snapshot features
```

**Example**:
```bash
if ! validate_git_repository; then
    echo "Cannot proceed without valid git repo"
    exit 1
fi
```

---

## Snapshot Creation Functions

### auto_create_snapshot()

Automatically creates a snapshot for automated workflows.

**Usage**:
```bash
if auto_create_snapshot "optimizer" "branch" "P0 optimization run"; then
    echo "Created: $AUTO_SNAPSHOT_NAME"
else
    echo "Snapshot creation failed"
    exit 1
fi
```

**Parameters**:
- `$1` (string, required): Agent name (must pass validate_agent_name)
- `$2` (string, optional): Snapshot type - `tag`, `branch`, or `full` (default: `tag`)
- `$3` (string, optional): Reason/message (default: "Auto-snapshot before $agent_name execution")

**Exported Variables** (on success):
- `AUTO_SNAPSHOT_NAME`: Name of created snapshot

**Returns**:
- `0`: Snapshot created successfully
- `1`: Creation failed (error message to stderr)

**Pre-Execution Actions**:
1. Validates agent name
2. Validates snapshot type
3. Validates git repository
4. Detects uncommitted changes
5. Checks for sensitive files (prevents accidental secrets commit)
6. Stages and commits changes if safe
7. Creates snapshot (tag/branch/bundle)
8. Logs to agents.md for audit trail

**Example - Automatic Snapshot**:
```bash
#!/bin/bash
source .claude/lib/snapshot-utils.sh

# Before running risky operation
if ! auto_create_snapshot "optimizer" "branch"; then
    echo "Safety snapshot failed - aborting"
    exit 1
fi

# Now we have backup: $AUTO_SNAPSHOT_NAME
perform_risky_operation

echo "Snapshot available for rollback: $AUTO_SNAPSHOT_NAME"
```

**Example - With Custom Message**:
```bash
auto_create_snapshot "test-runner" "tag" "Checkpoint before running test suite"
# Creates snapshot named: snapshot-before-test-runner-20250123-143022
```

**Safety Features**:
- Rejects operations if sensitive files (.env, .pem, secrets) detected
- Verifies files actually staged before committing
- Verifies commit succeeded before creating snapshot
- Comprehensive error checking on all git operations

---

### snapshot_safety_check()

Main entry point for snapshot safety checking in agents. Combines checking, prompting, and auto-creation logic.

**Usage**:
```bash
if snapshot_safety_check "code-reviewer" "interactive" "branch" "code review"; then
    echo "Snapshot ready: $SAFETY_SNAPSHOT_NAME"
    proceed_with_review
else
    exit 1
fi
```

**Parameters**:
- `$1` (string, required): Agent name
- `$2` (string, optional): Mode - `interactive`, `auto`, or `bypass` (default: `interactive`)
- `$3` (string, optional): Snapshot type (default: `tag`)
- `$4` (string, optional): Operation description (default: "$agent_name execution")

**Exported Variables** (on success):
- `SAFETY_SNAPSHOT_NAME`: Name of snapshot (or "none" if user declined)

**Returns**:
- `0`: Snapshot verified or created successfully
- `1`: Safety check failed

**Modes**:

**Interactive Mode**:
- Checks for recent snapshot
- If found: Returns success with snapshot name
- If not found: Prompts user to create snapshot or continue anyway
- User can choose to create or skip

**Auto Mode**:
- Checks for recent snapshot
- If found: Returns success
- If not found: Automatically creates snapshot
- Never prompts user

**Bypass Mode**:
- Same as auto mode
- Creates snapshot without user interaction
- Useful for fully automated pipelines

**Example - Interactive Mode**:
```bash
#!/bin/bash
source .claude/lib/snapshot-utils.sh

# For human-driven operations
snapshot_safety_check "code-reviewer" "interactive" "branch" "code review"

if [[ $? -eq 0 ]]; then
    echo "Proceeding with review (snapshot: $SAFETY_SNAPSHOT_NAME)"
    perform_code_review
else
    echo "Aborted by user"
    exit 1
fi
```

**Example - Automated Mode**:
```bash
#!/bin/bash
source .claude/lib/snapshot-utils.sh

# For automated workflows - auto-creates if needed
if snapshot_safety_check "optimizer" "auto" "branch" "optimization analysis"; then
    echo "Running optimization with safety snapshot: $SAFETY_SNAPSHOT_NAME"
    run_optimization
else
    echo "Failed to create safety snapshot"
    exit 1
fi
```

---

### log_snapshot_to_agents_md()

Logs snapshot creation to agents.md audit trail.

**Usage**:
```bash
log_snapshot_to_agents_md "pre-optimization-20250123-143022" "branch" "Safety checkpoint before optimization" "optimizer"
```

**Parameters**:
- `$1` (string): Snapshot name
- `$2` (string): Snapshot type (tag/branch/full)
- `$3` (string): Reason for snapshot
- `$4` (string): Agent name that created snapshot

**Side Effects**:
- Creates agents.md if it doesn't exist with proper structure
- Appends snapshot entry to agents.md under "## Snapshots" section
- Includes metadata: timestamp, commit hash, branch, reason, agent, user, file stats
- Automatically calculates diff statistics vs previous snapshot

**Returns**:
- `0`: Successfully logged
- `1`: Logging failed (validation error)

**Example Audit Entry Created**:
```markdown
### [20250123-143022] pre-optimization-20250123-143022
- **Type**: branch
- **Commit**: abc123f4567890def1234567890abc123f45678
- **Branch**: main
- **Reason**: Safety checkpoint before optimization
- **Agent**: optimizer
- **Created By**: temlock
- **Files changed**: 47 files changed, 892 insertions(+), 234 deletions(-)
- **Restoration**: `git checkout snapshot/pre-optimization-20250123-143022`
- **Auto-created**: Yes
```

**Audit Trail Uses**:
- HIPAA §164.312(b) audit control documentation
- SOC 2 CC6.1 change control records
- Compliance review and forensics
- Operational troubleshooting

---

## Utility Functions

### get_snapshot_report_section()

Generates markdown-formatted snapshot report section for agent outputs.

**Usage**:
```bash
get_snapshot_report_section "$SAFETY_SNAPSHOT_NAME" "optimizer"
```

**Parameters**:
- `$1` (string): Snapshot name (or "none")
- `$2` (string): Agent name

**Output**: Markdown-formatted snapshot section suitable for agent reports

**Returns**: Always 0 (writes to stdout)

**Example Output**:
```markdown
**Snapshot**: pre-optimization-20250123-143022

### Rollback Instructions
If optimizer changes cause issues:
```bash
# Using snapshot agent (recommended)
/snapshot --restore pre-optimization-20250123-143022

# Or using git directly
git checkout snapshot/pre-optimization-20250123-143022
```

### Audit Trail
This snapshot is logged in .claude/agents/agents.md for compliance auditing.
```

**Example - Adding to Agent Report**:
```bash
#!/bin/bash
source .claude/lib/snapshot-utils.sh

# ... perform operation ...

# Generate report
{
    echo "## Optimization Report"
    echo ""
    echo "Results: ..."
    echo ""
    get_snapshot_report_section "$SAFETY_SNAPSHOT_NAME" "optimizer"
} > report.md
```

---

### get_snapshot_statistics()

Generates human-readable snapshot statistics for diagnostics.

**Usage**:
```bash
get_snapshot_statistics
```

**Parameters**: None

**Output**: Formatted statistics to stdout

**Example Output**:
```
=== Snapshot Statistics ===
Quick snapshots (tags): 12
Recovery branches: 8
Full backups (bundles): 2
Total snapshots: 22

💡 Tip: Consider running /snapshot --cleanup to remove old snapshots
```

**Returns**: Always 0

**Use Cases**:
- Diagnostic reporting
- Cleanup recommendations
- System status checks
- User information

---

## Error Handling

### Standard Error Pattern

All functions follow consistent error handling:

```bash
# Check return code
if ! function_name "argument"; then
    echo "Function failed"
    exit 1
fi
```

### Error Message Format

Functions output to stderr with this format:

```
✗ Short error description
Additional context or recovery steps
```

**Examples**:
```
✗ Invalid agent name: unknown-agent
Valid agents: code-reviewer, security-analyzer, optimizer, snapshot, rollback

✗ Not a git repository
Initialize with: git init

✗ Snapshot name too long (max 200 characters)
Current length: 256
```

### Common Errors & Recovery

**"Not a git repository"**
```bash
cd /path/to/repository
git status  # Verify repo is valid
```

**"Git is not installed"**
```bash
sudo apt-get install git  # Debian/Ubuntu
brew install git          # macOS
```

**"Sensitive files detected"**
```bash
# Remove sensitive files from staging
git reset HEAD file.env
git checkout -- file.env

# Try again
auto_create_snapshot "optimizer" "branch"
```

**"Failed to get current commit hash"**
```bash
git status  # Check repository state
git fsck --full  # Check for corruption
```

---

## Integration Guide

### Integration Pattern

Here's the recommended pattern for integrating snapshot utilities into new agents:

```bash
#!/bin/bash
#
# Name: my-agent.sh
# Description: My custom agent with snapshot support
#

set -euo pipefail

# Source snapshot utilities early
source .claude/lib/snapshot-utils.sh

# Define logging function for reports
log_section() {
    echo "### $1" >> "$REPORT_FILE"
}

# PHASE 1: Pre-execution safety check
if ! snapshot_safety_check "my-agent" "auto" "branch" "my agent operation"; then
    echo "Failed to create safety snapshot - aborting"
    exit 1
fi

echo "Safety snapshot: $SAFETY_SNAPSHOT_NAME"

# PHASE 2: Perform agent operations
log_section "Operations"
echo "Snapshot created for rollback..." >> "$REPORT_FILE"

# ... agent work here ...

# PHASE 3: Add snapshot info to report
log_section "Recovery Information"
get_snapshot_report_section "$SAFETY_SNAPSHOT_NAME" "my-agent" >> "$REPORT_FILE"

# PHASE 4: Complete
echo "✓ Agent completed successfully"
echo "Report: $REPORT_FILE"
```

### Integration Checklist

- [ ] Source library: `source .claude/lib/snapshot-utils.sh`
- [ ] Call snapshot safety check early: `snapshot_safety_check "agent-name" "auto"`
- [ ] Include snapshot info in reports: `get_snapshot_report_section`
- [ ] Handle errors gracefully: Check return codes
- [ ] Test with different modes: interactive, auto, bypass
- [ ] Verify audit logging: Check agents.md after runs

---

## Security Considerations

### Input Validation

All external inputs are validated:

**Agent Names**:
- Whitelist validation against known agents
- Prevents command injection

**Snapshot Names**:
- Alphanumeric + safe characters only
- Max 200 character length
- Prevents path traversal and injection

**Snapshot Types**:
- Whitelist: tag, branch, full
- No string interpolation in git commands

**Text Input**:
- Markdown special characters escaped
- Control characters removed
- Maximum length enforced

### Command Injection Prevention

Critical security feature: Proper quoting in all git commands:

```bash
# CORRECT - Proper quoting with multiple -m flags
git commit \
    -m "Message part 1" \
    -m "Message part 2" \
    -m "Sanitized reason: $safe_reason"

# INCORRECT - Vulnerable to injection (not used)
git commit -m "Reason: $unsafe_input"
```

### Sensitive File Detection

Before auto-committing, checks for sensitive patterns:

```bash
sensitive_patterns="\.env|credentials|secrets|\.pem|\.key|id_rsa"

if git status --porcelain | grep -qE "$sensitive_patterns"; then
    echo "Cannot auto-commit: Sensitive files detected"
    return 1
fi
```

### TOCTOU Protection

Time-of-Check-Time-of-Use race condition protection:

```bash
# Store timestamp at check time
export SNAPSHOT_TIMESTAMP="$snapshot_time"
export SNAPSHOT_AGE_MINUTES="$age_minutes"

# Can re-validate at operation time
current_time=$(date +%s)
age_minutes=$(( (current_time - SNAPSHOT_TIMESTAMP) / 60 ))
```

### Audit Trail Security

- All logs use sanitized markdown
- No PHI (Protected Health Information) in logs
- Immutable append-only audit trail
- User attribution and timestamps
- Restoration commands for forensics

---

## Examples

### Example 1: Add Snapshot to Code Reviewer

```bash
#!/bin/bash
# In code-reviewer agent

source .claude/lib/snapshot-utils.sh

echo "=== Code Reviewer Agent ==="

# Safety check
if ! snapshot_safety_check "code-reviewer" "auto" "branch"; then
    echo "Failed to create safety snapshot"
    exit 1
fi

# Proceed with review
echo "Reviewing code (snapshot: $SAFETY_SNAPSHOT_NAME)"
perform_review

# Add snapshot to report
{
    echo "## Safety & Rollback"
    get_snapshot_report_section "$SAFETY_SNAPSHOT_NAME" "code-reviewer"
} >> review-report.md
```

### Example 2: Automated Optimization Pipeline

```bash
#!/bin/bash
# In optimizer agent

source .claude/lib/snapshot-utils.sh

# Create automatic snapshot for safe optimization
if ! auto_create_snapshot "optimizer" "branch" "Pre-optimization checkpoint"; then
    echo "Failed to create optimization checkpoint"
    exit 1
fi

echo "✓ Created checkpoint: $AUTO_SNAPSHOT_NAME"
echo "  Restore with: /snapshot --restore $AUTO_SNAPSHOT_NAME"

# Run optimization
analyze_and_suggest_changes

# If changes are applied and something breaks, user can restore
```

### Example 3: Check Recent Snapshot in SDLC

```bash
#!/bin/bash
# In SDLC workflow

source .claude/lib/snapshot-utils.sh

# Check if we have recent snapshot (within 30 min)
if check_recent_snapshot 30; then
    echo "✓ Recent snapshot available: $SNAPSHOT_NAME"
    SAFE_TO_PROCEED=true
else
    # Try to auto-create one
    if auto_create_snapshot "sdlc-workflow" "branch"; then
        echo "✓ Created SDLC snapshot: $AUTO_SNAPSHOT_NAME"
    else
        echo "⚠ No safety snapshot - proceeding with caution"
        SAFE_TO_PROCEED=false
    fi
fi
```

### Example 4: Conditional Snapshot in Test Runner

```bash
#!/bin/bash
# In test runner

source .claude/lib/snapshot-utils.sh

# For automated tests, always use auto mode
if snapshot_safety_check "test-runner" "auto" "tag"; then
    echo "Test checkpoint: $SAFETY_SNAPSHOT_NAME"
fi

# Run tests
run_test_suite

# Report results with rollback info
{
    echo "## Test Results"
    echo "Pass rate: X%"
    echo ""
    get_snapshot_report_section "$SAFETY_SNAPSHOT_NAME" "test-runner"
} > test-report.md
```

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2025-11-23 | Production release, 9/9 security fixes |
| 0.9.0 | 2025-11-22 | Beta testing, compliance validation |
| 0.1.0 | 2025-11-20 | Initial development |

## Compatibility

- **Bash**: 4.0+ (for parameter expansion)
- **Git**: 2.25+ (for tag formatting)
- **OS**: Linux, macOS, WSL (Unix-like systems)

## Support

- See `.claude/docs/integration-guide.md` for detailed integration help
- Check `.claude/docs/security.md` for security questions
- Review `.claude/README.md` for command-line usage

---

**Generated**: 2025-11-23
**Library Version**: 1.0.0
**Maintained By**: Tom Vitso + Claude Code
