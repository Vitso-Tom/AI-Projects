# Snapshot System Integration Guide

**Version**: 1.0.0
**Last Updated**: 2025-11-23
**Audience**: SDLC agents, developers integrating snapshot awareness

Guide for integrating snapshot and rollback capabilities into agents and workflows.

---

## Table of Contents

1. [Integration Patterns](#integration-patterns)
2. [Agent Integration](#agent-integration)
3. [Configuration Options](#configuration-options)
4. [Safety Modes](#safety-modes)
5. [Report Integration](#report-integration)
6. [Error Handling](#error-handling)
7. [Best Practices](#best-practices)
8. [Examples](#examples)
9. [Troubleshooting Integration](#troubleshooting-integration)

---

## Integration Patterns

### Basic Pattern

Every agent that performs potentially risky operations should:

1. Source snapshot utilities
2. Perform safety check
3. Proceed with operation
4. Include snapshot info in report

```bash
#!/bin/bash
set -euo pipefail

# Step 1: Source utilities
source .claude/lib/snapshot-utils.sh

# Step 2: Safety check
if ! snapshot_safety_check "agent-name" "auto" "branch" "operation description"; then
    echo "Safety snapshot failed - aborting"
    exit 1
fi

# Step 3: Proceed with operation
perform_agent_work

# Step 4: Report with snapshot info
{
    echo "## Operation Results"
    echo "Status: Complete"
    echo ""
    get_snapshot_report_section "$SAFETY_SNAPSHOT_NAME" "agent-name"
} > report.md
```

### Three-Phase Pattern

```bash
#!/bin/bash

source .claude/lib/snapshot-utils.sh

echo "=== Phase 1: Safety Check ==="
if ! snapshot_safety_check "agent" "auto"; then
    exit 1
fi

echo "=== Phase 2: Operation ==="
# ... do actual work ...

echo "=== Phase 3: Report ==="
# ... include snapshot info ...
```

---

## Agent Integration

### Integration for Code Reviewer

```bash
#!/bin/bash
# File: .claude/agents/code-reviewer.sh

source .claude/lib/snapshot-utils.sh

echo "=== Code Reviewer Agent ==="

# Create safety checkpoint
if ! snapshot_safety_check "code-reviewer" "auto" "branch" "code review analysis"; then
    echo "Failed to create safety snapshot"
    exit 1
fi

echo "Safety snapshot: $SAFETY_SNAPSHOT_NAME"

# Perform code review
analyze_code_quality

# Suggest changes
suggest_refactoring

# Include recovery info in report
{
    echo "## Safety Information"
    echo ""
    get_snapshot_report_section "$SAFETY_SNAPSHOT_NAME" "code-reviewer"
} >> code-review-report.md
```

### Integration for Optimizer

```bash
#!/bin/bash
# File: .claude/agents/optimizer.sh

source .claude/lib/snapshot-utils.sh

echo "=== Optimizer Agent ==="

# Create checkpoint before potentially risky optimization
if ! snapshot_safety_check "optimizer" "auto" "branch" "performance optimization analysis"; then
    echo "Failed to create safety snapshot"
    exit 1
fi

echo "Optimization checkpoint: $SAFETY_SNAPSHOT_NAME"

# Perform optimization analysis
analyze_performance
suggest_optimizations

# Report with rollback capability
{
    echo "## Optimization Results"
    echo "Estimated improvement: X%"
    echo ""
    echo "### Recovery"
    get_snapshot_report_section "$SAFETY_SNAPSHOT_NAME" "optimizer"
} > optimization-report.md
```

### Integration for Test Runner

```bash
#!/bin/bash
# File: .claude/agents/test-runner.sh

source .claude/lib/snapshot-utils.sh

echo "=== Test Runner Agent ==="

# For test runs, use tag snapshots (fast, lightweight)
if ! snapshot_safety_check "test-runner" "auto" "tag" "test execution"; then
    echo "Failed to create test checkpoint"
    exit 1
fi

# Run test suite
run_tests

# Report test results
{
    echo "## Test Results"
    echo "Pass rate: $(get_pass_rate)%"
    echo "Failed tests: $(get_failed_count)"
    echo ""
    echo "### Rollback if Needed"
    get_snapshot_report_section "$SAFETY_SNAPSHOT_NAME" "test-runner"
} > test-report.md
```

### Integration for SDLC Workflow

```bash
#!/bin/bash
# File: .claude/commands/sdlc-workflow.sh

source .claude/lib/snapshot-utils.sh

echo "=== SDLC Workflow Pipeline ==="

# STEP 1: Create pre-workflow snapshot
echo "Step 1: Creating safety checkpoint..."
if ! snapshot_safety_check "sdlc-workflow" "auto" "branch" "SDLC pipeline execution"; then
    echo "Failed to create workflow checkpoint"
    exit 1
fi

SDLC_SNAPSHOT="$SAFETY_SNAPSHOT_NAME"
echo "✓ Checkpoint: $SDLC_SNAPSHOT"

# STEP 2: Run code review
echo ""
echo "Step 2: Running code review..."
/review

# STEP 3: Run tests
echo ""
echo "Step 3: Running tests..."
/test

# STEP 4: Run optimizer
echo ""
echo "Step 4: Running optimizer..."
/optimize

# STEP 5: Build
echo ""
echo "Step 5: Building..."
npm run build

# STEP 6: Report
echo ""
echo "Step 6: Generating report..."
{
    echo "# SDLC Workflow Report"
    echo ""
    echo "## Execution Summary"
    echo "- Code Review: Complete"
    echo "- Tests: Passed"
    echo "- Optimization: Complete"
    echo "- Build: Success"
    echo ""
    echo "## Safety & Recovery"
    get_snapshot_report_section "$SDLC_SNAPSHOT" "sdlc-workflow"
} > sdlc-report.md

echo "✓ Workflow complete"
```

---

## Configuration Options

### Safety Check Modes

```bash
# Interactive mode - prompts user if no snapshot
snapshot_safety_check "agent" "interactive" "branch"

# Automated mode - creates snapshot if needed
snapshot_safety_check "agent" "auto" "branch"

# Bypass mode - same as auto
snapshot_safety_check "agent" "bypass" "branch"
```

### Snapshot Types

```bash
# Quick snapshot (tag) - fast, lightweight
snapshot_safety_check "agent" "auto" "tag"

# Recovery branch - full history
snapshot_safety_check "agent" "auto" "branch"

# Full backup - complete repository
snapshot_safety_check "agent" "auto" "full"
```

### Operation Description

```bash
# Generic (uses agent name)
snapshot_safety_check "optimizer"

# Custom description
snapshot_safety_check "optimizer" "auto" "branch" "P0 optimization pass"

# Shows in audit trail and confirmation prompts
```

### Age Threshold

```bash
# Default: 25 minutes (5-minute safety buffer)
check_recent_snapshot

# Custom threshold: 60 minutes
check_recent_snapshot 60

# 5 minutes only
check_recent_snapshot 5
```

---

## Safety Modes

### Mode 1: Interactive (User-Driven)

**Use when**: Human is present and can make decisions

```bash
snapshot_safety_check "agent" "interactive" "branch"

# User sees:
# ⚠️  No recent snapshot detected
# Recommend creating snapshot before optimization.
#
# Options:
# 1. Create snapshot now (recommended)
# 2. Continue without snapshot (not recommended)
#
# Choice [1/2]:
```

**User Can**:
- Choose to create snapshot
- Choose to proceed anyway
- Decide on snapshot type
- Add custom description

---

### Mode 2: Automated (Agent-Driven)

**Use when**: Running in automated pipeline with no user interaction

```bash
snapshot_safety_check "agent" "auto" "branch"

# System:
# - Checks for recent snapshot
# - Creates one if needed (no prompts)
# - Proceeds with operation
```

**Benefits**:
- No blocking prompts
- Always safe (snapshot guaranteed)
- Suitable for CI/CD pipelines
- Automatic recovery point

---

## Report Integration

### Include Snapshot Info in Reports

```bash
# Generate snapshot report section
get_snapshot_report_section "$SAFETY_SNAPSHOT_NAME" "agent-name"
```

**Output**:
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

### Adding to Reports

```bash
#!/bin/bash
source .claude/lib/snapshot-utils.sh

snapshot_safety_check "my-agent" "auto"

# Build report
{
    echo "# Agent Report"
    echo ""
    echo "## Results"
    echo "Operation completed successfully"
    echo ""
    echo "## Safety & Recovery"
    get_snapshot_report_section "$SAFETY_SNAPSHOT_NAME" "my-agent"
} > report.md
```

---

## Error Handling

### Check Return Codes

```bash
source .claude/lib/snapshot-utils.sh

# snapshot_safety_check returns 0 on success
if snapshot_safety_check "agent" "auto"; then
    echo "Snapshot ready, proceeding..."
else
    echo "Failed to establish safety snapshot"
    exit 1
fi
```

### Validate Individual Functions

```bash
# Check individual functions
if ! validate_agent_name "$agent"; then
    echo "Invalid agent name"
    exit 1
fi

if ! validate_git_repository; then
    echo "Not a git repository"
    exit 1
fi

if ! check_recent_snapshot; then
    echo "No recent snapshot"
    # Decide what to do
fi
```

### Handle Missing Library

```bash
# Verify library exists before sourcing
if [[ ! -f .claude/lib/snapshot-utils.sh ]]; then
    echo "Error: snapshot-utils.sh not found"
    exit 1
fi

source .claude/lib/snapshot-utils.sh
```

### Graceful Degradation

```bash
source .claude/lib/snapshot-utils.sh 2>/dev/null

# Proceed without snapshots if library unavailable
if [[ $? -ne 0 ]]; then
    echo "Warning: Snapshot support unavailable"
    SKIP_SNAPSHOT=true
fi

if [[ -z "${SKIP_SNAPSHOT:-}" ]]; then
    snapshot_safety_check "agent" "auto"
fi
```

---

## Best Practices

### Before Every Operation

```bash
# 1. Always source library at top of agent
source .claude/lib/snapshot-utils.sh

# 2. Check safety early
if ! snapshot_safety_check "agent-name" "auto" "branch"; then
    echo "Safety check failed - aborting"
    exit 1
fi

# 3. Use result in operations
echo "Snapshot available: $SAFETY_SNAPSHOT_NAME"

# 4. Include in report
get_snapshot_report_section "$SAFETY_SNAPSHOT_NAME" "agent-name"
```

### Naming Conventions

```bash
# ✓ Good - Descriptive operation
snapshot_safety_check "code-reviewer" "auto" "branch" "code quality analysis"

# ✓ Good - Agent-based
snapshot_safety_check "optimizer" "auto" "branch"

# ✓ Good - P-level indication
snapshot_safety_check "security-analyzer" "auto" "branch" "P0 vulnerability scan"

# ✗ Bad - Too vague
snapshot_safety_check "agent" "auto" "branch" "operation"

# ✗ Bad - Incomplete
snapshot_safety_check "agent" "auto"  # Missing description
```

### Mode Selection

```bash
# Use INTERACTIVE for:
# - Development/testing
# - When user can make decisions
# - Debugging agent issues
if [[ "$DEBUG" == "true" ]]; then
    MODE="interactive"
else
    MODE="auto"
fi

snapshot_safety_check "agent" "$MODE" "branch"
```

### Type Selection

```bash
# For quick operations: tag
snapshot_safety_check "agent" "auto" "tag" "minor change"

# For major operations: branch
snapshot_safety_check "agent" "auto" "branch" "major refactoring"

# For critical operations: full
snapshot_safety_check "agent" "auto" "full" "production deployment"
```

### Timeout Handling

```bash
# For operations with timeouts
if timeout 300 snapshot_safety_check "agent" "auto"; then
    echo "Safety check complete"
    # Proceed with operation
else
    echo "Safety check timeout or failure"
    exit 1
fi
```

---

## Examples

### Example 1: Minimal Integration

```bash
#!/bin/bash
source .claude/lib/snapshot-utils.sh

snapshot_safety_check "my-agent" "auto" || exit 1
# ... do work ...
echo "Snapshot: $SAFETY_SNAPSHOT_NAME"
```

### Example 2: Full Integration

```bash
#!/bin/bash
set -euo pipefail

source .claude/lib/snapshot-utils.sh

REPORT_FILE="report.md"

# Safety check
echo "=== Pre-Flight Checks ==="
if ! validate_git_repository; then
    echo "Not in git repository"
    exit 1
fi

if ! snapshot_safety_check "analysis-agent" "auto" "branch" "detailed analysis run"; then
    echo "Failed to create safety snapshot"
    exit 1
fi

echo "✓ Safety snapshot: $SAFETY_SNAPSHOT_NAME"

# Run analysis
echo ""
echo "=== Running Analysis ==="
analyze_codebase > /tmp/analysis.txt
ANALYSIS_RESULT=$(<tmp/analysis.txt)

# Generate report
echo ""
echo "=== Generating Report ==="
{
    echo "# Analysis Report"
    echo ""
    echo "## Results"
    echo "$ANALYSIS_RESULT"
    echo ""
    echo "## Safety Information"
    get_snapshot_report_section "$SAFETY_SNAPSHOT_NAME" "analysis-agent"
} > "$REPORT_FILE"

echo "✓ Report: $REPORT_FILE"
```

### Example 3: Conditional Integration

```bash
#!/bin/bash
source .claude/lib/snapshot-utils.sh

# Only create snapshot for major operations
CHANGES=$(git diff --stat | tail -n 1 | awk '{print $1}')

if [[ $CHANGES -gt 20 ]]; then
    echo "Large changeset detected ($CHANGES files)"
    if ! snapshot_safety_check "agent" "auto" "branch"; then
        exit 1
    fi
    USE_SNAPSHOT=true
else
    echo "Small changeset - snapshot optional"
    USE_SNAPSHOT=false
fi

# ... proceed with operation ...

if [[ "$USE_SNAPSHOT" == "true" ]]; then
    get_snapshot_report_section "$SAFETY_SNAPSHOT_NAME" "agent"
fi
```

### Example 4: Pipeline Integration

```bash
#!/bin/bash
# SDLC-aware pipeline with snapshots

source .claude/lib/snapshot-utils.sh

SNAPSHOT_NAME=""

# Pipeline stages
run_stage() {
    local stage_name="$1"
    local stage_cmd="$2"

    echo ""
    echo "=== Stage: $stage_name ==="

    if $stage_cmd; then
        echo "✓ $stage_name: PASSED"
        return 0
    else
        echo "✗ $stage_name: FAILED"
        return 1
    fi
}

# Pre-pipeline snapshot
if ! snapshot_safety_check "pipeline" "auto" "branch" "pre-pipeline checkpoint"; then
    echo "Failed to create pipeline snapshot"
    exit 1
fi

SNAPSHOT_NAME="$SAFETY_SNAPSHOT_NAME"

# Run pipeline stages
run_stage "Code Review" "/review" || FAILURE=true
run_stage "Tests" "/test" || FAILURE=true
run_stage "Build" "npm run build" || FAILURE=true

# Report
{
    echo "# Pipeline Report"
    echo ""
    if [[ -z "${FAILURE:-}" ]]; then
        echo "Status: SUCCESS"
    else
        echo "Status: FAILED (see details below)"
    fi
    echo ""
    echo "## Recovery"
    get_snapshot_report_section "$SNAPSHOT_NAME" "pipeline"
} > pipeline-report.md

if [[ -z "${FAILURE:-}" ]]; then
    exit 0
else
    exit 1
fi
```

---

## Troubleshooting Integration

### Library Not Found

**Error**: `source: command not found`

**Solution**:
```bash
# Verify library path
ls -la .claude/lib/snapshot-utils.sh

# Use absolute path if needed
source /absolute/path/to/.claude/lib/snapshot-utils.sh
```

### Function Not Available

**Error**: `command not found: snapshot_safety_check`

**Solution**:
```bash
# Verify library sourced
source .claude/lib/snapshot-utils.sh

# Check functions exist
declare -f snapshot_safety_check

# If missing, re-source
unset -f snapshot_safety_check
source .claude/lib/snapshot-utils.sh
```

### Safety Check Always Fails

**Error**: `snapshot_safety_check: command not found: validate_git_repository`

**Solution**:
```bash
# Library functions depend on each other
# Make sure sourcing is first command

#!/bin/bash
source .claude/lib/snapshot-utils.sh  # Must be first

# Now functions available
snapshot_safety_check "agent" "auto"
```

### Variables Not Exported

**Error**: `$SAFETY_SNAPSHOT_NAME` is empty

**Solution**:
```bash
# Function must succeed
if snapshot_safety_check "agent" "auto"; then
    # Now variables are available
    echo "$SAFETY_SNAPSHOT_NAME"
else
    echo "Function failed - variables not set"
fi
```

### Repository Issues

**Error**: `✗ Not a git repository`

**Solution**:
```bash
# Verify you're in git repository
git rev-parse --git-dir

# Initialize if needed
cd /path/to/repo
git init
```

---

## Extending the System

### Creating Wrapper Functions

```bash
#!/bin/bash
# Add to your agent script

source .claude/lib/snapshot-utils.sh

# Wrapper for your specific needs
safe_operation() {
    local operation_name="$1"
    local operation_cmd="$2"

    # Always create snapshot
    if ! snapshot_safety_check "$operation_name" "auto" "branch"; then
        echo "Failed to create safety snapshot"
        return 1
    fi

    echo "Snapshot: $SAFETY_SNAPSHOT_NAME"

    # Run operation
    if $operation_cmd; then
        echo "✓ Operation succeeded"
        return 0
    else
        echo "✗ Operation failed"
        echo "Rollback available: /snapshot --restore $SAFETY_SNAPSHOT_NAME"
        return 1
    fi
}

# Use wrapper
safe_operation "my-agent" "perform_critical_task"
```

### Custom Safety Checks

```bash
#!/bin/bash
source .claude/lib/snapshot-utils.sh

# Add custom checks
custom_safety_check() {
    # Check 1: Snapshot
    if ! snapshot_safety_check "agent" "auto"; then
        return 1
    fi

    # Check 2: Build health
    if ! npm run build > /dev/null 2>&1; then
        echo "Build is broken - aborting"
        return 1
    fi

    # Check 3: Tests
    if ! npm test > /dev/null 2>&1; then
        echo "Tests are failing - aborting"
        return 1
    fi

    return 0
}

# Use
custom_safety_check || exit 1
```

---

## Version Compatibility

| Feature | Introduced | Status |
|---------|-----------|--------|
| Basic snapshot | 1.0.0 | Stable |
| Safety checks | 1.0.0 | Stable |
| Audit logging | 1.0.0 | Stable |
| HIPAA compliance | 1.0.0 | Stable |
| SOC 2 compliance | 1.0.0 | Stable |

---

**Version**: 1.0.0
**Last Updated**: 2025-11-23
**Maintained By**: Tom Vitso + Claude Code
