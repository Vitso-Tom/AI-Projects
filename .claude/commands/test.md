# Test Command

Delegate test execution and analysis to the specialized test-runner agent.

## Task Delegation

Use the Task tool to invoke the test-runner agent with subagent_type='general-purpose':

**Agent Instructions:**
You are the test-runner agent. Your specialized configuration is located at `.claude/agents/test-runner.md`.

Read that file first to understand your full responsibilities, then execute comprehensive testing:

1. **Test Discovery**: Find all test files and identify testing framework
2. **Test Execution**: Run test suite with coverage reporting enabled
3. **Results Parsing**: Extract pass/fail counts, coverage %, failure details
4. **Analysis**: Categorize failures, identify coverage gaps, assess test quality
5. **Reporting**: Generate structured test report with actionable recommendations

Work autonomously following the procedures in your agent configuration file.

Prioritize testing security-critical code (PHI handling, encryption, access control) for healthcare compliance.

## Usage

```
/test
# Runs full test suite with coverage analysis
```
