# AI Agent Reporting Guide

**Version**: 1.0.0
**Date**: 2025-11-20

## Overview

The reporting system automatically generates professional reports for all agent activities and can email them to stakeholders.

## Features

✅ **Automatic report generation** for all agents
✅ **Professional markdown formatting** with compliance references
✅ **Email delivery** via mail/sendmail/mutt
✅ **Report archiving** and management
✅ **Multiple report types** (security, optimization, code review, testing, documentation)

## Quick Start

### 1. Generate a Report

Reports are automatically generated when agents complete their work:

```bash
# The reporting library is sourced automatically by agents
source /home/temlock/ai-workspace/.claude/lib/reporting.sh

# Generate security audit report
REPORT=$(generate_security_report "$CONTENT" "$CODEBASE" "$FINDING_COUNT")
echo "Report saved to: $REPORT"
```

### 2. View Reports

```bash
# List all reports
source /home/temlock/ai-workspace/.claude/lib/reporting.sh
list_reports

# List specific type
list_reports "security-audit"

# Get latest report
get_latest_report "security-audit"
```

### 3. Email Reports

#### Setup Email Delivery

**Option A: Simple Mail (Ubuntu/Debian)**
```bash
# Install mail command
sudo apt-get install mailutils

# Configure environment variables
export REPORT_EMAIL_ENABLED=true
export REPORT_EMAIL_TO="your-email@example.com"
export REPORT_EMAIL_FROM="ai-agents@yourdomain.com"

# Test email delivery
source /home/temlock/ai-workspace/.claude/lib/reporting.sh
REPORT=$(get_latest_report "security-audit")
send_report_email "$REPORT" "Security Audit Report - $(date +%Y-%m-%d)"
```

**Option B: Gmail SMTP (For Development)**
```bash
# Install msmtp
sudo apt-get install msmtp msmtp-mta

# Configure msmtp for Gmail
cat > ~/.msmtprc <<EOF
defaults
auth           on
tls            on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
logfile        ~/.msmtp.log

account        gmail
host           smtp.gmail.com
port           587
from           your-email@gmail.com
user           your-email@gmail.com
password       your-app-password

account default : gmail
EOF

chmod 600 ~/.msmtprc

# Test
echo "Test email" | msmtp your-email@gmail.com
```

**Option C: AWS SES (For Production)**
```bash
# Install AWS CLI
pip install awscli

# Configure AWS credentials
aws configure

# Send via SES (custom script)
# See: https://docs.aws.amazon.com/ses/
```

#### Enable Email for Agents

Add to your `.bashrc` or `.bash_profile`:

```bash
# AI Agent Reporting Configuration
export REPORT_EMAIL_ENABLED=true
export REPORT_EMAIL_TO="team@example.com"
export REPORT_EMAIL_FROM="ai-agents@yourdomain.com"
```

Or create persistent configuration:

```bash
# Create config file
cat > /home/temlock/ai-workspace/.claude/reporting-config.sh <<'EOF'
export REPORT_EMAIL_ENABLED=true
export REPORT_EMAIL_TO="security-team@example.com"
export REPORT_EMAIL_FROM="ai-security-analyzer@yourdomain.com"
export REPORTS_DIR="/home/temlock/ai-workspace/reports"
EOF

# Source in agents
source /home/temlock/ai-workspace/.claude/reporting-config.sh
```

## Report Types

### 1. Security Audit Reports

```bash
generate_security_report "$content" "$codebase" "$finding_count"
```

**Contains**:
- Executive summary
- Critical findings (P0-P3)
- HIPAA compliance assessment
- OWASP Top 10 coverage
- Remediation roadmap
- Next steps

**Example**:
```bash
REPORT=$(generate_security_report "$(cat findings.md)" "/app" "6")
send_report_email "$REPORT" "🔒 Security Audit: Critical Findings Detected"
```

### 2. Optimization Reports

```bash
generate_optimization_report "$content" "$codebase" "$optimization_count"
```

