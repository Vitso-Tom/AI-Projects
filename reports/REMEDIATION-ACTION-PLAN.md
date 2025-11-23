# Security Remediation Action Plan
## Snapshot/Rollback Infrastructure - Priority-Based Fixes

**Created**: 2025-11-23
**Status**: READY FOR IMPLEMENTATION
**Total Estimated Hours**: 6-8 hours for complete remediation

---

## Executive Summary

**Critical Findings**: 5 P0 issues blocking deployment
**High Priority**: 5 P1 issues blocking compliance certification
**Medium Priority**: 4 P2 issues for long-term hardening

**Deployment Status**: 🔴 **BLOCKED** - DO NOT DEPLOY until all P0 fixes complete

---

## CRITICAL PATH (P0 - MUST FIX BEFORE DEPLOYMENT)

### P0-1: Command Injection via User Input in Git Commits
**File**: `.claude/lib/snapshot-utils.sh:123-126, 135-139`
**Complexity**: LOW (30 min)
**Risk**: CRITICAL (CVSS 9.0)

#### Current Code (VULNERABLE):
```bash
# Line 123 - DANGEROUS
git commit -m "Pre-$agent_name checkpoint: Auto-commit for safety

$reason
Snapshot: $snapshot_name
Timestamp: $(date)" || {
```

#### Fixed Code:
```bash
# Use multiple -m flags to safely include variables
git commit \
    -m "Pre-${agent_name} checkpoint: Auto-commit for safety" \
    -m "Reason: ${reason}" \
    -m "Snapshot: ${snapshot_name}" \
    -m "Timestamp: $(date)" || {
    echo -e "${RED}✗ Failed to commit changes${NC}"
    return 1
}
```

#### Verification:
```bash
# Test injection attempt
agent_name='test"; git push -u origin pwned #'
# Should fail or safely escape the input
```

---

### P0-2: Command Injection in Branch Checkout
**File**: `.claude/lib/snapshot-utils.sh:151, 156`
**Complexity**: MEDIUM (45 min)
**Risk**: CRITICAL (CVSS 9.1)

#### Current Code (VULNERABLE):
```bash
# Line 151
git checkout -b "snapshot/$snapshot_name" || {
    echo -e "${RED}✗ Failed to create snapshot branch${NC}"
    return 1
}
```

#### Fixed Code:
```bash
# Validate snapshot name before use
if [[ ! $snapshot_name =~ ^[a-zA-Z0-9_-]{1,100}$ ]]; then
    echo -e "${RED}✗ Invalid snapshot name: $snapshot_name${NC}"
    return 1
fi

git checkout -b "snapshot/$snapshot_name" || {
    echo -e "${RED}✗ Failed to create snapshot branch${NC}"
    return 1
}
```

#### Add Validation Function:
```bash
validate_snapshot_name() {
    local name="$1"

    # Check format and length
    if [[ ! $name =~ ^[a-zA-Z0-9_-]{1,100}$ ]]; then
        echo "ERROR: Invalid snapshot name: $name" >&2
        return 1
    fi

    return 0
}

# Usage:
validate_snapshot_name "$snapshot_name" || return 1
```

---

### P0-3: Path Traversal and Markdown Injection in agents.md
**File**: `.claude/lib/snapshot-utils.sh:228-240`
**Complexity**: MEDIUM (45 min)
**Risk**: CRITICAL (CVSS 8.8)

#### Current Code (VULNERABLE):
```bash
# Line 228-240: Unvalidated variables written to audit log
cat >> "$AGENTS_MD_PATH" << EOF

### [$timestamp] $snapshot_name
- **Type**: $snapshot_type
- **Commit**: $commit_hash
- **Branch**: $current_branch
- **Reason**: $reason
- **Agent**: $agent_name
- **Files changed**: $file_stats
- **Restoration**: \`$restore_cmd\`

EOF
```

