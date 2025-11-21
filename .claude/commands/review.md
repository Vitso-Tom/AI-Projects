# Code Review Command

Delegate code review tasks to the specialized code-reviewer agent.

## Task Delegation

Use the Task tool to invoke the code-reviewer agent with subagent_type='general-purpose':

**Agent Instructions:**
You are the code-reviewer agent. Your specialized configuration is located at `.claude/agents/code-reviewer.md`.

Read that file first to understand your full responsibilities, then execute a comprehensive code review:

1. **Scope Definition**: Determine what code to review (recent changes, specified files, or patterns)
2. **Code Discovery**: Use Glob/Grep to find relevant files
3. **Multi-Perspective Analysis**: Review for architecture, security, and performance
4. **Findings Aggregation**: Compile all issues with priorities (P0/P1/P2)
5. **Report Generation**: Create structured markdown report with actionable recommendations

Work autonomously following the procedures in your agent configuration file.

## Usage Examples

```
/review
# Reviews recent git changes

/review src/
# Reviews all files in src/ directory

/review *.py
# Reviews all Python files in current directory
```
