# AI Delegation Strategy

**Version**: 1.0.0
**Date**: 2025-11-20
**Status**: Based on systematic capability testing

## Overview

This document defines the optimal delegation strategy for distributing work across Claude, Codex (GPT-5), and Gemini to maximize efficiency while minimizing Claude token consumption.

## Test Results Summary

### Codex (GPT-5) Capabilities Assessment

| Test Category | Rating | Key Findings |
|--------------|--------|--------------|
| Code Review | ✅ Excellent | Line-specific feedback, security-aware, actionable |
| Optimization | ✅ Exceptional | Before/after examples, algorithmic improvements, measurable impact |
| Documentation | ✅ Good | Comprehensive API docs, professional formatting |
| Test Generation | ✅ Exceptional | Autonomous test suite creation, mocking framework, edge cases |

**Conclusion**: Codex (GPT-5) demonstrates exceptional capabilities across all tested dimensions, particularly in optimization and test generation. Quality consistently meets or exceeds professional standards.

## AI Capability Matrix

| AI Model | Best For | Token Cost | Speed | Quality |
|----------|----------|------------|-------|---------|
| **Claude (Sonnet 4.5)** | Orchestration, planning, complex reasoning, healthcare context | High | Fast | Excellent |
| **Codex (GPT-5)** | Optimization, test generation, code review, technical depth | Medium | Fast | Exceptional |
| **Gemini** | Pattern detection, security scanning, compliance checking | Low | Very Fast | Good |

## Recommended Agent Delegation

### 1. session-closer → **Claude**
**Rationale**: Orchestration task requiring context synthesis and git operations
- Complex multi-step workflow
- Requires understanding of full session context
- Git commit message generation needs healthcare/consulting context
- No delegation needed (token cost justified by complexity)

### 2. code-reviewer → **Multi-AI Orchestration**
**Rationale**: Leverage multiple perspectives for comprehensive review

**Delegation Pattern**:
```bash
# Phase 1: Architecture & Code Quality → Codex (GPT-5)
# Phase 2: Security & Compliance → Gemini
# Phase 3: Aggregation & Reporting → Claude
```

**Token Savings**: ~60% (delegate heavy analysis, Claude handles aggregation)

### 3. security-analyzer → **Gemini**
**Rationale**: Pattern matching and compliance checking are Gemini strengths

**Delegation Pattern**:
```bash
# OWASP Top 10 scanning → Gemini
# HIPAA compliance checking → Gemini
# SOC 2 control mapping → Gemini
# Report aggregation → Claude
```

**Token Savings**: ~70% (Gemini excels at pattern detection)

### 4. optimizer → **Codex (GPT-5)**
**Rationale**: Test results show exceptional optimization capabilities

**Delegation Pattern**:
```bash
# Algorithmic analysis → Codex
# Before/after code examples → Codex
# Performance impact estimation → Codex
# Report formatting → Claude
```

**Token Savings**: ~65% (Codex demonstrated exceptional optimization quality)

### 5. test-runner → **Hybrid (Bash execution + Codex analysis)**
**Rationale**: Test execution is native bash, Codex excels at test generation

**Delegation Pattern**:
```bash
# Test execution → Bash (no AI needed)
# Coverage analysis → Bash tools
# Failure analysis → Codex (when needed)
# Test suggestion generation → Codex
```

**Token Savings**: ~50% (most work is bash commands, Codex for recommendations)

### 6. doc-generator → **Codex (GPT-5)**
**Rationale**: Strong documentation generation with technical depth

**Delegation Pattern**:
```bash
# API documentation → Codex
# Code comment generation → Codex
# Architecture diagrams → Codex
# README narrative sections → Claude (better at storytelling)
# Compliance documentation → Claude (healthcare context)
```

**Token Savings**: ~55% (Codex handles technical docs, Claude handles narrative)

## Token Economics