**Contains**:
- Performance analysis
- Before/after code examples
- Impact estimates (10x, 2x, etc.)
- Implementation priority
- Resource savings projections

### 3. Code Review Reports

```bash
generate_code_review_report "$content" "$codebase" "$issue_count"
```

**Contains**:
- Architecture review
- Security findings
- Performance concerns
- Best practice violations
- Prioritized recommendations

### 4. Test Execution Reports

```bash
generate_test_report "$content" "$test_suite" "$pass_fail"
```

**Contains**:
- Test results (pass/fail/skip)
- Coverage analysis
- Flaky test detection
- Missing coverage gaps
- Test quality assessment

### 5. Documentation Reports

```bash
generate_documentation_report "$content" "$project" "$coverage"
```

**Contains**:
- Documentation generated
- Gap analysis
- API documentation coverage
- Compliance documentation status
- Recommendations

## Integration with Agents

### Update Agent to Generate Reports

Edit any agent (e.g., `security-analyzer.md`) to add report generation:

```bash
# At the end of agent execution

# 1. Source reporting library
source /home/temlock/ai-workspace/.claude/lib/reporting.sh
source /home/temlock/ai-workspace/.claude/reporting-config.sh 2>/dev/null || true

# 2. Generate report
REPORT_FILE=$(generate_security_report "$FINDINGS_CONTENT" "$CODEBASE_PATH" "$FINDING_COUNT")

# 3. Email report (if enabled)
if [[ "$REPORT_EMAIL_ENABLED" == "true" ]]; then
    send_report_email "$REPORT_FILE" "Security Audit Report - $(date +%Y-%m-%d)"
fi

# 4. Display report location
echo ""
echo "📄 Report saved: $REPORT_FILE"
echo "📧 Email sent: $([ "$REPORT_EMAIL_ENABLED" == "true" ] && echo "Yes" || echo "No (disabled)")"
```

## Report Management

### List Reports

```bash
# All reports
list_reports

# Specific type
list_reports "security-audit"
list_reports "optimization"
list_reports "code-review"
```

### Get Latest Report

```bash
# Get latest security audit
LATEST=$(get_latest_report "security-audit")
cat "$LATEST"

# Open in browser (if HTML)
xdg-open "$LATEST"
```

### Archive Old Reports

```bash
# Archive reports older than 30 days
archive_old_reports 30

# Archive reports older than 7 days
archive_old_reports 7

# View archived reports
ls /home/temlock/ai-workspace/reports/archive/
```

### Convert to HTML

```bash
# Install pandoc (if not installed)
sudo apt-get install pandoc

# Convert report
HTML_FILE=$(convert_report_to_html "$REPORT_FILE")
echo "HTML report: $HTML_FILE"

# Open in browser
xdg-open "$HTML_FILE"
```

## Email Templates

### Security Alert Email

```bash
SUBJECT="🔒 CRITICAL: Security Vulnerabilities Detected - $(date +%Y-%m-%d)"
send_report_email "$REPORT" "$SUBJECT" "security-team@example.com"
```

### Weekly Summary Email

```bash
SUBJECT="📊 Weekly Code Quality Report - Week $(date +%V)"
send_report_email "$REPORT" "$SUBJECT" "dev-team@example.com"
```

### Client Deliverable

```bash
SUBJECT="✅ Project Security Audit - $(date +%B %Y)"
send_report_email "$REPORT" "$SUBJECT" "client@example.com"
```

## Advanced Configuration

### Multiple Recipients

```bash
# Send to multiple people
RECIPIENTS="security@example.com,devops@example.com,cto@example.com"

for recipient in ${RECIPIENTS//,/ }; do
    send_report_email "$REPORT" "$SUBJECT" "$recipient"
done
```

### Custom Report Templates

Create your own report generator:

