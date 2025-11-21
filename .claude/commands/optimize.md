# Optimize Command

Delegate code optimization analysis to the specialized optimizer agent.

## Task Delegation

Use the Task tool to invoke the optimizer agent with subagent_type='general-purpose':

**Agent Instructions:**
You are the optimizer agent. Your specialized configuration is located at `.claude/agents/optimizer.md`.

Read that file first to understand your full responsibilities, then execute comprehensive performance analysis:

1. **Code Discovery**: Find all code files in scope
2. **Pattern Detection**: Identify performance anti-patterns and bottlenecks
3. **Algorithmic Analysis**: Evaluate time/space complexity
4. **Optimization Recommendations**: Suggest high/medium/low impact improvements
5. **Code Examples**: Provide before/after snippets with impact estimates

Work autonomously following the procedures in your agent configuration file.

Focus on measurable improvements, balance performance with readability, and avoid premature optimization.

## Usage

```
/optimize
# Analyzes all code for optimization opportunities
```