### Current (No Delegation)
- Average agent execution: ~30,000 tokens
- 6 agents × 30K = 180,000 tokens per full workflow

### With Delegation (Proposed)
- Claude orchestration: ~10,000 tokens per agent
- Delegated AI work: Free (Gemini) or low-cost (Codex)
- 6 agents × 10K = 60,000 tokens per full workflow

**Savings**: ~67% token reduction while maintaining or improving quality

## Implementation Architecture

### Shared Delegation Library

**Location**: `.claude/lib/delegation.sh`

**Functions**:
```bash
# Delegate task to Codex (GPT-5)
delegate_to_codex() {
    local task_type="$1"  # code-review, optimize, test-gen, document
    local input_file="$2"  # File to analyze
    local prompt_file="$3"  # Detailed prompt
    # Returns: Output file path with results
}

# Delegate task to Gemini
delegate_to_gemini() {
    local task_type="$1"  # security-scan, compliance-check, pattern-detect
    local input_file="$2"  # File to analyze
    local prompt_file="$3"  # Detailed prompt
    # Returns: Output file path with results
}

# Get delegation preference for agent
get_delegation_config() {
    local agent_name="$1"  # security-analyzer, optimizer, etc.
    # Returns: AI to use (claude, codex, gemini, or "multi")
    # Checks: 1) .claude/ai-delegation.yml, 2) $AI_DELEGATION_* env vars, 3) defaults
}
```

### Configuration System (3 Levels)

#### Level 1: Smart Defaults (Hardcoded)
```yaml
# Defaults embedded in delegation.sh
defaults:
  session-closer: claude
  code-reviewer: multi  # Codex + Gemini
  security-analyzer: gemini
  optimizer: codex
  test-runner: hybrid  # Bash + Codex
  doc-generator: codex
```

#### Level 2: Environment Variables (Session Override)
```bash
# User can override per session
export AI_DELEGATION_SECURITY_ANALYZER=codex
export AI_DELEGATION_OPTIMIZER=claude
```

#### Level 3: Config File (Persistent Override)
```yaml
# .claude/ai-delegation.yml
agents:
  security-analyzer: gemini
  optimizer: codex
  code-reviewer:
    architecture: codex
    security: gemini
    aggregation: claude
```

## Rollout Plan

### Phase 1: Build Infrastructure ✅
- [x] Test Codex capabilities
- [x] Create delegation strategy
- [ ] Build `.claude/lib/delegation.sh`
- [ ] Create `.claude/ai-delegation.yml.template`

### Phase 2: POC (Single Agent)
- [ ] Implement delegation in `security-analyzer.md` (Gemini delegation)
- [ ] Test end-to-end workflow
- [ ] Validate token savings
- [ ] Validate quality maintained/improved

### Phase 3: Expand (High-Value Agents)
- [ ] Add delegation to `optimizer.md` (Codex delegation)
- [ ] Add delegation to `code-reviewer.md` (Multi-AI orchestration)
- [ ] Test cross-agent workflows

### Phase 4: Complete Rollout
- [ ] Add delegation to `doc-generator.md`
- [ ] Add delegation to `test-runner.md`
- [ ] Document delegation architecture in `ARCHITECTURE.md`
- [ ] Update `agents.md` learning log

### Phase 5: Optimization
- [ ] Gather usage metrics
- [ ] Refine delegation strategy based on real-world usage
- [ ] Add caching layer for repeated analyses
- [ ] Create delegation performance dashboard

## Usage Examples

### Example 1: Security Analysis (Gemini Delegation)
```bash
# User runs: /security-audit

# security-analyzer agent flow:
1. Gather codebase files to analyze
2. Call delegate_to_gemini("security-scan", "src/", "owasp-hipaa-prompt.txt")
3. Parse Gemini output (OWASP findings)
4. Call delegate_to_gemini("compliance-check", "src/", "hipaa-soc2-prompt.txt")
5. Parse Gemini output (compliance findings)
6. Claude aggregates findings into structured report
7. Return comprehensive security audit report

# Token usage: ~8K Claude tokens (vs ~30K without delegation)
```

