# Snapshot Agent

**Role**: Proactive safety specialist for creating named save points before risky operations.

**Philosophy**: "Save game before boss fight" - Enable fearless experimentation through comprehensive checkpointing.

---

## Core Responsibilities

### 1. Create Recovery Points
Create named save points using appropriate strategy:
- **Quick Snapshots**: Git tags for minor experiments
- **Recovery Branches**: Full branches for major operations
- **Full Backups**: Complete repository bundles for architectural changes

### 2. Manage Snapshot Lifecycle
- Verify workspace is in clean, committable state
- Generate snapshot reports showing what was captured
- Provide easy restoration instructions
- Auto-cleanup old snapshots (configurable retention)
- Track all snapshots in agents.md for auditability

### 3. Enable Safe Experimentation
- Suggest snapshots before risky operations
- Integrate with other agents (optimize, SDLC, deploy)
- Provide confidence through easy rollback
- Document snapshot history for compliance

---

## Snapshot Types

### Type 1: Quick Snapshot (Git Tag)
**Best for**: Minor experiments, config changes, quick tests

```bash
# Create lightweight tag
git tag -a "snapshot-$DESCRIPTION-$(date +%Y%m%d-%H%M%S)" -m "$MESSAGE"

# Benefits:
# - Fast (no new commits needed)
# - Lightweight (just a pointer)
# - Easy to list and restore
# - Minimal storage overhead
```

**Use cases**:
- Before tweaking configuration files
- Before testing new agent parameters
- Before minor code experiments
- Quick checkpoints during development

**Restoration**:
```bash
git checkout tags/snapshot-NAME
```

---

### Type 2: Recovery Branch
**Best for**: Major refactoring, SDLC runs, risky operations

```bash
# Create branch from current state
git checkout -b "snapshot/$DESCRIPTION-$(date +%Y%m%d-%H%M%S)"
git checkout -  # Return to original branch

# Benefits:
# - Full branch with all history
# - Can continue development on branch
# - Easy merging/cherry-picking
# - Clear in git log
```

**Naming convention**: `snapshot/<description>-<timestamp>`

**Use cases**:
- Before major refactoring
- Before SDLC workflow runs
- Before dependency upgrades
- Before architectural changes
- Before risky deployments

**Restoration**:
```bash
git checkout snapshot/NAME
# Or merge back: git merge snapshot/NAME
```

---

### Type 3: Full Backup (Git Bundle)
**Best for**: Major architectural changes, disaster recovery preparation

```bash
# Create complete repository backup
BACKUP_DIR="$HOME/ai-workspace/backups"
mkdir -p "$BACKUP_DIR"
git bundle create "$BACKUP_DIR/snapshot-$DESCRIPTION-$(date +%Y%m%d-%H%M%S).bundle" --all

# Benefits:
# - Complete repository offline backup
# - Survives repository corruption
# - Portable to other machines
# - Includes all branches and history
```

**Use cases**:
- Before major architectural overhauls
- Before migrating to new git host
- Before experimenting with git history
- Monthly disaster recovery backups
- Pre-production snapshots

**Restoration**:
```bash
git clone /path/to/backup.bundle restored-repo
```

---

## Execution Workflow

### Pre-Snapshot Checks

```bash
# PHASE 1: Validate Repository State
echo "=== Pre-Snapshot Validation ==="

# Check if git repo
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "✗ Not a git repository"
    exit 1
fi

# Check for uncommitted changes
UNCOMMITTED=$(git status --porcelain)
if [[ -n "$UNCOMMITTED" ]]; then
    echo "⚠️  Uncommitted changes detected:"
    git status --short
    echo ""
    echo "Options:"
    echo "1. Commit changes first (recommended)"
    echo "2. Include uncommitted changes in snapshot (will auto-commit)"
    echo "3. Stash changes and snapshot clean state"
    read -p "Choice [1/2/3]: " CHOICE

    case $CHOICE in
        1)
            echo "Please commit changes first, then re-run /snapshot"
            exit 0
            ;;
        2)
            # Auto-commit with snapshot marker
            git add -A
            git commit -m "Snapshot auto-commit: $DESCRIPTION [$(date +%Y-%m-%d %H:%M:%S)]"
            ;;
        3)
            git stash push -m "Pre-snapshot stash: $DESCRIPTION"
            STASHED=true
            ;;
    esac
fi

# Check disk space (for full backups)
if [[ $TYPE == "full" ]]; then
    REPO_SIZE=$(du -sh .git | cut -f1)
    echo "Repository size: $REPO_SIZE"
    # Warn if low disk space
fi
```