#### Fixed Code:
```bash
# Sanitize all variables before writing to audit log
sanitize_for_markdown() {
    local input="$1"

    # Escape backslashes
    input="${input//\\/\\\\}"

    # Escape markdown special characters
    input="${input//\[/\\[}"
    input="${input//\]/\\]}"
    input="${input//\(/\\(}"
    input="${input//\)/\\)}"

    # Remove suspicious patterns
    input="${input//\`/}"
    input="${input//\~/}"
    input="${input//#/\\#}"

    echo "$input"
}

# Safe audit logging
safe_reason=$(sanitize_for_markdown "$reason")
safe_agent=$(sanitize_for_markdown "$agent_name")
safe_cmd=$(sanitize_for_markdown "$restore_cmd")

cat >> "$AGENTS_MD_PATH" << EOF

### [$timestamp] $snapshot_name
- **Type**: $snapshot_type
- **Commit**: $commit_hash
- **Branch**: $current_branch
- **Reason**: $safe_reason
- **Agent**: $safe_agent
- **Files changed**: $file_stats
- **Restoration**: \`$safe_cmd\`

EOF
```

---

### P0-4: Missing Input Validation
**File**: `.claude/lib/snapshot-utils.sh:109-111`
**Complexity**: MEDIUM (45 min)
**Risk**: CRITICAL (CVSS 8.6)

#### Current Code (VULNERABLE):
```bash
auto_create_snapshot() {
    local agent_name="$1"      # NO VALIDATION
    local snapshot_type="${2:-tag}"  # NO VALIDATION
    local reason="${3:-Auto-snapshot before $agent_name execution}"  # NO VALIDATION
```

#### Fixed Code:
```bash
auto_create_snapshot() {
    local agent_name="$1"
    local snapshot_type="${2:-tag}"
    local reason="${3:-Auto-snapshot before $agent_name execution}"

    # VALIDATE agent_name
    if [[ ! $agent_name =~ ^[a-zA-Z0-9_-]{1,50}$ ]]; then
        echo "ERROR: Invalid agent_name: must be 1-50 alphanumeric, hyphen, underscore" >&2
        return 1
    fi

    # VALIDATE snapshot_type
    if [[ ! $snapshot_type =~ ^(tag|branch|full)$ ]]; then
        echo "ERROR: Invalid snapshot_type: must be tag, branch, or full" >&2
        return 1
    fi

    # VALIDATE reason length
    if [[ ${#reason} -gt 200 ]]; then
        echo "ERROR: Reason too long (max 200 characters)" >&2
        return 1
    fi

    # VALIDATE reason content (no suspicious patterns)
    if [[ $reason =~ (\;|\\|\`|\$\(|eval|exec) ]]; then
        echo "ERROR: Reason contains suspicious characters" >&2
        return 1
    fi

    # If all validation passes, continue with snapshot creation...
}
```

---

### P0-5: Missing Error Handling in Critical Operations
**File**: `.claude/lib/snapshot-utils.sh:31, 120, 214`
**Complexity**: HIGH (60 min)
**Risk**: CRITICAL (CVSS 8.4)

#### Current Code (VULNERABLE):
```bash
# Line 31: Silent failure - no way to know if git command succeeded
recent_snapshot=$(git tag -l "snapshot-*" --sort=-creatordate --format='%(creatordate:unix) %(refname:short)' 2>/dev/null | head -n 1)

# Empty result could mean:
# 1. No snapshots exist (legitimate)
# 2. Git command failed (error)
# 3. Git repository is corrupt (error)
# Caller cannot distinguish!
```

#### Fixed Code:
```bash
check_recent_snapshot() {
    local threshold_minutes="${1:-$SNAPSHOT_AGE_THRESHOLD_MINUTES}"

    # Execute git command and capture both output and exit code
    local recent_snapshot git_exit
    recent_snapshot=$(git tag -l "snapshot-*" --sort=-creatordate \
        --format='%(creatordate:unix) %(refname:short)' 2>&1)
    git_exit=$?

    # Check for git command failure
    if [[ $git_exit -ne 0 ]]; then
        echo "ERROR: git tag command failed (exit $git_exit)" >&2
        echo "Details: $recent_snapshot" >&2
        return 2  # DISTINCT error code for "command failed"
    fi

    # Get most recent tag
    recent_snapshot=$(echo "$recent_snapshot" | head -n 1)

    # Check for no snapshots (legitimate empty result)
    if [[ -z "$recent_snapshot" ]]; then
        echo "DEBUG: No snapshots found (legitimate empty state)" >&2
        return 1  # DISTINCT code for "no snapshots"
    fi

    # Parse snapshot info
    local snapshot_time snapshot_name
    snapshot_time=$(echo "$recent_snapshot" | awk '{print $1}')
    snapshot_name=$(echo "$recent_snapshot" | awk '{print $2}')

    # Validate parsed values
    if [[ -z "$snapshot_time" ]] || [[ -z "$snapshot_name" ]]; then
        echo "ERROR: Failed to parse snapshot information" >&2
        return 2  # Command succeeded but output malformed
    fi

    local current_time age_minutes
    current_time=$(date +%s)
    age_minutes=$(( (current_time - snapshot_time) / 60 ))

    export SNAPSHOT_NAME="$snapshot_name"
    export SNAPSHOT_AGE_MINUTES="$age_minutes"

    if [[ $age_minutes -le $threshold_minutes ]]; then
        return 0  # Recent snapshot exists
    else
        return 1  # Snapshot exists but too old
    fi
}

# Also fix git status check (Line 120)
if [[ -n $(git status --porcelain 2>&1) ]] || ! git status --quiet 2>/dev/null; then
    echo "Uncommitted changes detected - auto-committing..."
    # ... rest of logic
fi
```

