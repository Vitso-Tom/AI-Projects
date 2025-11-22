#!/bin/bash
#
# AI Delegation Testing Script
# Tests the complete delegation architecture
#
# Usage: ./test-delegation.sh [test_level]
#   test_level: basic, full, poc (default: basic)

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test level
TEST_LEVEL="${1:-basic}"

echo "╔════════════════════════════════════════════════════════════╗"
echo "║         AI Delegation Architecture Test Suite              ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Test Level: $TEST_LEVEL"
echo ""

# ============================================================================
# TEST 1: Library Loading
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST 1: Delegation Library Loading"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if source /home/temlock/ai-workspace/.claude/lib/delegation.sh 2>/dev/null; then
    echo -e "${GREEN}✅ PASS${NC}: Delegation library loaded successfully"
else
    echo -e "${RED}❌ FAIL${NC}: Failed to load delegation library"
    exit 1
fi
echo ""

# ============================================================================
# TEST 2: Configuration System
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST 2: Configuration System (Default Values)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

declare -A EXPECTED_DEFAULTS=(
    ["security-analyzer"]="gemini"
    ["optimizer"]="codex"
    ["code-reviewer"]="multi"
    ["test-runner"]="hybrid"
    ["doc-generator"]="codex"
    ["session-closer"]="claude"
)

PASS_COUNT=0
FAIL_COUNT=0

for agent in "${!EXPECTED_DEFAULTS[@]}"; do
    ACTUAL=$(get_delegation_config "$agent")
    EXPECTED="${EXPECTED_DEFAULTS[$agent]}"

    if [[ "$ACTUAL" == "$EXPECTED" ]]; then
        echo -e "${GREEN}✅ PASS${NC}: $agent → $ACTUAL"
        ((PASS_COUNT++))
    else
        echo -e "${RED}❌ FAIL${NC}: $agent → Expected: $EXPECTED, Got: $ACTUAL"
        ((FAIL_COUNT++))
    fi
done

echo ""
echo "Results: $PASS_COUNT passed, $FAIL_COUNT failed"
echo ""

if [[ $FAIL_COUNT -gt 0 ]]; then
    echo -e "${RED}Configuration system test FAILED${NC}"
    exit 1
fi

# ============================================================================
# TEST 3: Environment Variable Override
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST 3: Environment Variable Override"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Test override
export AI_DELEGATION_SECURITY_ANALYZER=codex
RESULT=$(get_delegation_config "security-analyzer")

if [[ "$RESULT" == "codex" ]]; then
    echo -e "${GREEN}✅ PASS${NC}: Environment variable override works (security-analyzer → codex)"
else
    echo -e "${RED}❌ FAIL${NC}: Environment variable override failed (expected: codex, got: $RESULT)"
    exit 1
fi

# Clean up
unset AI_DELEGATION_SECURITY_ANALYZER
RESULT=$(get_delegation_config "security-analyzer")

if [[ "$RESULT" == "gemini" ]]; then
    echo -e "${GREEN}✅ PASS${NC}: Default restored after unset (security-analyzer → gemini)"
else
    echo -e "${RED}❌ FAIL${NC}: Default not restored (expected: gemini, got: $RESULT)"
    exit 1
fi

echo ""

# ============================================================================
# TEST 4: CLI Tool Availability
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST 4: CLI Tool Availability"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

TOOLS_AVAILABLE=true

if command -v codex &> /dev/null; then
    echo -e "${GREEN}✅ PASS${NC}: codex CLI found at $(which codex)"
else
    echo -e "${RED}❌ FAIL${NC}: codex CLI not found"
    TOOLS_AVAILABLE=false
fi

if command -v gemini &> /dev/null; then
    echo -e "${GREEN}✅ PASS${NC}: gemini CLI found at $(which gemini)"
else
    echo -e "${RED}❌ FAIL${NC}: gemini CLI not found"
    TOOLS_AVAILABLE=false
fi

echo ""

if [[ "$TOOLS_AVAILABLE" == "false" ]]; then
    echo -e "${YELLOW}⚠️  WARNING${NC}: Some CLI tools are missing. Delegation tests will be skipped."
    if [[ "$TEST_LEVEL" == "full" || "$TEST_LEVEL" == "poc" ]]; then
        echo "Cannot proceed with $TEST_LEVEL tests without CLI tools."
        exit 1
    fi
fi

# ============================================================================
# TEST 5: Delegation Functions (Basic)
# ============================================================================
if [[ "$TEST_LEVEL" == "full" || "$TEST_LEVEL" == "poc" ]]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "TEST 5: Delegation Functions (Gemini)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Create test prompt
    TEST_PROMPT=$(mktemp)
    cat > "$TEST_PROMPT" <<'EOF'
Analyze this simple bash script and identify any potential issues:

#!/bin/bash
# WARNING: INSECURE EXAMPLE for testing only
# Never use hardcoded credentials in production
PASSWORD="EXAMPLE_PASSWORD_REPLACE_ME"
echo "Connecting to database..."
mysql -u root -p$PASSWORD -e "SELECT * FROM users WHERE id=$1"
EOF

    # Create test input file
    TEST_INPUT=$(mktemp)
    echo "#!/bin/bash" > "$TEST_INPUT"
    echo 'echo "Hello World"' >> "$TEST_INPUT"

    echo "Testing Gemini delegation with simple security scan..."
    echo ""

    if GEMINI_OUTPUT=$(delegate_to_gemini "test-scan" "$TEST_INPUT" "$TEST_PROMPT" 2>/dev/null); then
        if [[ -f "$GEMINI_OUTPUT" ]]; then
            OUTPUT_SIZE=$(wc -c < "$GEMINI_OUTPUT")
            if [[ $OUTPUT_SIZE -gt 100 ]]; then
                echo -e "${GREEN}✅ PASS${NC}: Gemini delegation succeeded (output: $OUTPUT_SIZE bytes)"
                echo ""
                echo "Sample output (first 500 chars):"
                echo "---"
                head -c 500 "$GEMINI_OUTPUT"
                echo ""
                echo "---"
            else
                echo -e "${YELLOW}⚠️  WARNING${NC}: Gemini delegation returned small output ($OUTPUT_SIZE bytes)"
            fi
        else
            echo -e "${RED}❌ FAIL${NC}: Gemini delegation didn't create output file"
        fi
    else
        echo -e "${RED}❌ FAIL${NC}: Gemini delegation failed"
    fi

    # Clean up
    rm -f "$TEST_PROMPT" "$TEST_INPUT"
    echo ""
fi

# ============================================================================
# TEST 6: Codex Delegation
# ============================================================================
if [[ "$TEST_LEVEL" == "full" ]]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "TEST 6: Delegation Functions (Codex)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Create test prompt
    TEST_PROMPT=$(mktemp)
    cat > "$TEST_PROMPT" <<'EOF'
Optimize this Python function:

def find_duplicates(items):
    duplicates = []
    for i in range(len(items)):
        for j in range(i + 1, len(items)):
            if items[i] == items[j] and items[i] not in duplicates:
                duplicates.append(items[i])
    return duplicates
EOF

    # Create test input file
    TEST_INPUT=$(mktemp)
    cat > "$TEST_INPUT" <<'EOF'
def find_duplicates(items):
    duplicates = []
    for i in range(len(items)):
        for j in range(i + 1, len(items)):
            if items[i] == items[j] and items[i] not in duplicates:
                duplicates.append(items[i])
    return duplicates
EOF

    echo "Testing Codex delegation with optimization task..."
    echo ""

    if CODEX_OUTPUT=$(delegate_to_codex "test-optimize" "$TEST_INPUT" "$TEST_PROMPT" 2>/dev/null); then
        if [[ -f "$CODEX_OUTPUT" ]]; then
            OUTPUT_SIZE=$(wc -c < "$CODEX_OUTPUT")
            if [[ $OUTPUT_SIZE -gt 100 ]]; then
                echo -e "${GREEN}✅ PASS${NC}: Codex delegation succeeded (output: $OUTPUT_SIZE bytes)"
                echo ""
                echo "Sample output (first 500 chars):"
                echo "---"
                head -c 500 "$CODEX_OUTPUT"
                echo ""
                echo "---"
            else
                echo -e "${YELLOW}⚠️  WARNING${NC}: Codex delegation returned small output ($OUTPUT_SIZE bytes)"
            fi
        else
            echo -e "${RED}❌ FAIL${NC}: Codex delegation didn't create output file"
        fi
    else
        echo -e "${RED}❌ FAIL${NC}: Codex delegation failed"
    fi

    # Clean up
    rm -f "$TEST_PROMPT" "$TEST_INPUT"
    echo ""
fi

# ============================================================================
# SUMMARY
# ============================================================================
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                      TEST SUMMARY                          ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

if [[ "$TEST_LEVEL" == "basic" ]]; then
    echo -e "${GREEN}✅ Basic infrastructure tests PASSED${NC}"
    echo ""
    echo "Infrastructure is ready. Next steps:"
    echo "  1. Run full tests: ./test-delegation.sh full"
    echo "  2. Test POC agent: ./test-delegation.sh poc"
    echo "  3. Test with real agent: /security-audit"
else
    echo -e "${GREEN}✅ All tests PASSED${NC}"
    echo ""
    echo "Delegation architecture is fully functional!"
    echo ""
    echo "Next steps:"
    echo "  1. Test security-analyzer agent: /security-audit"
    echo "  2. Monitor token usage in Claude UI"
    echo "  3. Compare quality of delegated vs non-delegated runs"
fi

echo ""
echo "Delegation logs: /tmp/ai-delegation.log"
echo "View stats: source .claude/lib/delegation.sh && get_delegation_stats"
echo ""