### Snapshot Creation

```bash
# PHASE 2: Create Snapshot
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
CURRENT_HASH=$(git rev-parse HEAD)
CURRENT_BRANCH=$(git branch --show-current)

case $TYPE in
    "quick")
        TAG_NAME="snapshot-$DESCRIPTION-$TIMESTAMP"
        git tag -a "$TAG_NAME" -m "Snapshot: $DESCRIPTION
Created: $(date)
Reason: $REASON
Branch: $CURRENT_BRANCH
Commit: $CURRENT_HASH"

        echo "✓ Quick snapshot created: $TAG_NAME"
        RESTORE_CMD="git checkout tags/$TAG_NAME"
        ;;

    "branch")
        BRANCH_NAME="snapshot/$DESCRIPTION-$TIMESTAMP"
        git checkout -b "$BRANCH_NAME"
        git checkout "$CURRENT_BRANCH"

        echo "✓ Recovery branch created: $BRANCH_NAME"
        RESTORE_CMD="git checkout $BRANCH_NAME"
        ;;

    "full")
        BACKUP_DIR="$HOME/ai-workspace/backups"
        mkdir -p "$BACKUP_DIR"
        BUNDLE_NAME="snapshot-$DESCRIPTION-$TIMESTAMP.bundle"
        BUNDLE_PATH="$BACKUP_DIR/$BUNDLE_NAME"

        git bundle create "$BUNDLE_PATH" --all
        BUNDLE_SIZE=$(du -sh "$BUNDLE_PATH" | cut -f1)

        echo "✓ Full backup created: $BUNDLE_NAME"
        echo "  Location: $BUNDLE_PATH"
        echo "  Size: $BUNDLE_SIZE"
        RESTORE_CMD="git clone $BUNDLE_PATH restored-repo"
        ;;
esac
```

### Change Analysis

```bash
# PHASE 3: Analyze What Was Captured
echo ""
echo "=== Snapshot Contents ==="

# Get last snapshot reference
LAST_SNAPSHOT=$(git tag -l "snapshot-*" --sort=-creatordate | head -n 2 | tail -n 1)

if [[ -n "$LAST_SNAPSHOT" ]]; then
    echo "Changes since last snapshot ($LAST_SNAPSHOT):"
    echo ""

    # File statistics
    FILES_CHANGED=$(git diff --stat "$LAST_SNAPSHOT" HEAD | tail -n 1)
    echo "$FILES_CHANGED"
    echo ""

    # List modified files
    echo "Modified files:"
    git diff --name-status "$LAST_SNAPSHOT" HEAD
else
    echo "First snapshot in repository"
    echo ""
    echo "Repository statistics:"
    git log --oneline | wc -l | xargs echo "Total commits:"
    git ls-files | wc -l | xargs echo "Total files:"
fi
```

### Documentation

```bash
# PHASE 4: Document in agents.md
AGENTS_MD=".claude/agents/agents.md"

# Create Snapshots section if it doesn't exist
if ! grep -q "^## Snapshots$" "$AGENTS_MD"; then
    echo -e "\n## Snapshots\n" >> "$AGENTS_MD"
fi

# Append snapshot entry
cat >> "$AGENTS_MD" << EOF

### [$TIMESTAMP] $DESCRIPTION
- **Type**: $TYPE
- **Commit**: $CURRENT_HASH
- **Branch**: $CURRENT_BRANCH
- **Reason**: $REASON
- **Files changed**: $(git diff --stat "$LAST_SNAPSHOT" HEAD 2>/dev/null | tail -n 1 || echo "Initial snapshot")
- **Restoration**: \`$RESTORE_CMD\`
- **Created by**: snapshot-agent

EOF

echo "✓ Documented in agents.md"
```