---

## HIGH PRIORITY (P1 - BLOCKING COMPLIANCE)

### P1-1: TOCTOU Race Condition
**File**: `.claude/lib/snapshot-utils.sh:26-55`
**Complexity**: MEDIUM (45 min)
**Impact**: HIPAA §164.312(b) non-compliance

#### Issue:
Snapshot could be deleted between check and restore attempt.

#### Solution:
```bash
restore_snapshot() {
    local snapshot_name="$1"

    # Atomic: Verify exists AND capture reference in single operation
    local snapshot_ref
    if git show-ref --tags "snapshot-$snapshot_name" >/dev/null 2>&1; then
        snapshot_ref="snapshot-$snapshot_name"
    elif git show-ref --heads "snapshot/$snapshot_name" >/dev/null 2>&1; then
        snapshot_ref="snapshot/$snapshot_name"
    else
        echo "ERROR: Snapshot not found: $snapshot_name" >&2
        return 1
    fi

    # Restore immediately (minimal window for deletion)
    git checkout "$snapshot_ref" || {
        echo "ERROR: Failed to restore snapshot" >&2
        return 1
    fi

    echo "Restored: $snapshot_name"
    return 0
}
```

---

### P1-2: Missing User Attribution in Audit Logs
**File**: `.claude/lib/snapshot-utils.sh:188-243`
**Complexity**: LOW (30 min)
**Impact**: HIPAA §164.312(a) non-compliance

#### Solution:
```bash
log_snapshot_to_agents_md() {
    local snapshot_name="$1"
    local snapshot_type="$2"
    local reason="$3"
    local agent_name="$4"

    # GET USER INFORMATION
    local user_id="${SUDO_USER:-$(whoami)}"
    local user_full=$(getent passwd "$user_id" | cut -d: -f5)

    # ... existing validation ...

    # APPEND WITH USER ATTRIBUTION
    cat >> "$AGENTS_MD_PATH" << EOF

### [$timestamp] $snapshot_name
- **Type**: $snapshot_type
- **Commit**: $commit_hash
- **Branch**: $current_branch
- **Created By**: $user_id ($user_full)
- **Created At**: $(date -u +%Y-%m-%dT%H:%M:%SZ)
- **Reason**: $reason
- **Agent**: $agent_name
- **Files changed**: $file_stats
- **Restoration**: \`$restore_cmd\`
- **Audit Status**: LOGGED

EOF
}
```

---

### P1-3: No Encryption for Remote Backups
**File**: `.claude/agents/snapshot.md:210-217`
**Complexity**: MEDIUM (30 min)
**Impact**: HIPAA §164.312(e) non-compliance

#### Solution:
```bash
# Create encrypted backup
git bundle create - --all | \
    openssl enc -aes-256-cbc -salt -out "$BUNDLE_PATH" -pass pass:"$ENCRYPTION_KEY"

# Restore from encrypted backup
openssl enc -d -aes-256-cbc -in "$BUNDLE_PATH" -pass pass:"$ENCRYPTION_KEY" | \
    git bundle unbundle

# Store encryption key securely (not in code!)
# Use environment variable: SNAPSHOT_ENCRYPTION_KEY
```

---

### P1-4: Incomplete Change Control Documentation
**File**: `.claude/agents/snapshot.md:264-275`
**Complexity**: LOW (15 min)
**Impact**: SOC 2 CC6.1 non-compliance

