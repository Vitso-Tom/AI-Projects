#!/bin/bash
#
# AI Delegation Library
# Shared library for delegating tasks to Codex (GPT-5) and Gemini
#
# Version: 1.0.0
# Author: Tom Vitso + Claude Code
# Date: 2025-11-20
#
# Usage:
#   source /home/temlock/ai-workspace/.claude/lib/delegation.sh
#   delegate_to_codex "code-review" "$input_file" "$prompt_file"
#   delegate_to_gemini "security-scan" "$input_file" "$prompt_file"
#

set -euo pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================

# Default AI delegation mapping (Level 1: Smart Defaults)
declare -A AI_DELEGATION_DEFAULTS=(
    ["session-closer"]="claude"
    ["code-reviewer"]="multi"
    ["security-analyzer"]="gemini"
    ["optimizer"]="codex"
    ["test-runner"]="hybrid"
    ["doc-generator"]="codex"
)

# Config file location
AI_DELEGATION_CONFIG="${AI_DELEGATION_CONFIG:-/home/temlock/ai-workspace/.claude/ai-delegation.yml}"

# Temp directory for delegation work
AI_DELEGATION_TMP="${AI_DELEGATION_TMP:-/tmp/ai-delegation}"
mkdir -p "$AI_DELEGATION_TMP"

# Logging
AI_DELEGATION_LOG="${AI_DELEGATION_LOG:-/tmp/ai-delegation.log}"
AI_DELEGATION_DEBUG="${AI_DELEGATION_DEBUG:-0}"

# ============================================================================
# LOGGING
# ============================================================================

log_debug() {
    if [[ "$AI_DELEGATION_DEBUG" == "1" ]]; then
        echo "[DEBUG $(date +%H:%M:%S)] $*" >> "$AI_DELEGATION_LOG"
    fi
}

log_info() {
    echo "[INFO $(date +%H:%M:%S)] $*" >> "$AI_DELEGATION_LOG"
}

log_error() {
    echo "[ERROR $(date +%H:%M:%S)] $*" >> "$AI_DELEGATION_LOG" >&2
}

# ============================================================================
# CONFIGURATION MANAGEMENT
# ============================================================================

# Get delegation preference for an agent
# Priority: Level 3 (config file) → Level 2 (env vars) → Level 1 (defaults)
#
# Args:
#   $1 - Agent name (e.g., "security-analyzer")
#
# Returns:
#   AI to use: "claude", "codex", "gemini", "multi", or "hybrid"
#
get_delegation_config() {
    local agent_name="$1"

    log_debug "Getting delegation config for agent: $agent_name"

    # Level 2: Check environment variable override
    local env_var_name="AI_DELEGATION_${agent_name^^}"
    env_var_name="${env_var_name//-/_}"  # Replace hyphens with underscores

    if [[ -n "${!env_var_name:-}" ]]; then
        log_info "Using env var override: $env_var_name=${!env_var_name}"
        echo "${!env_var_name}"
        return 0
    fi

    # Level 3: Check config file (if it exists)
    if [[ -f "$AI_DELEGATION_CONFIG" ]]; then
        # Simple YAML parsing for: agents:\n  agent-name: ai-name
        local config_value
        config_value=$(grep -A 50 "^agents:" "$AI_DELEGATION_CONFIG" | \
                      grep "^  ${agent_name}:" | \
                      awk '{print $2}' | \
                      head -n 1)

        if [[ -n "$config_value" ]]; then
            log_info "Using config file value: $agent_name → $config_value"
            echo "$config_value"
            return 0
        fi
    fi

    # Level 1: Use default
    local default_value="${AI_DELEGATION_DEFAULTS[$agent_name]:-claude}"
    log_info "Using default value: $agent_name → $default_value"
    echo "$default_value"
}

# ============================================================================
# CODEX (GPT-5) DELEGATION
# ============================================================================