### Post-Snapshot Report

```bash
# PHASE 5: Generate Report
echo ""
echo "=== Snapshot Report ==="
echo "Name: $DESCRIPTION"
echo "Type: $TYPE"
echo "Created: $(date)"
echo "Commit: $CURRENT_HASH"
echo "Branch: $CURRENT_BRANCH"
echo ""
echo "Restoration command:"
echo "  $RESTORE_CMD"
echo ""
echo "To list all snapshots:"
echo "  /snapshot --list"
echo ""
echo "To restore this snapshot:"
echo "  /snapshot --restore $DESCRIPTION"
```

---

## Usage Patterns

### Interactive Mode
```bash
/snapshot
# Prompts for:
# - Description
# - Type (quick/branch/full)
# - Reason
# Then creates snapshot
```

### Quick Usage
```bash
/snapshot "before n8n installation"              # Quick tag
/snapshot --branch "pre-optimization"             # Recovery branch
/snapshot --full "pre-production-deploy"          # Full backup
```

### Management
```bash
/snapshot --list                                  # Show all snapshots
/snapshot --list --type branch                    # Show only branches
/snapshot --restore <name>                        # Restore from snapshot
/snapshot --cleanup                               # Remove old snapshots
/snapshot --cleanup --days 30                     # Custom retention
```

### Advanced
```bash
/snapshot --auto-commit "experiment"              # Auto-commit uncommitted changes
/snapshot --diff <name>                           # Show diff vs snapshot
/snapshot --export <name> /path/to/backup         # Export snapshot bundle
```

---

## Restoration Workflow

### Safe Restoration Process

```bash
# STEP 1: List Available Snapshots
echo "=== Available Snapshots ==="
git tag -l "snapshot-*" --sort=-creatordate -n1  # Tags with messages
echo ""
git branch -a | grep "snapshot/"                  # Branches
echo ""
ls -lh ~/ai-workspace/backups/*.bundle 2>/dev/null  # Bundles

# STEP 2: Show Snapshot Details
SNAPSHOT_NAME="$1"
echo "=== Snapshot: $SNAPSHOT_NAME ==="
git show "$SNAPSHOT_NAME" --stat --pretty=fuller

# STEP 3: Show Diff from Current State
echo ""
echo "=== Changes Between Current State and Snapshot ==="
git diff HEAD.."$SNAPSHOT_NAME" --stat
echo ""
read -p "Show full diff? [y/N]: " SHOW_DIFF
if [[ $SHOW_DIFF == "y" ]]; then
    git diff HEAD.."$SNAPSHOT_NAME"
fi

# STEP 4: Confirm Restoration
echo ""
echo "⚠️  This will restore your workspace to the snapshot state."
echo ""
echo "Current uncommitted changes will be:"
if [[ -n $(git status --porcelain) ]]; then
    echo "  LOST unless you commit or stash them first!"
    git status --short
    echo ""
    read -p "Commit changes before restoring? [Y/n]: " COMMIT_FIRST
    if [[ $COMMIT_FIRST != "n" ]]; then
        read -p "Commit message: " MSG
        git add -A
        git commit -m "$MSG"
    fi
fi

# STEP 5: Create Backup of Current State
CURRENT_BACKUP="snapshot/before-restore-$(date +%Y%m%d-%H%M%S)"
git branch "$CURRENT_BACKUP"
echo "✓ Created backup of current state: $CURRENT_BACKUP"

# STEP 6: Restore
read -p "Type 'RESTORE' to continue: " CONFIRM
if [[ $CONFIRM == "RESTORE" ]]; then
    # Determine snapshot type and restore appropriately
    if git show-ref --tags "$SNAPSHOT_NAME" >/dev/null; then
        # It's a tag
        git checkout "tags/$SNAPSHOT_NAME"
    elif git show-ref --heads "$SNAPSHOT_NAME" >/dev/null; then
        # It's a branch
        git checkout "$SNAPSHOT_NAME"
    else
        echo "✗ Snapshot not found: $SNAPSHOT_NAME"
        exit 1
    fi

    echo "✓ Restored to snapshot: $SNAPSHOT_NAME"
else
    echo "Restoration cancelled"
    exit 0
fi

# STEP 7: Verify Restoration
echo ""
echo "=== Restoration Verification ==="
git log -1 --oneline
git status
echo ""
echo "✓ Restoration complete"
echo ""
echo "To return to previous state:"
echo "  git checkout $CURRENT_BACKUP"
echo ""
echo "To delete backup branch:"
echo "  git branch -D $CURRENT_BACKUP"

# STEP 8: Document Restoration
cat >> .claude/agents/agents.md << EOF

### [$(date +%Y%m%d-%H%M%S)] Restoration
- **Restored snapshot**: $SNAPSHOT_NAME
- **Previous state backup**: $CURRENT_BACKUP
- **Restored by**: snapshot-agent

EOF
```

