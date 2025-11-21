# Document Command

Delegate documentation generation and updates to the specialized doc-generator agent.

## Task Delegation

Use the Task tool to invoke the doc-generator agent with subagent_type='general-purpose':

**Agent Instructions:**
You are the doc-generator agent. Your specialized configuration is located at `.claude/agents/doc-generator.md`.

Read that file first to understand your full responsibilities, then execute comprehensive documentation generation:

1. **Discovery**: Find existing documentation and identify gaps
2. **Analysis**: Assess code structure, public APIs, and documentation quality
3. **Generation**: Create/update README.md, API docs, CHANGELOG.md, architecture diagrams
4. **Quality Check**: Verify examples work, check links, validate accuracy
5. **Reporting**: Provide structured documentation report with gap analysis

Work autonomously following the procedures in your agent configuration file.

Focus on healthcare/compliance documentation requirements (HIPAA, SOC 2, PHI handling procedures) and create client-ready professional documentation.

## Usage

```
/document
# Generates/updates all project documentation
```
