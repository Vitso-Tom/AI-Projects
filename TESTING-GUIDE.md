# AI Delegation Testing Guide

**Purpose**: Validate the AI delegation architecture works correctly and achieves expected token savings.

## Quick Start

The delegation infrastructure has been validated and is ready to use. Here's how to test it:

### ✅ Infrastructure Tests (Already Passed)

```bash
# Test 1: Library loads correctly
source /home/temlock/ai-workspace/.claude/lib/delegation.sh
# ✅ Library loaded successfully

# Test 2: Configuration system works
get_delegation_config "security-analyzer"
# ✅ Returns: gemini

# Test 3: All agents have correct defaults
for agent in security-analyzer optimizer code-reviewer test-runner doc-generator session-closer; do
    echo "$agent: $(get_delegation_config "$agent")"
done
# ✅ All return expected values

# Test 4: Environment variable override works
export AI_DELEGATION_SECURITY_ANALYZER=codex
get_delegation_config "security-analyzer"
# ✅ Returns: codex (overridden)

unset AI_DELEGATION_SECURITY_ANALYZER
get_delegation_config "security-analyzer"
# ✅ Returns: gemini (default restored)

# Test 5: CLI tools are available
which codex    # ✅ /home/temlock/.nvm/versions/node/v22.21.1/bin/codex
which gemini   # ✅ /home/temlock/.nvm/versions/node/v22.21.1/bin/gemini
```

**Result**: ✅ All infrastructure tests passed. Ready for agent testing.

---

## Testing Levels

### Level 1: Simple Delegation Test (5 minutes)

Test the delegation functions directly with a minimal example:

```bash
# Create a simple test file
cat > /tmp/test-code.py <<'EOF'
def add(a, b):
    return a + b

def multiply(a, b):
    result = 0
    for i in range(b):
        result = result + a
    return result
EOF

# Create a prompt for Gemini
cat > /tmp/gemini-prompt.txt <<'EOF'
Analyze this Python code and identify:
1. Any bugs or issues
2. Performance concerns
3. Best practice violations

Keep your response concise (under 200 words).
EOF

# Source the library
source /home/temlock/ai-workspace/.claude/lib/delegation.sh

# Test Gemini delegation
GEMINI_OUTPUT=$(delegate_to_gemini "test-scan" "/tmp/test-code.py" "/tmp/gemini-prompt.txt")

# Check the result
if [[ $? -eq 0 && -f "$GEMINI_OUTPUT" ]]; then
    echo "✅ Gemini delegation successful!"
    echo ""
    echo "Output:"
    cat "$GEMINI_OUTPUT"
else
    echo "❌ Gemini delegation failed"
    cat /tmp/ai-delegation.log | tail -10
fi
```

**Expected Result**: Gemini should analyze the code and identify that `multiply()` is inefficient (O(n) instead of O(1)).

---

### Level 2: Security Analyzer POC Test (10 minutes)

**IMPORTANT**: This is a manual test because the security-analyzer agent needs to be invoked by Claude Code.

#### Setup Test Environment

```bash
# Create a test codebase with intentional security issues
mkdir -p /tmp/test-security-app
cd /tmp/test-security-app

# Create a file with security vulnerabilities
cat > app.py <<'EOF'
import os
import sqlite3

# SECURITY ISSUE: Hardcoded credentials
DATABASE_PASSWORD = "admin123"
API_KEY = "sk_live_51234567890abcdefgh"

def get_user(user_id):
    # SECURITY ISSUE: SQL injection
    conn = sqlite3.connect('database.db')
    query = "SELECT * FROM users WHERE id = " + user_id
    result = conn.execute(query)
    return result.fetchone()

def run_command(cmd):
    # SECURITY ISSUE: Command injection
    os.system(cmd)

def process_data(data):
    # SECURITY ISSUE: No input validation
    return eval(data)
EOF

cat > README.md <<'EOF'
# Test Security App
This app has intentional security vulnerabilities for testing.
EOF
```

#### Test Using Agent Configuration