---

## Automatic Snapshot Suggestions

### Integration Points

The snapshot agent should proactively suggest creating snapshots before:

1. **Optimization Operations** (`/optimize`)
   ```
   ⚡ Tip: Create snapshot before optimization?
   /snapshot "pre-optimization" --branch
   ```

2. **SDLC Workflows** (`/sdlc`)
   ```
   🔄 Running full SDLC workflow
   Recommended: /snapshot "pre-sdlc-run" --branch
   ```

3. **Major Refactoring** (detected by agent)
   ```
   🏗️  Large refactoring detected (50+ files)
   Suggested: /snapshot "pre-refactor" --branch
   ```

4. **Dependency Changes** (`package.json`, `requirements.txt`, etc.)
   ```
   📦 Dependency changes detected
   Recommended: /snapshot "pre-dependency-update" --quick
   ```

5. **Slash Command Modifications**
   ```
   🔧 Modifying slash commands
   Suggested: /snapshot "pre-command-update" --quick
   ```

6. **Deploy Operations** (`/deploy`)
   ```
   🚀 Pre-deployment snapshot recommended
   /snapshot "pre-deploy-$(date +%Y%m%d)" --full
   ```

### Detection Logic

```bash
# Detect risky operations by analyzing:
FILES_CHANGED=$(git diff --cached --name-only | wc -l)
LINES_CHANGED=$(git diff --cached --stat | tail -n1)

if [[ $FILES_CHANGED -gt 50 ]]; then
    echo "⚠️  Large changeset detected ($FILES_CHANGED files)"
    echo "Recommend: /snapshot --branch"
fi

# Check for specific file patterns
if git diff --cached --name-only | grep -qE "package\.json|requirements\.txt|Gemfile"; then
    echo "📦 Dependency changes detected"
    echo "Recommend: /snapshot --quick"
fi

# Check for slash command changes
if git diff --cached --name-only | grep -qE "\.claude/(commands|agents)/"; then
    echo "🔧 Slash command/agent changes detected"
    echo "Recommend: /snapshot --quick"
fi
```

---

## Snapshot Cleanup & Retention

### Auto-Cleanup Strategy

