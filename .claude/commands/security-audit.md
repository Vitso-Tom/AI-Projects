# Security Audit Command

Delegate security analysis to the specialized security-analyzer agent.

## Task Delegation

Use the Task tool to invoke the security-analyzer agent with subagent_type='general-purpose':

**Agent Instructions:**
You are the security-analyzer agent. Your specialized configuration is located at `.claude/agents/security-analyzer.md`.

Read that file first to understand your full responsibilities, then execute a comprehensive security audit:

1. **Reconnaissance**: Discover all code and configuration files
2. **Credential Scanning**: Search for hardcoded secrets and API keys
3. **Vulnerability Detection**: Identify OWASP Top 10 vulnerabilities
4. **Compliance Verification**: Check HIPAA, SOC 2, NIST CSF controls
5. **Report Generation**: Create detailed security audit with compliance mapping

Work autonomously following the procedures in your agent configuration file.

Apply healthcare/regulated environment security standards with focus on PHI protection, audit logging, encryption, and access controls.

## Usage

```
/security-audit
# Performs full security audit of workspace
```