The security-analyzer agent (v2.0.0) now includes delegation support. However, to test it properly, you need to invoke it through Claude Code.

**Option A: Test via Claude Code** (Recommended)

1. In this Claude Code session, ask me to:
   ```
   "Please analyze the security of /tmp/test-security-app using the security-analyzer agent"
   ```

2. I will invoke the security-analyzer agent, which will:
   - Source the delegation library
   - Check delegation config (should use Gemini by default)
   - Delegate vulnerability scanning to Gemini
   - Aggregate findings into a structured report

3. Observe the results:
   - Check for findings (hardcoded credentials, SQL injection, command injection, eval usage)
   - Verify report quality
   - Check Claude token usage (should be ~8K instead of ~30K)

**Option B: Manual Delegation Test** (Quick validation)

```bash
# Test Gemini directly with security scanning prompt
cat > /tmp/security-prompt.txt <<'EOF'
Perform security vulnerability analysis on the provided Python code:

1. **Credential Scanning**: Look for hardcoded passwords, API keys, tokens
2. **SQL Injection**: Check for string concatenation in SQL queries
3. **Command Injection**: Look for os.system(), exec(), eval()
4. **Input Validation**: Check if user input is validated

For each finding:
- Severity: P0 (Critical) / P1 (High) / P2 (Medium) / P3 (Low)
- Location: filename:line_number
- Description: What's the issue
- Remediation: How to fix it

=== CODE ===
$(cat /tmp/test-security-app/app.py)
EOF

# Source library and delegate
source /home/temlock/ai-workspace/.claude/lib/delegation.sh
RESULT=$(delegate_to_gemini "security-scan" "/tmp/test-security-app" "/tmp/security-prompt.txt")

# View results
if [[ $? -eq 0 ]]; then
    echo "✅ Security scan completed!"
    echo ""
    cat "$RESULT"
else
    echo "❌ Security scan failed"
    tail -20 /tmp/ai-delegation.log
fi
```

**Expected Findings**:
1. P0: Hardcoded API key (sk_live_...)
2. P0: Hardcoded password (DATABASE_PASSWORD)
3. P0: SQL injection in get_user()
4. P0: Command injection in run_command()
5. P0: Dangerous eval() usage

---

### Level 3: Token Usage Validation (Real-World Test)

This is the ultimate test: Run a real security analysis and measure token consumption.

#### Preparation

1. Choose a real codebase (or use system-check.sh)
2. Note your current Claude token usage (visible in Claude UI)

#### Test Procedure

```bash
# In Claude Code, ask:
"Please run a comprehensive security audit on the current workspace using /security-audit"

# Or if using a specific directory:
"Please analyze the security of /home/temlock/ai-workspace using the security-analyzer agent"
```

#### Measurement

**Without Delegation** (baseline):
- Expected: ~30,000 Claude tokens
- Method: Native bash tools + Claude analysis
- Time: ~2-3 minutes

**With Gemini Delegation** (optimized):
- Expected: ~8,000 Claude tokens (73% savings)
- Method: Gemini scanning + Claude aggregation
- Time: ~2-3 minutes (similar or faster)

#### Validation Criteria

✅ **Token Savings**: Claude tokens used ≤ 10,000 (target: ~8,000)
✅ **Quality**: All critical security issues identified
✅ **Completeness**: Report includes OWASP, HIPAA, SOC 2 findings
✅ **Format**: Structured report with severity levels and remediation
✅ **No Failures**: No delegation errors in `/tmp/ai-delegation.log`

---

## Testing Configuration Overrides

### Override 1: Use Codex Instead of Gemini

```bash
# Set environment variable
export AI_DELEGATION_SECURITY_ANALYZER=codex

# Ask Claude Code:
"Please analyze the security of /tmp/test-security-app"

# Verify in logs:
grep "Using env var override" /tmp/ai-delegation.log | tail -1
# Should show: AI_DELEGATION_SECURITY_ANALYZER=codex
```

### Override 2: Use Claude (No Delegation)

