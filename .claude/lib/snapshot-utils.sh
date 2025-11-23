#!/bin/bash
# Snapshot Utility Library
# Shared functions for snapshot awareness across SDLC agents
# Source this file in agents: source .claude/lib/snapshot-utils.sh

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SNAPSHOT_AGE_THRESHOLD_MINUTES=25  # 5-minute buffer for TOCTOU protection
AGENTS_MD_PATH=".claude/agents/agents.md"

################################################################################
# Input Validation Functions (Security - P0/P1 fixes)
################################################################################

# Validate agent name (whitelist approach)
validate_agent_name() {
    local name="$1"
    local valid_agents="code-reviewer|security-analyzer|optimizer|snapshot|rollback|doc-generator|test-runner"

    if [[ ! "$name" =~ ^($valid_agents)$ ]]; then
        echo -e "${RED}✗ Invalid agent name: $name${NC}" >&2
        echo "Valid agents: code-reviewer, security-analyzer, optimizer, snapshot, rollback" >&2
        return 1
    fi
    return 0
}

# Validate snapshot type (whitelist)
validate_snapshot_type() {
    local type="$1"

    if [[ ! "$type" =~ ^(tag|branch|full)$ ]]; then
        echo -e "${RED}✗ Invalid snapshot type: $type${NC}" >&2
        echo "Valid types: tag, branch, full" >&2
        return 1
    fi
    return 0
}