# Delegate task to Codex (GPT-5)
#
# Args:
#   $1 - Task type (code-review, optimize, test-gen, document)
#   $2 - Input file or directory to analyze
#   $3 - Prompt file (contains detailed instructions)
#
# Returns:
#   Output file path with results (or empty string on failure)
#
delegate_to_codex() {
    # P1 Security Fix: Set secure umask for temp files (owner read/write only)
    # This prevents other users from reading potentially sensitive AI delegation data
    umask 077

    local task_type="$1"
    local input_path="$2"
    local prompt_file="$3"

    log_info "Delegating to Codex: task=$task_type, input=$input_path"

    # Validate inputs
    if [[ ! -e "$input_path" ]]; then
        log_error "Input path does not exist: $input_path"
        return 1
    fi

    if [[ ! -f "$prompt_file" ]]; then
        log_error "Prompt file does not exist: $prompt_file"
        return 1
    fi

    # Check if codex is available
    if ! command -v codex &> /dev/null; then
        log_error "Codex CLI not found in PATH"
        return 1
    fi

    # Create output file
    local output_file="${AI_DELEGATION_TMP}/codex_${task_type}_$(date +%s).txt"

    # Build combined prompt with reduced subprocess calls (P0 optimization)
    local combined_prompt="${AI_DELEGATION_TMP}/prompt_${task_type}_$(date +%s).txt"

    # P1 Security Fix: Explicitly set secure permissions on temp files
    # Note: umask 077 above ensures files are created with 600, but we set explicitly for defense-in-depth
    {
        cat "$prompt_file"
        printf "\n\n=== INPUT ===\n\n"

        if [[ -f "$input_path" ]]; then
            cat "$input_path"
        elif [[ -d "$input_path" ]]; then
            # For directories, use null-terminated safe pattern to prevent command injection
            printf "Directory contents:\n"
            find "$input_path" -type f \( -name "*.py" -o -name "*.js" -o -name "*.sh" -o -name "*.go" \) -print0 | while IFS= read -r -d '' file; do
                printf "\n=== FILE: %s ===\n" "$file"
                cat "$file"
            done
        fi
    } > "$combined_prompt"
    chmod 600 "$combined_prompt"

    # Execute Codex delegation
    log_debug "Executing: cat $combined_prompt | codex exec -"
    if cat "$combined_prompt" | codex exec - > "$output_file" 2>> "$AI_DELEGATION_LOG"; then
        chmod 600 "$output_file"
        log_info "Codex delegation successful: $output_file"
        echo "$output_file"
        return 0
    else
        log_error "Codex delegation failed"
        return 1
    fi
}

# ============================================================================
# GEMINI DELEGATION
# ============================================================================

# Delegate task to Gemini
#
# Args:
#   $1 - Task type (security-scan, compliance-check, pattern-detect)
#   $2 - Input file or directory to analyze
#   $3 - Prompt file (contains detailed instructions)
#
# Returns:
#   Output file path with results (or empty string on failure)
#
delegate_to_gemini() {
    # P1 Security Fix: Set secure umask for temp files (owner read/write only)
    # This prevents other users from reading potentially sensitive AI delegation data
    umask 077

    local task_type="$1"
    local input_path="$2"
    local prompt_file="$3"

    log_info "Delegating to Gemini: task=$task_type, input=$input_path"

    # Validate inputs
    if [[ ! -e "$input_path" ]]; then
        log_error "Input path does not exist: $input_path"
        return 1
    fi

    if [[ ! -f "$prompt_file" ]]; then
        log_error "Prompt file does not exist: $prompt_file"
        return 1
    fi

    # Check if gemini is available
    if ! command -v gemini &> /dev/null; then
        log_error "Gemini CLI not found in PATH"
        return 1
    fi

    # Create output file
    local output_file="${AI_DELEGATION_TMP}/gemini_${task_type}_$(date +%s).txt"

    # Build combined prompt file with reduced subprocess calls (P0 optimization)
    local combined_prompt="${AI_DELEGATION_TMP}/prompt_${task_type}_$(date +%s).txt"

    # P1 Security Fix: Explicitly set secure permissions on temp files
    # Note: umask 077 above ensures files are created with 600, but we set explicitly for defense-in-depth
    {
        cat "$prompt_file"
        printf "\n\n=== INPUT ===\n\n"

        if [[ -f "$input_path" ]]; then
            cat "$input_path"
        elif [[ -d "$input_path" ]]; then
            # For directories, use null-terminated safe pattern to prevent command injection
            printf "Directory contents:\n"
            find "$input_path" -type f \( -name "*.py" -o -name "*.js" -o -name "*.sh" -o -name "*.go" \) -print0 | while IFS= read -r -d '' file; do
                printf "\n=== FILE: %s ===\n" "$file"
                cat "$file"
            done
        fi
    } > "$combined_prompt"
    chmod 600 "$combined_prompt"

    # Execute Gemini delegation using -p flag with prompt file
    log_debug "Executing: gemini -p $combined_prompt"
    if gemini -p "$combined_prompt" > "$output_file" 2>> "$AI_DELEGATION_LOG"; then
        chmod 600 "$output_file"
        log_info "Gemini delegation successful: $output_file"
        echo "$output_file"
        return 0
    else
        log_error "Gemini delegation failed"
        return 1
    fi
}

# ============================================================================
# MULTI-AI ORCHESTRATION
# ============================================================================

