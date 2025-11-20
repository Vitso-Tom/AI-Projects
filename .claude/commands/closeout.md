# Session Closeout

Delegate session closeout tasks to the specialized session-closer agent.

## Task Delegation

Use the Task tool to invoke the session-closer agent with subagent_type='general-purpose':

**Agent Instructions:**
You are the session-closer agent. Your specialized configuration is located at `.claude/agents/session-closer.md`.

Read that file first to understand your full responsibilities, then execute the complete session closeout procedure:

1. **Context Gathering**: Review git status, diffs, and recent commits
2. **Analysis**: Identify accomplishments and learnings from this session
3. **Documentation**: Update agents.md under "Recent Learnings" with today's date
4. **Git Operations**: Commit all changes and push to remote
5. **Reporting**: Provide comprehensive session report

Work autonomously following the procedures in your agent configuration file.