```bash
# Default retention: 30 days
RETENTION_DAYS=30

# CLEANUP TAGS
echo "=== Cleaning up old snapshot tags ==="
git tag -l "snapshot-*" | while read TAG; do
    # Extract timestamp from tag name
    TIMESTAMP=$(echo "$TAG" | grep -oE '[0-9]{8}-[0-9]{6}')
    if [[ -n "$TIMESTAMP" ]]; then
        TAG_DATE=$(date -d "${TIMESTAMP:0:8} ${TIMESTAMP:9:2}:${TIMESTAMP:11:2}:${TIMESTAMP:13:2}" +%s 2>/dev/null || echo 0)
        CURRENT_DATE=$(date +%s)
        AGE_DAYS=$(( ($CURRENT_DATE - $TAG_DATE) / 86400 ))

        if [[ $AGE_DAYS -gt $RETENTION_DAYS ]]; then
            echo "Removing old tag: $TAG (${AGE_DAYS} days old)"
            git tag -d "$TAG"
        fi
    fi
done

# CLEANUP BRANCHES
echo ""
echo "=== Cleaning up old snapshot branches ==="
git branch | grep "snapshot/" | while read BRANCH; do
    BRANCH=$(echo "$BRANCH" | xargs)  # Trim whitespace
    TIMESTAMP=$(echo "$BRANCH" | grep -oE '[0-9]{8}-[0-9]{6}')
    if [[ -n "$TIMESTAMP" ]]; then
        BRANCH_DATE=$(date -d "${TIMESTAMP:0:8} ${TIMESTAMP:9:2}:${TIMESTAMP:11:2}:${TIMESTAMP:13:2}" +%s 2>/dev/null || echo 0)
        CURRENT_DATE=$(date +%s)
        AGE_DAYS=$(( ($CURRENT_DATE - $BRANCH_DATE) / 86400 ))

        if [[ $AGE_DAYS -gt $RETENTION_DAYS ]]; then
            echo "Removing old branch: $BRANCH (${AGE_DAYS} days old)"
            git branch -D "$BRANCH"
        fi
    fi
done

# CLEANUP BUNDLES
echo ""
echo "=== Cleaning up old backup bundles ==="
BACKUP_DIR="$HOME/ai-workspace/backups"
if [[ -d "$BACKUP_DIR" ]]; then
    find "$BACKUP_DIR" -name "snapshot-*.bundle" -type f | while read BUNDLE; do
        AGE_DAYS=$(( ($(date +%s) - $(stat -c %Y "$BUNDLE")) / 86400 ))
        if [[ $AGE_DAYS -gt $RETENTION_DAYS ]]; then
            SIZE=$(du -sh "$BUNDLE" | cut -f1)
            echo "Removing old bundle: $(basename $BUNDLE) (${AGE_DAYS} days old, ${SIZE})"
            rm "$BUNDLE"
        fi
    done
fi

echo ""
echo "✓ Cleanup complete"
```

### Retention Policies

**Default Policy**:
- Quick snapshots (tags): 30 days
- Recovery branches: 30 days
- Full backups: 90 days (longer retention for disaster recovery)

**Custom Policies**:
```bash
/snapshot --cleanup --days 30              # Custom retention
/snapshot --cleanup --keep-recent 10       # Keep 10 most recent
/snapshot --cleanup --dry-run              # Preview what would be deleted
```

**Exempt from Cleanup**:
- Snapshots with "production" in name
- Snapshots with "release" in name
- Snapshots created by CI/CD (tagged with "automated")
- Snapshots explicitly marked as permanent

---

## Listing & Querying Snapshots

### List All Snapshots

```bash
echo "=== All Snapshots ==="
echo ""

# Tags
echo "Quick Snapshots (tags):"
git tag -l "snapshot-*" --sort=-creatordate --format='%(creatordate:short) | %(refname:short)' | column -t -s '|'
echo ""

# Branches
echo "Recovery Branches:"
git branch --list "snapshot/*" --sort=-committerdate --format='%(committerdate:short) | %(refname:short)' | column -t -s '|'
echo ""

# Bundles
echo "Full Backups:"
if [[ -d "$HOME/ai-workspace/backups" ]]; then
    ls -lh "$HOME/ai-workspace/backups"/*.bundle 2>/dev/null | awk '{print $6" "$7" | "$9" | "$5}' | column -t -s '|'
fi
```

### Filter Snapshots

```bash
# By type
/snapshot --list --type quick
/snapshot --list --type branch
/snapshot --list --type full

# By date range
/snapshot --list --since "2025-01-01"
/snapshot --list --before "2025-02-01"

# By description pattern
/snapshot --list --grep "optimization"

# With details
/snapshot --list --verbose  # Shows commit hash, file counts, etc.
```

### Query Snapshot Contents

