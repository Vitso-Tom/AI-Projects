# Snapshot System User Guide

**Version**: 1.0.0
**Last Updated**: 2025-11-23
**Audience**: All users (developers, agents, operators)

Practical guide to using snapshots and rollbacks for safe experimentation and emergency recovery.

---

## Table of Contents

1. [Quick Decision Tree](#quick-decision-tree)
2. [When to Use Snapshots](#when-to-use-snapshots)
3. [Snapshot Types Explained](#snapshot-types-explained)
4. [Interactive vs Automated](#interactive-vs-automated)
5. [Creating Snapshots](#creating-snapshots)
6. [Listing & Viewing Snapshots](#listing--viewing-snapshots)
7. [Restoring Snapshots](#restoring-snapshots)
8. [Rollback Procedures](#rollback-procedures)
9. [Common Workflows](#common-workflows)
10. [Troubleshooting](#troubleshooting)

---

## Quick Decision Tree

### Do I Need a Snapshot?

```
┌─ Are you about to make significant code changes?
│  ├─ YES → Create snapshot (Type: Branch or Full)
│  └─ NO  → Continue
│
├─ Are you running an agent that suggests changes?
│  ├─ YES → Agent should auto-create snapshot
│  └─ NO  → Continue
│
├─ Are you running SDLC workflow?
│  ├─ YES → Create recovery branch snapshot
│  └─ NO  → Continue
│
├─ Are you testing something experimental?
│  ├─ YES → Create quick snapshot (Tag)
│  └─ NO  → Continue
│
└─ Are you about to deploy to production?
   ├─ YES → Create FULL backup bundle
   └─ NO  → NO SNAPSHOT NEEDED
```

### Which Snapshot Type?

```
┌─ How significant is the change?
│
├─ SMALL (< 10 files, < 100 lines)
│  └─ Use: Quick Snapshot (tag)
│     Command: /snapshot "description"
│
├─ MEDIUM (10-50 files, 100-1000 lines)
│  └─ Use: Recovery Branch
│     Command: /snapshot --branch "description"
│
├─ LARGE (> 50 files, > 1000 lines)
│  └─ Use: Full Backup Bundle
│     Command: /snapshot --full "description"
│
└─ CRITICAL (Architecture, Production)
   └─ Use: Full Backup Bundle + Tag
      Command: /snapshot --full "description"
```

---

## When to Use Snapshots

### Always Snapshot Before

- **Major Refactoring**: Changes to >20 files
- **SDLC Workflow Runs**: Full test/build/deploy pipelines
- **Dependency Upgrades**: Changes to package.json, requirements.txt, etc.
- **Architectural Changes**: Database schema, API endpoints, etc.
- **Agent-Suggested Changes**: Code review refactoring, optimization changes
- **Production Deployments**: Critical live environment changes
- **Authentication Changes**: Security-sensitive modifications

### Consider Snapshot Before

- **Configuration Changes**: `.env`, config files, settings
- **Slash Command Modifications**: Adding/modifying `/commands`
- **Agent Configuration Updates**: `.claude/agents/*.md`
- **Database Migrations**: Schema changes
- **API Endpoint Changes**: New/modified REST endpoints
- **Build Process Changes**: Webpack, build scripts, etc.

### No Snapshot Needed For

- **Documentation Only**: README, comments, docs
- **Style Fixes**: Formatting, whitespace, linting
- **Minor Bug Fixes**: Single file, well-understood changes
- **Read-Only Operations**: Viewing files, querying databases
- **Already Committed**: Changes already pushed to main

### Decision Framework

| Change Type | Impact | Need Snapshot? | Type |
|-------------|--------|---|---|
| 1 file, 10 lines | Low | Maybe | Quick |
| Config file | Medium | Yes | Quick |
| 20 file refactor | High | YES | Branch |
| Dependency upgrade | Medium | YES | Quick |
| Architecture change | Critical | YES | Full |
| Documentation | None | No | - |
| Production deploy | Critical | YES | Full |

---

## Snapshot Types Explained

### Type 1: Quick Snapshot (Git Tag)

**What it is**: A lightweight pointer to current state, like a game save

**Best for**:
- Minor experiments and tweaks
- Configuration changes
- Quick checkpoint during development
- Testing new parameters
- Before config file changes

**How to create**:
```bash
/snapshot "description"                    # Default to quick
/snapshot "before-config-tweak"            # Implicit quick
```

**Size & Speed**:
- Creation: Instant (< 1 second)
- Storage: Minimal (< 1 MB)
- Number: Can create many without disk concerns

**Recovery**:
```bash
/snapshot --restore before-config-tweak
```

**Pros**:
- Fast creation (no commits needed)
- Minimal disk usage
- Perfect for non-critical experiments
- Easy to list and manage

**Cons**:
- Only points to current commit
- Doesn't preserve uncommitted work
- Not suitable for major changes
- Limited history

**Example Scenario**:
```bash
# Testing a config parameter
/snapshot "before-param-test"

# Modify config
vi .env.local

# Run experiment
npm test

# Something went wrong?
/snapshot --restore before-param-test
```

---

### Type 2: Recovery Branch

**What it is**: A full git branch with complete history and ability to develop

**Best for**:
- Major refactoring (>20 files)
- SDLC workflow runs
- Risky agent operations
- Dependency upgrades
- Architectural experimentation
- Complex changes that might need rework

**How to create**:
```bash
/snapshot --branch "description"
/snapshot --branch "pre-optimization"      # Explicit branch
```

**Size & Speed**:
- Creation: 1-5 seconds (no new commits)
- Storage: Minimal (just branch pointer)
- Number: Keep < 20 active (cleanup monthly)

**Recovery**:
```bash
/snapshot --restore pre-optimization
```

**Pros**:
- Complete commit history preserved
- Can develop on branch if needed
- Easy to cherry-pick changes
- Clear in git log
- Suitable for major operations

**Cons**:
- More overhead than quick snapshot
- Need to manage branch cleanup
- Can create confusion with many branches

**Example Scenario**:
```bash
# Major refactoring coming
/snapshot --branch "pre-large-refactor"

# Run code reviewer with big changes
/optimize

# Something broke badly?
/snapshot --restore pre-large-refactor
# Also: git merge snapshot/pre-large-refactor to cherry-pick some changes
```

---

### Type 3: Full Backup (Git Bundle)

**What it is**: Complete offline backup of entire repository

**Best for**:
- Production deployments
- Major architectural overhauls
- Repository migration preparation
- Critical milestones
- Disaster recovery preparation
- Monthly backups

**How to create**:
```bash
/snapshot --full "description"
/snapshot --full "production-deploy-20250123"
```

**Size & Speed**:
- Creation: 10-30 seconds (depends on repo size)
- Storage: ~same size as `.git` directory
- Number: Keep < 10 (monthly rotation)

**Location**: `~/ai-workspace/backups/snapshot-NAME.bundle`

**Recovery**:
```bash
# Clone bundle as new repo
git clone ~/ai-workspace/backups/snapshot-production-deploy-20250123.bundle recovery

# Or restore into existing repo
cd existing-repo
git fetch ~/ai-workspace/backups/snapshot-NAME.bundle refs/*:refs/remotes/backup/*
```

**Pros**:
- Complete offline backup
- Survives repository corruption
- Portable to other machines
- Includes all history and branches
- Best for disaster recovery

**Cons**:
- Slower creation
- Takes significant disk space
- Need to manage cleanup
- Requires more disk space for recovery

**Example Scenario**:
```bash
# Before major production deployment
/snapshot --full "pre-prod-deploy-20250123"

# Deploy to production
/deploy

# Production broken - complete rollback available
git clone ~/ai-workspace/backups/snapshot-pre-prod-deploy-20250123.bundle recovery
```

---

## Interactive vs Automated

### Interactive Mode (User-Driven)

When to use:
- During development when you're making decisions
- When running agents in supervised mode
- When experimenting with different approaches

```bash
# Creates snapshot and asks user
/snapshot                               # Interactive prompts

# Agent checks and asks user
if snapshot_safety_check "agent" "interactive"; then
    proceed_with_operation
fi
```

**User Flow**:
1. Agent or user initiates operation
2. System checks for recent snapshot
3. If no snapshot found, asks: "Create snapshot now?"
4. User chooses: Create or Continue anyway
5. Snapshot created or skipped based on choice

**When User Gets Prompted**:
- Running major optimization
- Starting large refactoring
- Running SDLC workflow
- Any risky agent operation

---

### Automated Mode (Agent-Driven)

When to use:
- Fully automated pipelines
- CI/CD workflows
- Unattended agent runs
- When you want guaranteed safety backup

```bash
# Creates snapshot automatically if needed
/snapshot "description" --auto

# Agent with auto-mode
if snapshot_safety_check "agent" "auto" "branch"; then
    proceed_with_operation
fi
```

**System Flow**:
1. Agent initiates operation
2. System checks for recent snapshot
3. If found: Use existing snapshot
4. If not found: Automatically create new one
5. Proceed with operation
6. Never prompts user

**Best For**:
- SDLC workflows
- Build pipelines
- Test runs
- Optimization passes
- Any automated operation

---

## Creating Snapshots

### Method 1: Quick Snapshot (Default)

Fastest way to create save point.

```bash
/snapshot "before-experiment"
```

**What happens**:
1. Checks git repository
2. Detects uncommitted changes
3. Offers to commit them
4. Creates git tag: `snapshot-before-experiment-TIMESTAMP`
5. Logs to agents.md

**Output**:
```
✓ Quick snapshot created: snapshot-before-experiment-20250123-143022 (tag)
  Commit: abc123f45678
  Branch: main
  Files changed: 5 files changed, 123 insertions(+), 45 deletions(-)
  Restore with: /snapshot --restore before-experiment-20250123-143022
```

---

### Method 2: Recovery Branch

For major operations.

```bash
/snapshot --branch "pre-major-refactor"
```

**What happens**:
1. Validates repository
2. Creates recovery branch: `snapshot/pre-major-refactor-TIMESTAMP`
3. Returns to original branch
4. Logs to agents.md with statistics

**Output**:
```
✓ Recovery branch created: snapshot/pre-major-refactor-20250123-143022
  Commit: abc123f45678
  Branch: main
  Files changed: 47 files changed, 892 insertions(+), 234 deletions(-)
  Restore with: /snapshot --restore pre-major-refactor-20250123-143022
```

---

### Method 3: Full Backup

For critical snapshots.

```bash
/snapshot --full "production-checkpoint"
```

**What happens**:
1. Validates repository
2. Checks available disk space
3. Creates bundle: `snapshot-production-checkpoint-TIMESTAMP.bundle`
4. Saves to: `~/ai-workspace/backups/`
5. Logs to agents.md with bundle details

**Output**:
```
✓ Full backup created: snapshot-production-checkpoint-20250123-143022.bundle
  Location: ~/ai-workspace/backups/snapshot-production-checkpoint-20250123-143022.bundle
  Size: 125 MB
  Includes: All branches, all history
  Restore with: git clone [backup-path] recovery-repo
```

---

### Handling Uncommitted Changes

When snapshot finds uncommitted changes, offers options:

```
⚠️  Uncommitted changes detected:
  M  src/app.js
  ??  test.js

Options:
1. Commit changes first (recommended)
2. Include uncommitted changes in snapshot (will auto-commit)
3. Stash changes and snapshot clean state
4. Abort snapshot
```

**Option 1: Commit First** (Recommended)
```bash
# User commits their work
git add . && git commit -m "WIP: my changes"

# Then retry snapshot
/snapshot "after-commits"
```

**Option 2: Auto-Commit**
```bash
# System auto-commits with marker
# Snapshot includes the auto-commit
# Good for quick checkpoints
```

**Option 3: Stash & Snapshot**
```bash
# System stashes changes
git stash
# Takes snapshot of clean state
# Changes preserved in stash for later
```

---

## Listing & Viewing Snapshots

### List All Snapshots

```bash
/snapshot --list
```

**Output**:
```
=== Snapshot Summary ===
Quick snapshots (tags): 5
  before-experiment
  pre-optimization
  config-test
  checkpoint-1
  checkpoint-2

Recovery branches: 2
  snapshot/pre-major-refactor-20250123-143022
  snapshot/pre-sdlc-run-20250122-120000

Full backups: 1
  snapshot-production-checkpoint-20250123-143022.bundle (125 MB)

Total snapshots: 8
```

---

### List by Type

```bash
/snapshot --list --type quick           # Only tags
/snapshot --list --type branch          # Only branches
/snapshot --list --type full            # Only bundles
```

---

### View Snapshot Details

```bash
/snapshot --show before-experiment

# Output includes:
# - Commit hash
# - Files changed
# - Summary of changes
# - Timestamp
# - Creator info
```

---

### Compare Snapshots

```bash
/snapshot --diff before-experiment

# Shows:
# - What changed since this snapshot
# - File statistics
# - Line-by-line diff (optional)
```

---

## Restoring Snapshots

### Safe Restoration Process

#### Step 1: Verify Current State

```bash
git status                          # Check for uncommitted work
git log --oneline -5                # Show recent commits
```

#### Step 2: List Available Snapshots

```bash
/snapshot --list

# Note the name of snapshot you want to restore
```

#### Step 3: Show Snapshot Preview

```bash
/snapshot --show pre-optimization

# Review what state you're restoring to
```

#### Step 4: Show Changes Since Snapshot

```bash
/snapshot --diff pre-optimization

# See what work will be lost/kept
```

#### Step 5: Commit Uncommitted Work (If Needed)

```bash
# If you have uncommitted changes that you want to keep:
git add .
git commit -m "Save current work before restoring snapshot"

# OR if you want to discard them:
git checkout .              # Discard all changes
```

#### Step 6: Restore Snapshot

```bash
/snapshot --restore pre-optimization

# OR use git directly:
git checkout snapshot/pre-optimization-20250123-143022
git checkout tags/snapshot-before-experiment-20250123-143022
```

**What happens**:
1. Creates backup of current state: `snapshot/before-restore-TIMESTAMP`
2. Restores working directory to snapshot state
3. Logs restoration to agents.md
4. Shows verification info

#### Step 7: Verify Restoration

```bash
git log --oneline -3              # Verify HEAD is at right commit
git status                        # Should be clean
ls -la                           # Files should match snapshot
```

#### Step 8: Test

```bash
# If applicable:
npm test                          # Run tests
npm run build                     # Try build
./run-verification.sh             # Run project tests
```

---

## Rollback Procedures

### When to Use Rollback

Rollback is for **undoing commits after they've been made**, not for restoring snapshots.

**Use rollback when**:
- Recent commit is broken
- Test suite started failing after commit
- Build is broken
- Changes caused unexpected issues

**Use snapshot restore when**:
- Want to go back to major checkpoint
- Major operation went wrong
- Want point-in-time recovery

---

### Quick Rollback Options

#### Option 1: Undo Last Commit (Safe)

```bash
/rollback --soft              # Keep changes in working directory
# Changes are available to recommit differently
```

#### Option 2: Undo & Review Changes

```bash
/rollback --mixed             # Default - undo commit, keep file changes
git status                    # See what changed
# Recommit if needed, or discard
```

#### Option 3: Undo & Delete Changes

```bash
/rollback --hard              # ⚠️  DESTRUCTIVE - requires confirmation
# Changes are deleted, cannot recover
```

#### Option 4: Revert Instead (For Shared Branches)

```bash
/rollback --revert abc123     # Create new commit that undoes abc123
git log                       # Shows revert commit
# Safer for already-pushed commits
```

---

### Multi-Commit Rollback

```bash
# Undo last 3 commits
/rollback --soft 3

# OR specify exact number
/rollback --mixed 5
```

---

### Rollback to Specific Commit

```bash
# Find commit hash
git log --oneline

# Rollback to specific hash
/rollback --to abc123def
```

---

## Common Workflows

### Workflow 1: Testing a Configuration Change

```bash
# Step 1: Create quick snapshot
/snapshot "before-config-test"

# Step 2: Make change
vi config.json

# Step 3: Test
npm run test-config

# Step 4a: If it works
git add config.json && git commit -m "Update config"

# Step 4b: If it doesn't work
/snapshot --restore before-config-test
vi config.json  # Try different approach
```

---

### Workflow 2: Major Refactoring

```bash
# Step 1: Create recovery branch (important!)
/snapshot --branch "pre-refactor-large"

# Step 2: Run code reviewer to suggest changes
/review --suggest-refactor

# Step 3: Implement suggestions
# ... multiple commits during refactoring ...

# Step 4: Run tests
/test

# Step 4a: If tests pass
git log                        # Verify history looks good
# Continue working

# Step 4b: If tests fail
/snapshot --restore pre-refactor-large
# Try different refactoring approach
```

---

### Workflow 3: SDLC Pipeline

```bash
# Step 1: System auto-creates snapshot
/snapshot --branch "pre-sdlc"

# Step 2: Run SDLC pipeline
/sdlc run

# Step 3: Pipeline completes
# ... review results ...

# Step 3a: Results are good
# Snapshot serves as checkpoint for this version

# Step 3b: Something broken
/snapshot --restore pre-sdlc
# Fix issues and retry
/sdlc run
```

---

### Workflow 4: Production Deployment

```bash
# Step 1: Create full backup (critical!)
/snapshot --full "pre-deployment-20250123"

# Step 2: Verify backup created
ls -lh ~/ai-workspace/backups/snapshot-pre-deployment*.bundle

# Step 3: Deploy
/deploy

# Step 4: Monitor and test
# ... verify deployment ...

# Step 4a: Deployment successful
echo "✓ Deployment complete"

# Step 4b: Major issue found
# Restore from full backup
git clone ~/ai-workspace/backups/snapshot-pre-deployment-20250123.bundle recovery
# Then redeploy from backup
```

---

### Workflow 5: Emergency Recovery

```bash
# Something is seriously broken right now

# Option 1: Quick rollback of last commit
/rollback --soft 1
# Review what changed
git status
# Either fix or discard

# Option 2: Rollback multiple commits
/rollback --hard 3
# Confirm with "YES, DELETE CHANGES"
# Back to 3 commits ago

# Option 3: Restore from snapshot
/snapshot --list
/snapshot --restore pre-optimization
# Back to major checkpoint

# Option 4: Restore from full backup (last resort)
git clone ~/ai-workspace/backups/snapshot-production-checkpoint.bundle recovery
# Complete recovery
```

---

## Troubleshooting

### "Snapshot creation failed"

**Check repository health**:
```bash
git status                    # Should show clean or modified files
git fsck --full              # Check for corruption
```

**If repository is corrupted**:
```bash
# Try to recover
git fsck --full --lost-found

# Or restore from full backup
git clone ~/ai-workspace/backups/snapshot-*.bundle recovery
```

---

### "Cannot restore snapshot"

**Verify snapshot exists**:
```bash
git tag -l snapshot-*                     # Check tags
git branch -l snapshot/*                  # Check branches
ls ~/ai-workspace/backups/snapshot-*.bundle  # Check bundles
```

**If snapshot missing**:
```bash
/snapshot --list              # Show what's available
# Create new snapshot
/snapshot "new-checkpoint"
```

---

### "Rollback didn't work"

**Check what happened**:
```bash
git log --oneline -5          # See current HEAD
git status                    # Check for uncommitted work
```

**Undo the rollback**:
```bash
# If you created backup, restore from it
git reset --hard backup-before-rollback-TIMESTAMP

# OR redo the operation
git reset --hard HEAD@{1}     # Go back one step in reflog
```

---

### "Out of disk space"

**For quick snapshots**:
```bash
/snapshot --cleanup           # Remove old snapshots
git gc --aggressive           # Garbage collect
```

**For full backups**:
```bash
# Remove old bundles
rm ~/ai-workspace/backups/snapshot-*.bundle

# Verify disk space
df -h
du -sh ~/ai-workspace/.git
```

---

### "Uncommitted changes conflict"

**Option 1: Commit before snapshot**:
```bash
git add .
git commit -m "Checkpoint before operation"
/snapshot "next-checkpoint"
```

**Option 2: Stash changes**:
```bash
git stash
/snapshot "clean-state"
git stash pop  # Restore changes later
```

**Option 3: Include in snapshot**:
```bash
/snapshot "description"
# Choose option 2: "Include uncommitted changes"
```

---

### "Restoration lost my work"

**Don't panic - recovery is possible**:

```bash
# Check reflog (recent actions)
git reflog

# Find your work's commit
git log --all --oneline | grep "work description"

# Restore from backup branch
git reset --hard backup-before-restore-TIMESTAMP

# OR check in stash
git stash list

# OR restore from snapshot
/snapshot --list
/snapshot --restore different-snapshot
```

---

### "Need to merge snapshot changes back"

**If you restored snapshot but want some changes**:

```bash
# Create branch with those changes
git branch temp-changes abc123def

# Go back to main
git checkout main

# Cherry-pick specific commits
git cherry-pick abc123
git cherry-pick def456

# Or merge partial changes
git merge --no-ff temp-changes
```

---

## Tips & Best Practices

### Before Each Agent Run

```bash
# Check if snapshot is available
git tag -l snapshot-* | head -5

# If not recent, create one
/snapshot --branch "pre-agent-run"
```

### Naming Snapshots

**Good names**:
- `before-optimization`
- `pre-sdlc-run`
- `checkpoint-stable`
- `before-migration`

**Bad names**:
- `test` (too vague)
- `backup` (not descriptive)
- `1`, `2`, `3` (meaningless)
- `asdf` (random)

### Cleanup Strategy

**Monthly**:
```bash
/snapshot --cleanup          # Remove snapshots > 30 days old
```

**Before major operations**:
```bash
/snapshot --list
/snapshot --cleanup --keep-recent 10
```

### Testing Restoration

**Periodically verify snapshots work**:
```bash
/snapshot --list
/snapshot --show important-snapshot

# In a test directory:
git clone /path/to/backup.bundle test-recovery
cd test-recovery
git log           # Verify history is intact
```

---

**Updated**: 2025-11-23
**Version**: 1.0.0
**Maintained By**: Tom Vitso + Claude Code