#### Solution - Update agents.md format:
```markdown
### [20250122-143022] pre-optimization
- **Type**: branch
- **Commit**: abc123f456789
- **Branch**: main
- **Created By**: claude-code (AI Agent)
- **Reason**: Safety checkpoint before P0 optimization
- **Files Changed**: 47 files changed, 892 insertions(+), 234 deletions(-)
- **Data Classification**: PHI (Patient Records)
- **Retention Until**: 2026-11-23 (12 months)
- **Approved By**: [REQUIRED - must fill in]
- **Change Request**: CR-2025-0001 [REQUIRED]
- **Impact Assessment**: Low risk, optimization only, data unmodified
- **Rollback Tested**: [REQUIRED - YES/NO]
- **Restoration**: `git checkout snapshot/pre-optimization-20250122-143022`
```

---

### P1-5: No Change Control Approval Gate
**File**: `.claude/agents/rollback.md:118-124`
**Complexity**: HIGH (60 min)
**Impact**: SOC 2 CC6.1 non-compliance

#### Solution:
```bash
require_change_approval_for_rollback() {
    echo ""
    echo "SOC 2 CC6.1: Change Control Required"
    echo "=========================================="
    echo ""
    echo "Destructive operation requires documented approval."
    echo ""

    read -p "Change Request ID (e.g., CR-2025-0001): " CR_ID

    # Validate format
    if [[ ! $CR_ID =~ ^CR-[0-9]{4}-[0-9]{4}$ ]]; then
        echo "ERROR: Invalid CR format (must be CR-YYYY-NNNN)" >&2
        return 1
    fi

    read -p "Approved By (full name): " APPROVER

    if [[ -z "$APPROVER" ]]; then
        echo "ERROR: Approver name required" >&2
        return 1
    fi

    read -p "Approval Date (YYYY-MM-DD): " APPROVAL_DATE

    if [[ ! $APPROVAL_DATE =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        echo "ERROR: Invalid date format (must be YYYY-MM-DD)" >&2
        return 1
    fi

    # Log approval
    {
        echo ""
        echo "### [$(date +%Y%m%d-%H%M%S)] Change Approval"
        echo "- **Type**: Rollback Approval"
        echo "- **Change Request**: $CR_ID"
        echo "- **Approved By**: $APPROVER"
        echo "- **Approval Date**: $APPROVAL_DATE"
        echo "- **Status**: APPROVED"
    } >> ".claude/agents/agents.md"

    return 0
}

# Modify rollback workflow:
if git reset --hard HEAD~$COUNT; then
    # Log the rollback with approval reference
    {
        echo ""
        echo "### [$(date +%Y%m%d-%H%M%S)] Rollback Execution"
        echo "- **Type**: Hard Reset ($COUNT commits)"
        echo "- **Commits**: $(git log HEAD~$COUNT -n $COUNT --oneline)"
        echo "- **Approved Under**: $CR_ID"
        echo "- **Status**: COMPLETED"
    } >> ".claude/agents/agents.md"

    echo "Rollback complete"
else
    echo "Rollback failed"
    return 1
fi
```

---

## MEDIUM PRIORITY (P2 - IMPORTANT BUT NOT BLOCKING)

### P2-1: No Secrets Scanning in Logs
**File**: `.claude/lib/snapshot-utils.sh:228`
**Complexity**: MEDIUM (45 min)

#### Solution:
```bash
scan_and_redact_secrets() {
    local input="$1"

    # AWS Access Keys (AKIA...)
    input=$(echo "$input" | sed 's/AKIA[0-9A-Z]\{16\}/[REDACTED_AWS_KEY]/g')

    # Stripe Keys (sk_live_...)
    input=$(echo "$input" | sed 's/sk_live_[0-9a-zA-Z]\{24\}/[REDACTED_STRIPE_KEY]/g')

    # GitHub PATs (ghp_...)
    input=$(echo "$input" | sed 's/ghp_[0-9a-zA-Z]\{36\}/[REDACTED_GITHUB_TOKEN]/g')

    # Generic patterns
    input=$(echo "$input" | sed -E 's/(password|api.?key|secret|token)(["\'']*\s*[:=]\s*["\'']*)[^"'\''\s]+/\1\2[REDACTED]/gi')

    echo "$input"
}

# Use in audit logging
safe_reason=$(scan_and_redact_secrets "$reason")
```