### Example 2: Code Optimization (Codex Delegation)
```bash
# User runs: /optimize

# optimizer agent flow:
1. Discover code files to optimize
2. Call delegate_to_codex("optimize", "src/processor.py", "optimization-prompt.txt")
3. Parse Codex output (before/after examples, impact estimates)
4. Claude formats report with prioritization
5. Return optimization recommendations report

# Token usage: ~10K Claude tokens (vs ~30K without delegation)
```

### Example 3: Multi-AI Code Review (Orchestration)
```bash
# User runs: /review

# code-reviewer agent flow:
1. Gather code files to review
2. PARALLEL EXECUTION:
   a. delegate_to_codex("code-review", "src/", "architecture-quality-prompt.txt")
   b. delegate_to_gemini("security-scan", "src/", "security-prompt.txt")
3. Wait for both to complete
4. Claude aggregates findings by priority (P0/P1/P2)
5. Claude cross-references findings (e.g., security issue + architectural smell)
6. Return comprehensive multi-perspective review

# Token usage: ~12K Claude tokens (vs ~35K without delegation)
```

## Decision Tree for Delegation

```
Is this task orchestration/planning?
├─ YES → Use Claude (complex reasoning needed)
└─ NO → Continue

Does task involve security pattern matching?
├─ YES → Use Gemini (fast, good at patterns)
└─ NO → Continue

Does task require code optimization or test generation?
├─ YES → Use Codex (exceptional quality demonstrated)
└─ NO → Continue

Does task require healthcare/compliance context?
├─ YES → Use Claude (domain expertise)
└─ NO → Use Codex (general technical task)
```

## Quality Assurance

### Validation Criteria
- [ ] Delegated output quality ≥ Claude quality
- [ ] Token savings ≥ 50% per agent
- [ ] No increase in error rates
- [ ] User satisfaction maintained/improved
- [ ] Healthcare/compliance context preserved

### Monitoring Metrics
- Token consumption per agent (before/after)
- Quality scores (manual review of reports)
- User feedback on report usefulness
- Time to completion (delegation should not slow down)
- Error rates (parsing failures, API errors)

## Risk Mitigation

### Risk 1: Delegated AI Output Quality Issues
**Mitigation**: Claude validates all delegated output before returning to user
**Fallback**: If output quality is insufficient, re-run with Claude

### Risk 2: API Rate Limits
**Mitigation**: Respect rate limits with exponential backoff
**Fallback**: Gracefully degrade to Claude-only execution

### Risk 3: Parsing Failures
**Mitigation**: Robust parsing with error handling
**Fallback**: Log error and use Claude as backup

### Risk 4: Loss of Healthcare Context
**Mitigation**: All compliance-related tasks stay with Claude or have Claude aggregation phase
**Fallback**: Critical healthcare tasks (PHI handling) never delegated

## Success Criteria

**POC Success** (Phase 2):
- ✅ security-analyzer delegation works end-to-end
- ✅ Token savings ≥ 50%
- ✅ Output quality ≥ Claude baseline
- ✅ No increase in execution time

**Rollout Success** (Phase 4):
- ✅ All 6 agents support delegation
- ✅ Average token savings ≥ 60%
- ✅ Configuration system works (3 levels)
- ✅ Documentation complete
- ✅ User can easily override delegation per agent

## Next Steps

1. **Immediate**: Build `.claude/lib/delegation.sh` library
2. **Immediate**: Create `.claude/ai-delegation.yml.template`
3. **POC**: Implement delegation in `security-analyzer.md`
4. **Validation**: Test POC and measure token savings
5. **Expand**: Roll out to remaining agents

---

**Maintained By**: Tom Vitso + Claude Code
**Last Updated**: 2025-11-20