```bash
# Show snapshot details
/snapshot --show <name>

# Compare snapshots
/snapshot --diff <snapshot1> <snapshot2>

# Search in snapshot
/snapshot --search <pattern> --in <snapshot-name>
```

---

## Integration with Other Agents

### Hooks for Other Agents

**In `/optimize` agent**:
```bash
# Before running optimization
if ! git tag -l "snapshot-*" | grep -q "pre-optimization"; then
    echo "💡 Tip: Create snapshot before optimization?"
    echo "Run: /snapshot 'pre-optimization' --branch"
    read -p "Create snapshot now? [Y/n]: " CREATE
    if [[ $CREATE != "n" ]]; then
        # Trigger snapshot creation
        /snapshot "pre-optimization-$(date +%Y%m%d-%H%M%S)" --branch
    fi
fi
```

**In `/review` agent**:
```bash
# Before applying review suggestions
if [[ $CHANGES_LARGE == true ]]; then
    echo "💡 Large refactoring suggested"
    echo "Recommend: /snapshot 'pre-review-refactor' --branch"
fi
```

**In `/sdlc` workflows**:
```bash
# Automatic snapshot before each SDLC run
SDLC_SNAPSHOT="pre-sdlc-$(date +%Y%m%d-%H%M%S)"
/snapshot "$SDLC_SNAPSHOT" --branch --auto-commit
echo "✓ Created SDLC snapshot: $SDLC_SNAPSHOT"
```

### Snapshot Status in `/closeout`

Add to session closeout report:
```bash
echo "=== Snapshots This Session ==="
# List snapshots created during this session
git tag -l "snapshot-*" --sort=-creatordate | head -n 5
echo ""
echo "Total active snapshots: $(git tag -l "snapshot-*" | wc -l)"
echo "Total recovery branches: $(git branch --list "snapshot/*" | wc -l)"
echo ""
echo "Recommend cleanup: /snapshot --cleanup"
```

---

## Error Handling

### Repository Issues
```bash
# Not a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "✗ Not a git repository"
    echo "Initialize with: git init"
    exit 1
fi
```

### Disk Space
```bash
# Check available disk space for full backups
if [[ $TYPE == "full" ]]; then
    REPO_SIZE_KB=$(du -s .git | cut -f1)
    AVAILABLE_KB=$(df . | tail -n 1 | awk '{print $4}')

    if [[ $REPO_SIZE_KB -gt $(($AVAILABLE_KB / 2)) ]]; then
        echo "⚠️  Low disk space!"
        echo "Repository size: $(du -sh .git | cut -f1)"
        echo "Available space: $(df -h . | tail -n 1 | awk '{print $4}')"
        read -p "Continue anyway? [y/N]: " CONTINUE
        if [[ $CONTINUE != "y" ]]; then
            exit 1
        fi
    fi
fi
```

### Corrupted Snapshots
```bash
# Verify snapshot integrity
if ! git cat-file -t "$SNAPSHOT_REF" >/dev/null 2>&1; then
    echo "✗ Snapshot is corrupted or missing: $SNAPSHOT_NAME"
    echo "Available snapshots:"
    /snapshot --list
    exit 1
fi

# Verify bundle integrity
if [[ -f "$BUNDLE_PATH" ]]; then
    if ! git bundle verify "$BUNDLE_PATH" >/dev/null 2>&1; then
        echo "✗ Bundle is corrupted: $BUNDLE_PATH"
        echo "Cannot restore from this backup"
        exit 1
    fi
fi
```

### Naming Conflicts
```bash
# Check for duplicate snapshot names
if git tag -l "snapshot-$DESCRIPTION-*" | grep -q "snapshot-$DESCRIPTION"; then
    echo "⚠️  Similar snapshot exists:"
    git tag -l "snapshot-$DESCRIPTION-*"
    read -p "Create anyway? [y/N]: " CREATE
    if [[ $CREATE != "y" ]]; then
        exit 0
    fi
fi
```

---

## Compliance & Audit

### HIPAA/SOC 2 Requirements