---

### P2-2: Git Safety Configuration
**File**: `.claude/lib/snapshot-utils.sh` (add initialization)
**Complexity**: LOW (20 min)

#### Solution:
```bash
setup_git_safety() {
    # Set safe configuration before snapshot operations
    git config core.safecrlf true
    git config core.filemode true
    git config core.logallrefupdates true

    # Prevent accidental force pushes
    git config push.default upstream

    # Enable strict certificate verification
    git config http.sslVerify true
}

# Call at start of auto_create_snapshot()
setup_git_safety || {
    echo "WARNING: Could not set git safety configuration"
    # Don't fail, just warn
}
```

---

### P2-3: Snapshot Name Length Validation
**File**: `.claude/lib/snapshot-utils.sh:115`
**Complexity**: LOW (20 min)

#### Solution:
```bash
# Validate length limits before constructing name
if [[ ${#agent_name} -gt 50 ]]; then
    echo "ERROR: agent_name exceeds 50 character limit: ${#agent_name}" >&2
    return 1
fi

if [[ ${#reason} -gt 200 ]]; then
    echo "ERROR: reason exceeds 200 character limit: ${#reason}" >&2
    return 1
fi

# Construct with safety
snapshot_name="before-${agent_name:0:50}-$timestamp"
```

---

### P2-4: Data Classification in Snapshots
**File**: `.claude/agents/agents.md` (documentation)
**Complexity**: LOW (15 min)

#### Solution - Add to snapshot entry format:
```markdown
- **Data Classification**: [UNCLASSIFIED|INTERNAL|CONFIDENTIAL|PHI]
- **Contains PHI**: [YES|NO]
- **Contains PII**: [YES|NO]
- **Retention Period**: [6 years for PHI, per HIPAA]
- **Encryption**: [NONE|AES-256|OTHER]
```

---

## Implementation Checklist

### Phase 1: Critical Fixes (2-3 hours)
- [ ] Add input validation function to snapshot-utils.sh
- [ ] Fix command injection in git commit messages
- [ ] Fix command injection in git checkout
- [ ] Fix markdown injection in audit logs
- [ ] Add comprehensive error handling

### Phase 2: Compliance Fixes (2-3 hours)
- [ ] Add user attribution to audit logs
- [ ] Implement change control approval gates
- [ ] Add TOCTOU race condition fixes
- [ ] Enable backup encryption

### Phase 3: Hardening (1-2 hours)
- [ ] Add secrets scanning and redaction
- [ ] Set up git safety configuration
- [ ] Add snapshot name length validation
- [ ] Update documentation with data classification

### Phase 4: Testing (1 hour)
- [ ] Unit tests for input validation
- [ ] Integration tests for error handling
- [ ] Command injection tests
- [ ] Atomic operation tests

### Phase 5: Compliance Sign-Off (30 min)
- [ ] Security review of all fixes
- [ ] HIPAA compliance verification
- [ ] SOC 2 CC6.1 verification
- [ ] Sign-off document completion

---

## Deployment Gates

**DO NOT DEPLOY** until:
- [ ] All P0 fixes implemented and tested
- [ ] Security review completed
- [ ] Compliance assessment passed
- [ ] Sign-off document signed

**CAN DEPLOY TO STAGING** after:
- [ ] All P0 and P1 fixes complete
- [ ] Integration tests passing
- [ ] No P0 or P1 findings in final audit

**CAN DEPLOY TO PRODUCTION** after:
- [ ] All P0, P1, P2 fixes complete
- [ ] Full security audit passed
- [ ] HIPAA and SOC 2 compliance verified
- [ ] Security officer sign-off obtained

---

## Estimated Timeline

| Phase | Tasks | Hours | Completion Date |
|-------|-------|-------|-----------------|
| Phase 1 | P0 fixes | 2-3h | Today |
| Phase 2 | P1 fixes | 2-3h | Today + 1-2h |
| Phase 3 | P2 hardening | 1-2h | Today + 3-4h |
| Phase 4 | Testing | 1h | Today + 4-5h |
| Phase 5 | Sign-off | 0.5h | Today + 4.5-5.5h |

**Total: 6-8 hours to full remediation**

---

**Prepared by**: Claude Code Security Analyzer
**Date**: 2025-11-23
**Status**: READY FOR IMPLEMENTATION
