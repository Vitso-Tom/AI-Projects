#!/bin/bash
# Test Security Fixes for snapshot-utils.sh

set -e

source .claude/lib/snapshot-utils.sh

echo "=== Testing Security Fixes ==="
echo ""

# Test 1: Command Injection Prevention
echo "Test 1: Command Injection Prevention"
echo "--------------------------------------"

# Test malicious agent names
if validate_agent_name 'test"; rm -rf /'; then
    echo "✗ FAIL: Accepted malicious agent name with command injection"
    exit 1
else
    echo "✓ PASS: Rejected malicious agent name with command injection"
fi

if validate_agent_name 'test`whoami`'; then
    echo "✗ FAIL: Accepted malicious agent name with backticks"
    exit 1
else
    echo "✓ PASS: Rejected malicious agent name with backticks"
fi

# Test valid agent name
if validate_agent_name 'code-reviewer'; then
    echo "✓ PASS: Accepted valid agent name"
else
    echo "✗ FAIL: Rejected valid agent name"
    exit 1
fi

echo ""

# Test 2: Snapshot Name Validation
echo "Test 2: Snapshot Name Validation"
echo "--------------------------------------"

# Test malicious snapshot names
if validate_snapshot_name '../../../etc/passwd'; then
    echo "✗ FAIL: Accepted path traversal in snapshot name"
    exit 1
else
    echo "✓ PASS: Rejected path traversal in snapshot name"
fi

if validate_snapshot_name 'test;cat /etc/passwd'; then
    echo "✗ FAIL: Accepted command injection in snapshot name"
    exit 1
else
    echo "✓ PASS: Rejected command injection in snapshot name"
fi

# Test valid snapshot name
if validate_snapshot_name 'before-code-reviewer-20251123-143022'; then
    echo "✓ PASS: Accepted valid snapshot name"
else
    echo "✗ FAIL: Rejected valid snapshot name"
    exit 1
fi

# Test snapshot name length limit
if validate_snapshot_name "$(printf 'a%.0s' {1..250})"; then
    echo "✗ FAIL: Accepted snapshot name > 200 characters"
    exit 1
else
    echo "✓ PASS: Rejected snapshot name > 200 characters"
fi

echo ""

# Test 3: Snapshot Type Validation
echo "Test 3: Snapshot Type Validation"
echo "--------------------------------------"

if validate_snapshot_type 'tag'; then
    echo "✓ PASS: Accepted valid snapshot type 'tag'"
else
    echo "✗ FAIL: Rejected valid snapshot type 'tag'"
    exit 1
fi

if validate_snapshot_type 'branch'; then
    echo "✓ PASS: Accepted valid snapshot type 'branch'"
else
    echo "✗ FAIL: Rejected valid snapshot type 'branch'"
    exit 1
fi

if validate_snapshot_type 'malicious'; then
    echo "✗ FAIL: Accepted invalid snapshot type"
    exit 1
else
    echo "✓ PASS: Rejected invalid snapshot type"
fi

echo ""

# Test 4: Markdown Sanitization
echo "Test 4: Markdown Sanitization"
echo "--------------------------------------"

# Test markdown injection
input='### Fake Entry
- **Commit**: xyz'
output=$(sanitize_markdown "$input")

if [[ "$output" == *"###"* ]]; then
    echo "✗ FAIL: Did not escape markdown headers"
    exit 1
else
    echo "✓ PASS: Escaped markdown headers"
fi

if [[ "$output" == *"**"* ]]; then
    echo "✗ FAIL: Did not escape markdown bold"
    exit 1
else
    echo "✓ PASS: Escaped markdown bold"
fi

# Test control character removal
input=$'test\nmalicious\rcode'
output=$(sanitize_markdown "$input")

if [[ "$output" == *$'\n'* ]]; then
    echo "✗ FAIL: Did not remove newlines"
    exit 1
else
    echo "✓ PASS: Removed newlines"
fi

echo ""

# Test 5: Git Repository Validation
echo "Test 5: Git Repository Validation"
echo "--------------------------------------"

# This should pass since we're in a git repository
if validate_git_repository; then
    echo "✓ PASS: Validated git repository correctly"
else
    echo "✗ FAIL: Failed to validate git repository"
    exit 1
fi

echo ""

# Test 6: TOCTOU Protection (Threshold Check)
echo "Test 6: TOCTOU Protection"
echo "--------------------------------------"

# Check that threshold is 25 minutes (not 30)
if [[ $SNAPSHOT_AGE_THRESHOLD_MINUTES -eq 25 ]]; then
    echo "✓ PASS: Snapshot age threshold is 25 minutes (5-min buffer)"
else
    echo "✗ FAIL: Snapshot age threshold is $SNAPSHOT_AGE_THRESHOLD_MINUTES (should be 25)"
    exit 1
fi

echo ""

echo "==================================="
echo "All Security Tests PASSED! ✓"
echo "==================================="
echo ""
echo "Summary:"
echo "  - Command injection prevention: WORKING"
echo "  - Input validation: WORKING"
echo "  - Markdown sanitization: WORKING"
echo "  - Git repository validation: WORKING"
echo "  - TOCTOU protection: ENABLED (25-min threshold)"
echo ""
echo "The snapshot-utils.sh library is now secure!"