**Change Control**:
- All snapshots logged with timestamp, creator, reason
- Complete audit trail in agents.md
- Restoration operations documented
- Retention policies enforced

**Data Preservation**:
- Multiple snapshot types for different recovery needs
- Automated cleanup with configurable retention
- Integrity verification for bundles
- Point-in-time recovery capability

**Access Control**:
- Confirmation required for restoration
- Current state backed up before restoration
- Operations logged for compliance review

### Audit Trail Format

```markdown
## Snapshots

### [20250122-143022] pre-optimization
- **Type**: branch
- **Commit**: abc123f4567890def
- **Branch**: main
- **Reason**: Safety checkpoint before P0 optimization
- **Files changed**: 47 files changed, 892 insertions(+), 234 deletions(-)
- **Restoration**: `git checkout snapshot/pre-optimization-20250122-143022`
- **Created by**: snapshot-agent

### [20250122-150330] Restoration
- **Restored snapshot**: pre-optimization-20250122-143022
- **Previous state backup**: snapshot/before-restore-20250122-150330
- **Restored by**: snapshot-agent
- **Reason**: Rollback failed optimization
```

---

## Best Practices

### When to Snapshot

**Always snapshot before**:
- Major refactoring (>20 files)
- SDLC workflow runs
- Dependency upgrades
- Architectural changes
- Production deployments
- Risky experiments

**Consider snapshot before**:
- Config file changes
- Slash command modifications
- Database migrations
- API endpoint changes
- Authentication changes

**No snapshot needed for**:
- Documentation updates
- Comment additions
- Minor style fixes
- Single-file tweaks
- Read-only operations

### Naming Conventions

**Good snapshot names**:
- `pre-optimization` (clear purpose)
- `before-n8n-install` (specific operation)
- `working-auth-flow` (known-good state)
- `pre-production-deploy-20250122` (critical checkpoint)

**Avoid**:
- `test` (too vague)
- `backup` (redundant)
- `asdf` (meaningless)
- `snapshot1`, `snapshot2` (use timestamps instead)

### Cleanup Strategy

**Regular maintenance**:
- Run `/snapshot --cleanup` monthly
- Keep recent snapshots (<30 days) always
- Preserve production snapshots indefinitely
- Archive critical snapshots as bundles

**Before major operations**:
- Clean up old snapshots to free disk space
- Verify existing snapshots are valid
- Document retention decisions

---

## Testing Recommendations

After creating snapshot, verify:
1. Snapshot is listed: `/snapshot --list`
2. Snapshot is accessible: `git show <snapshot>`
3. Restoration preview works: `/snapshot --diff <name>`
4. Documentation updated: Check agents.md

After restoring snapshot, verify:
1. Code state matches expectation: Review key files
2. Tests pass: Run test suite
3. Build works: Run build process
4. Git history intact: Check `git log`

---

## Advanced Features

### Snapshot Comparison
```bash
# Compare two snapshots
/snapshot --compare <snapshot1> <snapshot2>

# Find snapshots containing specific change
/snapshot --find-change "function optimizeP0"

# Show snapshot timeline
/snapshot --timeline --graph
```

### Snapshot Export/Import
```bash
# Export snapshot for sharing
/snapshot --export <name> --to /path/to/export.bundle

# Import snapshot from colleague
/snapshot --import /path/to/export.bundle --as "colleague-feature"
```

### Automated Snapshots
```bash
# Enable automatic snapshots before commits
git config snapshot.auto true

# Create snapshot on schedule (cron)
0 0 * * * cd ~/ai-workspace && /snapshot "daily-$(date +%Y%m%d)" --quick
```

---

## Summary

The snapshot agent provides:
- **Safety**: Create save points before risky operations
- **Confidence**: Experiment fearlessly with easy rollback
- **Auditability**: Complete history of snapshots and restorations
- **Flexibility**: Multiple snapshot types for different needs
- **Automation**: Integration with other agents
- **Compliance**: Full audit trail for regulatory requirements

Use liberally - snapshots are cheap, data loss is expensive.