```bash
generate_custom_report() {
    local content="$1"
    local timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
    local report_file="$REPORTS_DIR/custom_${timestamp}.md"

    cat > "$report_file" <<EOF
# Custom Report

**Client**: Your Client Name
**Project**: Project Name
**Date**: $(date)

---

$content

---

**Prepared By**: Your Company
**Contact**: support@yourcompany.com
EOF

    echo "$report_file"
}
```

### Scheduled Reports

Use cron to generate daily/weekly reports:

```bash
# Edit crontab
crontab -e

# Add daily security audit (9 AM)
0 9 * * * cd /home/temlock/ai-workspace && /security-audit-script.sh

# Add weekly summary (Friday 5 PM)
0 17 * * 5 cd /home/temlock/ai-workspace && /weekly-summary-script.sh
```

## Troubleshooting

### Email Not Sending

**Check 1: Is email enabled?**
```bash
echo $REPORT_EMAIL_ENABLED
# Should be: true
```

**Check 2: Is recipient configured?**
```bash
echo $REPORT_EMAIL_TO
# Should be: your-email@example.com
```

**Check 3: Is mail command installed?**
```bash
which mail
which sendmail
which mutt
# At least one should be found
```

**Check 4: Test mail manually**
```bash
echo "Test email" | mail -s "Test" your-email@example.com
```

### Reports Not Generating

**Check 1: Reports directory exists**
```bash
ls -la /home/temlock/ai-workspace/reports/
```

**Check 2: Permissions**
```bash
chmod 755 /home/temlock/ai-workspace/reports/
chmod +x /home/temlock/ai-workspace/.claude/lib/reporting.sh
```

**Check 3: Library loaded**
```bash
source /home/temlock/ai-workspace/.claude/lib/reporting.sh
# Should see: [INFO] Reporting library loaded
```

## Best Practices

### For Healthcare/Compliance Projects

1. **Always generate reports** for security audits
2. **Email to compliance team** immediately for P0 findings
3. **Archive reports** for audit trail (7 years for HIPAA)
4. **Include HIPAA references** in all findings
5. **Encrypt sensitive reports** before emailing

### For Client Projects

1. **Professional formatting** - use formal language
2. **Executive summaries** - include for management
3. **Clear next steps** - actionable recommendations
4. **Regular delivery** - weekly or bi-weekly updates
5. **Version control** - track report history

### For Internal Development

1. **Automated reporting** - integrate with CI/CD
2. **Trend analysis** - compare reports over time
3. **Team notifications** - email relevant teams
4. **Quick fixes** - prioritize P0/P1 findings
5. **Learning** - document patterns and improvements

## Example Workflows

### Daily Security Scan

```bash
#!/bin/bash
# daily-security-scan.sh

source /home/temlock/ai-workspace/.claude/lib/delegation.sh
source /home/temlock/ai-workspace/.claude/lib/reporting.sh

# Run security scan
FINDINGS=$(delegate_to_gemini "daily-scan" "/app" "security-prompt.txt")

# Generate report
REPORT=$(generate_security_report "$(cat $FINDINGS)" "/app" "Auto")

# Email if critical findings
if grep -q "P0" "$REPORT"; then
    send_report_email "$REPORT" "🚨 CRITICAL Security Issues Detected" "security-team@example.com"
fi
```

### Weekly Code Review

```bash
#!/bin/bash
# weekly-code-review.sh

# Get changed files this week
CHANGED_FILES=$(git diff --name-only HEAD@{7.days.ago})

# Review with Codex
REVIEW=$(delegate_to_codex "weekly-review" "$CHANGED_FILES" "review-prompt.txt")

# Generate report
REPORT=$(generate_code_review_report "$(cat $REVIEW)" "Weekly Changes" "Auto")

# Email to team
send_report_email "$REPORT" "📋 Weekly Code Review" "dev-team@example.com"
```

## Support

For issues with reporting:
1. Check `/tmp/ai-delegation.log` for errors
2. Verify email configuration
3. Test mail command manually
4. Contact: support@yourcompany.com

---

**Last Updated**: 2025-11-20
**Maintained By**: Tom Vitso + Claude Code