# Validate snapshot name (alphanumeric + safe chars only)
validate_snapshot_name() {
    local name="$1"

    # Whitelist: letters, numbers, hyphens, underscores
    if [[ ! "$name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo -e "${RED}✗ Invalid snapshot name: must contain only letters, numbers, hyphens, underscores${NC}" >&2
        return 1
    fi

    # Length check
    if [[ ${#name} -gt 200 ]]; then
        echo -e "${RED}✗ Snapshot name too long (max 200 characters)${NC}" >&2
        return 1
    fi

    return 0
}

# Sanitize text for markdown logging (prevent injection)
sanitize_markdown() {
    local input="$1"

    # Escape markdown special characters
    input="${input//\\/\\\\}"  # Backslash
    input="${input//\[/\\[}"   # Left bracket
    input="${input//\]/\\]}"   # Right bracket
    input="${input//\#/\\#}"   # Hash
    input="${input//\*/\\*}"   # Asterisk
    input="${input//\_/\\_}"   # Underscore
    input="${input//\`/\\\`}"  # Backtick

    # Remove control characters
    input="${input//$'\n'/ }"  # Newline to space
    input="${input//$'\r'/}"   # Remove carriage return
    input="${input//$'\t'/ }"  # Tab to space

    # Truncate if too long
    if [[ ${#input} -gt 500 ]]; then
        input="${input:0:497}..."
    fi

    echo "$input"
}

################################################################################
# check_recent_snapshot
#
# Check if a snapshot exists within the threshold time (default: 30 minutes)
# Returns: 0 if recent snapshot exists, 1 otherwise
# Sets: SNAPSHOT_NAME, SNAPSHOT_AGE_MINUTES
################################################################################
check_recent_snapshot() {
    local threshold_minutes="${1:-$SNAPSHOT_AGE_THRESHOLD_MINUTES}"

    # P1-5: Validate git repository first
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        echo -e "${RED}✗ Not a git repository${NC}" >&2
        return 1
    fi

    # Try to find most recent snapshot tag with error handling
    local recent_snapshot
    if ! recent_snapshot=$(git tag -l "snapshot-*" --sort=-creatordate --format='%(creatordate:unix) %(refname:short)' 2>&1 | head -n 1); then
        echo -e "${RED}✗ Failed to query git tags${NC}" >&2
        return 1
    fi

    if [[ -z "$recent_snapshot" ]]; then
        # No snapshots exist at all
        return 1
    fi

    # P2: Use bash parameter expansion instead of awk (performance optimization)
    local snapshot_time snapshot_name
    snapshot_time="${recent_snapshot%% *}"
    snapshot_name="${recent_snapshot#* }"

    local current_time age_minutes
    current_time=$(date +%s)
    age_minutes=$(( (current_time - snapshot_time) / 60 ))

    # P0-3: Export timestamp for TOCTOU re-validation
    export SNAPSHOT_NAME="$snapshot_name"
    export SNAPSHOT_AGE_MINUTES="$age_minutes"
    export SNAPSHOT_TIMESTAMP="$snapshot_time"

    if [[ $age_minutes -le $threshold_minutes ]]; then
        return 0  # Recent snapshot exists
    else
        return 1  # Snapshot exists but too old
    fi
}

################################################################################
# prompt_for_snapshot
#
# Interactive prompt asking user to create snapshot
# Arguments: $1 = agent name (e.g., "code-reviewer", "optimizer")
#            $2 = operation description (e.g., "code review", "optimization")
# Returns: 0 if user wants to create snapshot, 1 if they want to continue anyway
################################################################################
prompt_for_snapshot() {
    local agent_name="$1"
    local operation="$2"

    # P1-2: Validate inputs
    validate_agent_name "$agent_name" || return 1

    # Sanitize operation for display (replace shell metacharacters)
    operation="${operation//[^a-zA-Z0-9 _-]/_}"

    echo -e "${YELLOW}⚠️  No recent snapshot detected${NC}"
    echo ""
    echo "Recommend creating snapshot before ${operation}."
    echo "This operation may suggest significant code changes."
    echo ""
    echo -e "${BLUE}Suggested command:${NC}"
    echo "  /snapshot \"before-${agent_name}-$(date +%Y%m%d-%H%M%S)\" --branch"
    echo ""
    echo "Options:"
    echo "  1. Create snapshot now (recommended)"
    echo "  2. Continue without snapshot (not recommended)"
    echo ""
    read -p "Choice [1/2]: " choice

    case "$choice" in
        1)
            return 0  # User wants snapshot
            ;;
        2)
            echo -e "${YELLOW}⚠️  Proceeding without snapshot (risky)${NC}"
            return 1  # User declined snapshot
            ;;
        *)
            echo "Invalid choice. Defaulting to option 1 (create snapshot)."
            return 0
            ;;
    esac
}

################################################################################
# auto_create_snapshot
#
# Automatically create snapshot for automated workflows
# Arguments: $1 = agent name
#            $2 = snapshot type (tag|branch)
#            $3 = optional custom reason/message
# Returns: 0 on success, 1 on failure
# Sets: AUTO_SNAPSHOT_NAME
################################################################################
auto_create_snapshot() {
    local agent_name="$1"
    local snapshot_type="${2:-tag}"
    local reason="${3:-Auto-snapshot before $agent_name execution}"

    # P1-2: Validate all inputs
    validate_agent_name "$agent_name" || return 1
    validate_snapshot_type "$snapshot_type" || return 1

    local timestamp
    timestamp=$(date +%Y%m%d-%H%M%S)
    local snapshot_name="before-$agent_name-$timestamp"

    # Validate generated snapshot name
    validate_snapshot_name "$snapshot_name" || return 1

    echo -e "${BLUE}Creating automatic snapshot...${NC}"

    # P0-2: Handle uncommitted changes with comprehensive error handling
    if [[ -n $(git status --porcelain) ]]; then
        echo "Uncommitted changes detected - auto-committing for snapshot safety..."

        # Safety check: Don't auto-commit sensitive files
        local sensitive_patterns="\.env|credentials|secrets|\.pem|\.key|id_rsa"
        if git status --porcelain | grep -qE "$sensitive_patterns"; then
            echo -e "${RED}✗ Cannot auto-commit: Sensitive files detected${NC}"
            git status --porcelain | grep -E "$sensitive_patterns"
            return 1
        fi

        # Stage all changes (explicit error check)
        if ! git add -A 2>&1; then
            echo -e "${RED}✗ Failed to stage changes${NC}"
            return 1
        fi

        # Verify files were staged
        local staged_count
        staged_count=$(git diff --cached --numstat | wc -l)
        if [[ $staged_count -eq 0 ]]; then
            echo -e "${RED}✗ No files were staged (git add failed silently)${NC}"
            return 1
        fi

        echo "Staged $staged_count files for auto-commit"

        # P0-1: Fix command injection - use proper quoting and separate -m flags
        if ! git commit \
            -m "Pre-${agent_name} checkpoint: Auto-commit for safety" \
            -m "$(sanitize_markdown "$reason")" \
            -m "Snapshot: ${snapshot_name}" \
            -m "Timestamp: $(date)" 2>&1; then
            echo -e "${RED}✗ Failed to commit changes${NC}"
            # Rollback: Unstage files
            git reset HEAD 2>/dev/null
            return 1
        fi

        # Verify commit succeeded
        if [[ -n $(git status --porcelain) ]]; then
            echo -e "${YELLOW}⚠️  Warning: Uncommitted changes remain after commit${NC}"
            git status --short
        fi
    fi

    case "$snapshot_type" in
        tag)
            # P0-1: Fix command injection - use proper quoting and multiple -m flags
            if ! git tag -a "snapshot-${snapshot_name}" \
                -m "Auto-snapshot: $(sanitize_markdown "$reason")" \
                -m "Agent: ${agent_name}" \
                -m "Timestamp: $(date)" \
                -m "Commit: $(git rev-parse HEAD)" 2>&1; then
                echo -e "${RED}✗ Failed to create snapshot tag${NC}"
                return 1
            fi

            echo -e "${GREEN}✓ Auto-created snapshot: snapshot-${snapshot_name} (tag)${NC}"
            ;;

        branch)
            local current_branch
            if ! current_branch=$(git branch --show-current 2>&1); then
                echo -e "${RED}✗ Failed to get current branch${NC}"
                return 1
            fi

            # P0-1: Fix command injection - validate snapshot_name is safe
            if ! git checkout -b "snapshot/${snapshot_name}" 2>&1; then
                echo -e "${RED}✗ Failed to create snapshot branch${NC}"
                return 1
            fi

            if ! git checkout "${current_branch}" 2>&1; then
                echo -e "${RED}✗ Failed to return to original branch${NC}"
                # Attempt cleanup
                git branch -D "snapshot/${snapshot_name}" 2>/dev/null
                return 1
            fi

            echo -e "${GREEN}✓ Auto-created snapshot: snapshot/${snapshot_name} (branch)${NC}"
            ;;

        *)
            echo -e "${RED}✗ Invalid snapshot type: $snapshot_type${NC}"
            return 1
            ;;
    esac

    # Log to agents.md for audit trail
    log_snapshot_to_agents_md "$snapshot_name" "$snapshot_type" "$reason" "$agent_name"

    # Export for caller
    export AUTO_SNAPSHOT_NAME="$snapshot_name"

    return 0
}

################################################################################
# log_snapshot_to_agents_md
#
# Log snapshot creation to agents.md for compliance audit trail
# Arguments: $1 = snapshot name
#            $2 = snapshot type (tag|branch)
#            $3 = reason
#            $4 = agent name
################################################################################
log_snapshot_to_agents_md() {
    local snapshot_name="$1"
    local snapshot_type="$2"
    local reason="$3"
    local agent_name="$4"

    # P1-2: Validate all inputs
    validate_snapshot_name "$snapshot_name" || return 1
    validate_snapshot_type "$snapshot_type" || return 1
    validate_agent_name "$agent_name" || return 1

    # P0-3: Sanitize reason text to prevent markdown injection
    local safe_reason
    safe_reason=$(sanitize_markdown "$reason")

    # P1-3: Ensure agents.md exists with proper structure
    if [[ ! -f "$AGENTS_MD_PATH" ]]; then
        echo "Creating agents.md with proper structure..."
        mkdir -p "$(dirname "$AGENTS_MD_PATH")"

        cat > "$AGENTS_MD_PATH" << 'AGENTS_MD_HEADER'
# Agent Activity Log

**Purpose**: Maintain complete audit trail of AI agent operations for HIPAA §164.312(b) compliance

**Retention**: Permanent (required for regulatory compliance)

**Last Updated**: $(date)

---

## Snapshots

AGENTS_MD_HEADER
    fi

    # Create Snapshots section if it doesn't exist
    if ! grep -q "^## Snapshots$" "$AGENTS_MD_PATH" 2>/dev/null; then
        echo -e "\n## Snapshots\n" >> "$AGENTS_MD_PATH"
    fi

    local timestamp
    timestamp=$(date +%Y%m%d-%H%M%S)

    local commit_hash
    if ! commit_hash=$(git rev-parse HEAD 2>&1); then
        echo -e "${RED}✗ Failed to get current commit hash${NC}"
        return 1
    fi

    local current_branch
    if ! current_branch=$(git branch --show-current 2>&1); then
        # Could be detached HEAD - handle gracefully
        current_branch="(detached HEAD at ${commit_hash:0:7})"
    fi

    # Get last snapshot for diff stats (optional - don't fail if missing)
    local last_snapshot
    last_snapshot=$(git tag -l "snapshot-*" --sort=-creatordate 2>/dev/null | head -n 2 | tail -n 1 || echo "")

    local file_stats
    if [[ -n "$last_snapshot" ]]; then
        if ! file_stats=$(git diff --stat "$last_snapshot" HEAD 2>&1 | tail -n 1); then
            # Diff failed - snapshot might be corrupted or deleted
            file_stats="(diff unavailable - snapshot may be invalid)"
        fi
    else
        file_stats="Initial snapshot"
    fi

    # Determine restoration command based on type
    local restore_cmd
    if [[ "$snapshot_type" == "branch" ]]; then
        restore_cmd="git checkout snapshot/${snapshot_name}"
    else
        restore_cmd="git checkout tags/snapshot-${snapshot_name}"
    fi

    # Get current user for audit trail
    local user_id
    user_id="${SUDO_USER:-$(whoami)}"

    # P0-3: Append entry to agents.md with sanitized values
    cat >> "$AGENTS_MD_PATH" << EOF

### [${timestamp}] ${snapshot_name}
- **Type**: ${snapshot_type}
- **Commit**: ${commit_hash}
- **Branch**: ${current_branch}
- **Reason**: ${safe_reason}
- **Agent**: ${agent_name}
- **Created By**: ${user_id}
- **Files changed**: ${file_stats}
- **Restoration**: \`${restore_cmd}\`
- **Auto-created**: Yes

EOF

    echo -e "${GREEN}✓ Logged snapshot to agents.md${NC}"
}

################################################################################
# snapshot_safety_check
#
# Main entry point for snapshot safety checks in SDLC agents
# Combines check + prompt/auto-create logic
#
# Arguments: $1 = agent name
#            $2 = mode (interactive|auto|bypass)
#            $3 = snapshot type for auto mode (tag|branch)
#            $4 = optional operation description
# Returns: 0 on success (snapshot exists or created), 1 on failure
# Sets: SAFETY_SNAPSHOT_NAME
################################################################################
snapshot_safety_check() {
    local agent_name="$1"
    local mode="${2:-interactive}"
    local snapshot_type="${3:-tag}"
    local operation="${4:-$agent_name execution}"

    # P1-2: Validate inputs at entry point
    validate_agent_name "$agent_name" || return 1
    validate_snapshot_type "$snapshot_type" || return 1

    # P1-6: Validate git repository before any operations
    validate_git_repository || return 1

    echo -e "${BLUE}=== Snapshot Safety Check ===${NC}"

    # Check for recent snapshot
    if check_recent_snapshot; then
        echo -e "${GREEN}✓ Recent snapshot exists: $SNAPSHOT_NAME${NC}"
        echo "  Created: $SNAPSHOT_AGE_MINUTES minutes ago"
        export SAFETY_SNAPSHOT_NAME="$SNAPSHOT_NAME"
        return 0
    fi

    # No recent snapshot - handle based on mode
    case "$mode" in
        interactive)
            if prompt_for_snapshot "$agent_name" "$operation"; then
                echo ""
                echo -e "${YELLOW}Please create snapshot and re-run this agent:${NC}"
                echo "  /snapshot \"before-$agent_name-$(date +%Y%m%d-%H%M%S)\" --branch"
                echo ""
                return 1  # Exit agent, wait for user to create snapshot
            else
                echo -e "${YELLOW}⚠️  Continuing without snapshot (user override)${NC}"
                export SAFETY_SNAPSHOT_NAME="none"
                return 0  # User explicitly declined, continue anyway
            fi
            ;;

        auto|bypass)
            if auto_create_snapshot "$agent_name" "$snapshot_type" "Safety checkpoint before $operation"; then
                echo "  Type: $snapshot_type"
                echo "  Restoration: /snapshot --restore $AUTO_SNAPSHOT_NAME"
                export SAFETY_SNAPSHOT_NAME="$AUTO_SNAPSHOT_NAME"
                return 0
            else
                echo -e "${RED}✗ Failed to auto-create snapshot${NC}"
                return 1
            fi
            ;;

        *)
            echo -e "${RED}✗ Invalid mode: $mode${NC}"
            return 1
            ;;
    esac
}

################################################################################
# get_snapshot_report_section
#
# Generate snapshot section for agent reports
# Arguments: $1 = snapshot name (or "none")
#            $2 = agent name
# Outputs: Markdown-formatted snapshot report section
################################################################################
get_snapshot_report_section() {
    local snapshot_name="$1"
    local agent_name="$2"

    if [[ "$snapshot_name" == "none" ]]; then
        echo "**Snapshot**: None (user declined)"
        echo ""
        echo "> ⚠️  No snapshot was created for this operation. Rollback not available."
        return
    fi

    # Determine if it's a tag or branch
    local restore_cmd
    if git show-ref --tags "snapshot-$snapshot_name" >/dev/null 2>&1; then
        restore_cmd="git checkout tags/snapshot-$snapshot_name"
    elif git show-ref --heads "snapshot/$snapshot_name" >/dev/null 2>&1; then
        restore_cmd="git checkout snapshot/$snapshot_name"
    else
        restore_cmd="/snapshot --restore $snapshot_name"
    fi

    cat << EOF
**Snapshot**: $snapshot_name

### Rollback Instructions
If $agent_name changes cause issues:
\`\`\`bash
# Using snapshot agent (recommended)
/snapshot --restore $snapshot_name

# Or using git directly
$restore_cmd
\`\`\`

### Audit Trail
This snapshot is logged in .claude/agents/agents.md for compliance auditing.
EOF
}

################################################################################
# validate_git_repository
#
# Verify we're in a git repository before snapshot operations
# Returns: 0 if valid git repo, 1 otherwise
################################################################################
validate_git_repository() {
    # P1-6: Enhanced git repository validation

    # Check if git command exists
    if ! command -v git >/dev/null 2>&1; then
        echo -e "${RED}✗ Git is not installed${NC}" >&2
        echo "Install git: sudo apt-get install git" >&2
        return 1
    fi

    # Check if we're in a git repository
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        echo -e "${RED}✗ Not a git repository${NC}" >&2
        echo "Initialize with: git init" >&2
        echo "Current directory: $(pwd)" >&2
        return 1
    fi

    # Check if repository is corrupted
    if ! git status >/dev/null 2>&1; then
        echo -e "${RED}✗ Git repository is corrupted${NC}" >&2
        echo "Try: git fsck --full" >&2
        return 1
    fi

    # Check if HEAD exists (not a brand new repo)
    if ! git rev-parse HEAD >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  No commits in repository yet${NC}" >&2
        echo "Create initial commit before using snapshot features" >&2
        return 1
    fi

    return 0
}

################################################################################
# get_snapshot_statistics
#
# Get statistics about existing snapshots for reporting
# Outputs: Human-readable snapshot statistics
################################################################################
get_snapshot_statistics() {
    echo -e "${BLUE}=== Snapshot Statistics ===${NC}"

    local tag_count branch_count bundle_count
    tag_count=$(git tag -l "snapshot-*" 2>/dev/null | wc -l)
    branch_count=$(git branch --list "snapshot/*" 2>/dev/null | wc -l)
    bundle_count=$(ls -1 ~/ai-workspace/backups/*.bundle 2>/dev/null | wc -l)

    echo "Quick snapshots (tags): $tag_count"
    echo "Recovery branches: $branch_count"
    echo "Full backups (bundles): $bundle_count"

    local total=$((tag_count + branch_count + bundle_count))
    echo "Total snapshots: $total"

    if [[ $total -gt 10 ]]; then
        echo ""
        echo -e "${YELLOW}💡 Tip: Consider running /snapshot --cleanup to remove old snapshots${NC}"
    fi
}

################################################################################
# Usage Examples (for documentation)
################################################################################
: << 'USAGE_EXAMPLES'

# Example 1: Basic interactive check
source .claude/lib/snapshot-utils.sh
if snapshot_safety_check "code-reviewer" "interactive" "branch" "code review"; then
    echo "Snapshot verified, proceeding with code review..."
else
    echo "Exiting - please create snapshot first"
    exit 1
fi

# Example 2: Automated workflow
source .claude/lib/snapshot-utils.sh
snapshot_safety_check "optimizer" "auto" "branch" "optimization analysis"
# Snapshot is auto-created, stored in $SAFETY_SNAPSHOT_NAME

# Example 3: Add snapshot section to report
source .claude/lib/snapshot-utils.sh
snapshot_safety_check "security-analyzer" "auto" "tag"
get_snapshot_report_section "$SAFETY_SNAPSHOT_NAME" "security-analyzer" > /tmp/snapshot-section.md

# Example 4: Simple check without action
source .claude/lib/snapshot-utils.sh
if check_recent_snapshot; then
    echo "Recent snapshot: $SNAPSHOT_NAME ($SNAPSHOT_AGE_MINUTES min old)"
fi

USAGE_EXAMPLES

# Export functions for use in other scripts
export -f check_recent_snapshot
export -f prompt_for_snapshot
export -f auto_create_snapshot
export -f log_snapshot_to_agents_md
export -f snapshot_safety_check
export -f get_snapshot_report_section
export -f validate_git_repository
export -f get_snapshot_statistics