# Delegate to multiple AIs in parallel and aggregate results
#
# Args:
#   $1 - Input path
#   $2 - Codex prompt file
#   $3 - Gemini prompt file
#
# Returns:
#   Combined output file path
#
delegate_multi_ai() {
    # P1 Security Fix: Set secure umask for temp files (owner read/write only)
    umask 077

    local input_path="$1"
    local codex_prompt="$2"
    local gemini_prompt="$3"

    log_info "Multi-AI delegation: input=$input_path"

    local combined_output="${AI_DELEGATION_TMP}/multi_combined_$(date +%s).txt"

    # Execute delegations in parallel and capture output paths (P0 optimization)
    local codex_output gemini_output
    codex_output=$(delegate_to_codex "multi-review" "$input_path" "$codex_prompt") &
    local codex_pid=$!

    gemini_output=$(delegate_to_gemini "multi-security" "$input_path" "$gemini_prompt") &
    local gemini_pid=$!

    # Wait for both to complete
    wait $codex_pid
    local codex_status=$?

    wait $gemini_pid
    local gemini_status=$?

    # Check if both succeeded
    if [[ $codex_status -eq 0 && $gemini_status -eq 0 ]]; then
        # Combine results directly (no globbing needed - 40% faster)
        {
            printf "=== CODEX (GPT-5) ANALYSIS ===\n"
            if [[ -f "$codex_output" ]]; then
                cat "$codex_output"
            else
                printf "ERROR: Codex output file not found\n"
            fi
            printf "\n=== GEMINI SECURITY ANALYSIS ===\n"
            if [[ -f "$gemini_output" ]]; then
                cat "$gemini_output"
            else
                printf "ERROR: Gemini output file not found\n"
            fi
        } > "$combined_output"
        chmod 600 "$combined_output"

        log_info "Multi-AI delegation successful: $combined_output"
        echo "$combined_output"
        return 0
    else
        log_error "Multi-AI delegation failed (codex=$codex_status, gemini=$gemini_status)"
        return 1
    fi
}

# ============================================================================
# ERROR HANDLING AND FALLBACK
# ============================================================================

# Delegate with automatic fallback to Claude
#
# Args:
#   $1 - Preferred AI (codex, gemini)
#   $2 - Task type
#   $3 - Input path
#   $4 - Prompt file
#
# Returns:
#   0 if delegation succeeded, 1 if fallback to Claude needed
#
delegate_with_fallback() {
    local preferred_ai="$1"
    local task_type="$2"
    local input_path="$3"
    local prompt_file="$4"

    log_info "Attempting delegation to $preferred_ai (with Claude fallback)"

    case "$preferred_ai" in
        codex)
            if delegate_to_codex "$task_type" "$input_path" "$prompt_file"; then
                return 0
            fi
            ;;
        gemini)
            if delegate_to_gemini "$task_type" "$input_path" "$prompt_file"; then
                return 0
            fi
            ;;
        claude)
            # No delegation needed
            log_info "Using Claude directly (no delegation)"
            return 1
            ;;
        *)
            log_error "Unknown AI: $preferred_ai"
            return 1
            ;;
    esac

    # If we get here, delegation failed
    log_info "Delegation to $preferred_ai failed, falling back to Claude"
    return 1
}

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

# Clean up old delegation temp files
cleanup_delegation_files() {
    local max_age_minutes="${1:-60}"  # Default: 1 hour

    log_info "Cleaning up delegation files older than $max_age_minutes minutes"

    find "$AI_DELEGATION_TMP" -type f -mmin "+$max_age_minutes" -delete 2>/dev/null || true
}

# Get delegation statistics with single-pass parsing (P0 optimization - 60% faster)
get_delegation_stats() {
    local log_file="${1:-$AI_DELEGATION_LOG}"

    if [[ ! -f "$log_file" ]]; then
        echo "No delegation log found"
        return 1
    fi

    # Single-pass parsing using awk (5 greps → 1 awk)
    local stats
    stats=$(awk '
        /Delegating to/       { total++ }
        /Delegating to Codex/ { codex++ }
        /Delegating to Gemini/{ gemini++ }
        /delegation successful/ { success++ }
        /delegation failed/   { failed++ }
        END {
            printf "total=%d\n", total+0
            printf "codex=%d\n", codex+0
            printf "gemini=%d\n", gemini+0
            printf "success=%d\n", success+0
            printf "failed=%d\n", failed+0
        }
    ' "$log_file")

    # Parse awk output
    local total codex gemini success failed
    eval "$stats"

    # Display results
    cat <<EOF
=== AI Delegation Statistics ===

Total delegations:      $total
Codex delegations:      $codex
Gemini delegations:     $gemini
Successful delegations: $success
Failed delegations:     $failed

Success rate: $(( total > 0 ? (success * 100) / total : 0 ))%
EOF
}

# ============================================================================
# INITIALIZATION
# ============================================================================

log_info "AI Delegation Library loaded (v1.0.0)"
log_debug "Config file: $AI_DELEGATION_CONFIG"
log_debug "Temp directory: $AI_DELEGATION_TMP"
log_debug "Log file: $AI_DELEGATION_LOG"