```bash
# Set environment variable
export AI_DELEGATION_SECURITY_ANALYZER=claude

# Ask Claude Code:
"Please analyze the security of /tmp/test-security-app"

# Result: Should use Claude directly, consuming ~30K tokens
```

### Override 3: Persistent Config File

```bash
# Create config file
cp /home/temlock/ai-workspace/.claude/ai-delegation.yml.template \
   /home/temlock/ai-workspace/.claude/ai-delegation.yml

# Edit to customize
nano /home/temlock/ai-workspace/.claude/ai-delegation.yml

# Change security-analyzer to codex:
agents:
  security-analyzer: codex  # Changed from gemini

# Test - should now use Codex by default
unset AI_DELEGATION_SECURITY_ANALYZER  # Remove env var override
# Ask Claude Code: "Please run /security-audit"
# Should use Codex (from config file)
```

---

## Troubleshooting

### Issue 1: Delegation Not Working

**Symptom**: Agent uses Claude instead of delegating

**Debug Steps**:
```bash
# Check delegation log
tail -50 /tmp/ai-delegation.log

# Verify configuration
source /home/temlock/ai-workspace/.claude/lib/delegation.sh
get_delegation_config "security-analyzer"

# Check CLI tools
which gemini
which codex

# Enable debug logging
export AI_DELEGATION_DEBUG=1
# Re-run agent
```

### Issue 2: Gemini/Codex Failures

**Symptom**: Delegation returns empty or error

**Debug Steps**:
```bash
# Test CLI directly
echo "Analyze this: print('hello')" | codex exec -

# Check rate limits
cat /tmp/ai-delegation.log | grep -i "rate limit"

# Verify network connectivity
curl -I https://gemini.google.com
```

### Issue 3: Token Savings Not Achieved

**Symptom**: Still using ~30K tokens

**Possible Causes**:
1. Delegation not configured (check `get_delegation_config`)
2. Fallback to Claude occurred (check `/tmp/ai-delegation.log` for "fallback")
3. Agent not updated with delegation code (verify `security-analyzer.md` version)

---

## Monitoring & Statistics

### View Delegation Statistics

```bash
source /home/temlock/ai-workspace/.claude/lib/delegation.sh
get_delegation_stats
```

**Example Output**:
```
=== AI Delegation Statistics ===

Total delegations: 15
Codex delegations: 8
Gemini delegations: 7
Successful delegations: 14
Failed delegations: 1
```

### View Recent Delegation Log

```bash
tail -50 /tmp/ai-delegation.log
```

### Clean Up Old Delegation Files

```bash
source /home/temlock/ai-workspace/.claude/lib/delegation.sh
cleanup_delegation_files 60  # Delete files older than 60 minutes
```

---

## Success Indicators

### ✅ Infrastructure Working
- Delegation library loads without errors
- Configuration returns expected values
- CLI tools (codex, gemini) are accessible
- Environment variable overrides work

### ✅ Delegation Working
- Gemini/Codex return valid output
- Delegation log shows successful delegations
- No errors in `/tmp/ai-delegation.log`

### ✅ Token Savings Achieved
- Claude token usage reduced by 50-70%
- Quality of output maintained or improved
- Execution time similar or better

### ✅ Quality Maintained
- All expected findings identified
- Report structure is professional
- Healthcare/compliance context preserved
- Remediation guidance is actionable

---

## Next Steps After Successful Testing

1. **Expand Delegation**: Add to optimizer.md and code-reviewer.md
2. **Monitor Usage**: Track token savings over multiple runs
3. **Refine Prompts**: Optimize delegation prompts based on results
4. **Document Learnings**: Update agents.md with delegation insights

---

## Quick Reference Commands

```bash
# Load library
source /home/temlock/ai-workspace/.claude/lib/delegation.sh

# Check config
get_delegation_config "security-analyzer"

# Override for session
export AI_DELEGATION_SECURITY_ANALYZER=codex

# View stats
get_delegation_stats

# View log
tail -f /tmp/ai-delegation.log

# Clean up
cleanup_delegation_files 60
```

---

**Last Updated**: 2025-11-20
**Version**: 1.0.0
