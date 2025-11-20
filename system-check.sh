#!/bin/bash
set -euo pipefail

# system-check.sh - A colorful system health checker
# Checks disk space, memory usage, and largest files

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Box drawing characters
HLINE="═"
VLINE="║"
TL="╔"
TR="╗"
BL="╚"
BR="╝"

# Repeat a character N times without external utilities
repeat_char() {
    local char="$1"
    local count=${2:-0}
    if (( count <= 0 )); then
        echo ""
        return
    fi
    local line
    printf -v line '%*s' "$count" ''
    echo "${line// /$char}"
}

# Convert kibibytes to a human-readable unit with one decimal
human_readable_kib() {
    local kib=${1:-0}
    if (( kib < 0 )); then
        kib=0
    fi
    local units=(KiB MiB GiB TiB PiB)
    local unit_index=0
    local scaled=$((kib * 10))
    while (( scaled >= 10240 && unit_index < ${#units[@]} - 1 )); do
        scaled=$(( (scaled + 512) / 1024 ))
        ((unit_index++))
    done
    local integer=$((scaled / 10))
    local decimal=$((scaled % 10))
    if (( decimal == 0 )); then
        printf "%d %s" "$integer" "${units[unit_index]}"
    else
        printf "%d.%d %s" "$integer" "$decimal" "${units[unit_index]}"
    fi
}

# Function to print a header box
print_header() {
    local title="$1"
    local color="$2"
    local width=50
    local padding=$(( (width - ${#title} - 2) / 2 ))
    (( padding < 0 )) && padding=0
    local remainder=$((width - padding - ${#title} - 2))
    (( remainder < 0 )) && remainder=0
    local horizontal
    horizontal=$(repeat_char "${HLINE}" "$width")
    local left_pad right_pad
    printf -v left_pad '%*s' "$padding" ''
    printf -v right_pad '%*s' "$remainder" ''

    echo ""
    echo -e "${color}${TL}${horizontal}${TR}${NC}"
    echo -e "${color}${VLINE}${left_pad}${WHITE} $title ${color}${right_pad}${VLINE}${NC}"
    echo -e "${color}${BL}${horizontal}${BR}${NC}"
}

# Function to colorize percentage based on value
colorize_percent() {
    local percent=$1
    if (( percent >= 90 )); then
        echo -e "${RED}${percent}%${NC}"
    elif (( percent >= 70 )); then
        echo -e "${YELLOW}${percent}%${NC}"
    else
        echo -e "${GREEN}${percent}%${NC}"
    fi
}

# Function to create a progress bar
progress_bar() {
    local percent=$1
    local width=30
    local filled=$(( percent * width / 100 ))
    local empty=$(( width - filled ))

    local bar=""
    local color

    if (( percent >= 90 )); then
        color="${RED}"
    elif (( percent >= 70 )); then
        color="${YELLOW}"
    else
        color="${GREEN}"
    fi

    bar+="${color}"
    for ((i=0; i<filled; i++)); do bar+="█"; done
    bar+="${NC}"
    for ((i=0; i<empty; i++)); do bar+="░"; done

    echo -e "$bar"
}

# Print welcome banner
echo ""
echo -e "${CYAN}╭─────────────────────────────────────────────────────╮${NC}"
echo -e "${CYAN}│${NC}  ${WHITE}🖥️  SYSTEM HEALTH CHECK${NC}                            ${CYAN}│${NC}"
echo -e "${CYAN}│${NC}  ${MAGENTA}$(date '+%Y-%m-%d %H:%M:%S')${NC}                           ${CYAN}│${NC}"
echo -e "${CYAN}╰─────────────────────────────────────────────────────╯${NC}"

# =============================================================================
# DISK SPACE CHECK
# =============================================================================
print_header "DISK SPACE" "${BLUE}"

echo ""
echo -e "${WHITE}  Filesystem            Size    Used   Avail  Use%${NC}"
echo -e "  ────────────────────────────────────────────────"

# Get disk usage for main filesystems (excluding snap, tmpfs, etc.)
while read -r filesystem size used avail percent; do
    [[ -z "$filesystem" ]] && continue
    [[ "$filesystem" != /dev/* ]] && continue
    percent=${percent%%%}

    if [ ${#filesystem} -gt 18 ]; then
        filesystem="${filesystem:0:15}..."
    fi

    colored_percent=$(colorize_percent "$percent")
    bar=$(progress_bar "$percent")

    printf "  ${CYAN}%-18s${NC} %6s  %6s  %6s  %s %s\n" "$filesystem" "$size" "$used" "$avail" "$colored_percent" "$bar"
done < <(df -h --output=source,size,used,avail,pcent 2>/dev/null | tail -n +2)

# =============================================================================
# MEMORY USAGE
# =============================================================================
print_header "MEMORY USAGE" "${MAGENTA}"

echo ""

# Get memory info directly from /proc/meminfo
mem_total_kb=0
mem_free_kb=0
mem_available_kb=-1
buffers_kb=0
cached_kb=0
sreclaimable_kb=0
shmem_kb=0
swap_total_kb=0
swap_free_kb=0

while read -r key value _; do
    key=${key%:}
    case "$key" in
        MemTotal) mem_total_kb=$value ;;
        MemFree) mem_free_kb=$value ;;
        MemAvailable) mem_available_kb=$value ;;
        Buffers) buffers_kb=$value ;;
        Cached) cached_kb=$value ;;
        SReclaimable) sreclaimable_kb=$value ;;
        Shmem) shmem_kb=$value ;;
        SwapTotal) swap_total_kb=$value ;;
        SwapFree) swap_free_kb=$value ;;
    esac
done < /proc/meminfo

mem_cache_kb=$((cached_kb + sreclaimable_kb - shmem_kb))
(( mem_cache_kb < 0 )) && mem_cache_kb=0
mem_used_kb=$((mem_total_kb - mem_free_kb - buffers_kb - mem_cache_kb))
(( mem_used_kb < 0 )) && mem_used_kb=0
if (( mem_available_kb < 0 )); then
    mem_available_kb=$((mem_free_kb + mem_cache_kb))
fi

mem_percent=0
if (( mem_total_kb > 0 )); then
    mem_percent=$(( (mem_used_kb * 100 + mem_total_kb / 2) / mem_total_kb ))
fi

swap_used_kb=$((swap_total_kb - swap_free_kb))
(( swap_used_kb < 0 )) && swap_used_kb=0
swap_percent=0
if (( swap_total_kb > 0 )); then
    swap_percent=$(( (swap_used_kb * 100 + swap_total_kb / 2) / swap_total_kb ))
fi

mem_total=$(human_readable_kib "$mem_total_kb")
mem_used=$(human_readable_kib "$mem_used_kb")
mem_available=$(human_readable_kib "$mem_available_kb")

swap_total=$(human_readable_kib "$swap_total_kb")
swap_used=$(human_readable_kib "$swap_used_kb")
swap_free=$(human_readable_kib "$swap_free_kb")

# RAM display
echo -e "  ${WHITE}RAM${NC}"
echo -e "  ───"
printf "  Total:     ${CYAN}%-8s${NC}  Used: ${CYAN}%-8s${NC}  Available: ${CYAN}%-8s${NC}\n" "$mem_total" "$mem_used" "$mem_available"
echo -e "  Usage:     $(colorize_percent "$mem_percent") $(progress_bar "$mem_percent")"

echo ""

# Swap display
echo -e "  ${WHITE}SWAP${NC}"
echo -e "  ────"
printf "  Total:     ${CYAN}%-8s${NC}  Used: ${CYAN}%-8s${NC}  Free:      ${CYAN}%-8s${NC}\n" "$swap_total" "$swap_used" "$swap_free"
echo -e "  Usage:     $(colorize_percent "$swap_percent") $(progress_bar "$swap_percent")"

# =============================================================================
# TOP 5 LARGEST FILES
# =============================================================================
print_header "TOP 5 LARGEST FILES" "${YELLOW}"

echo ""
echo -e "  ${WHITE}Size       File${NC}"
echo -e "  ────────────────────────────────────────────────"

# Find and list 5 largest files in current directory (non-recursive by default)
# Using find to get files in current directory and subdirectories
found_files=$(find . -maxdepth 3 -type f -exec du -h {} + 2>/dev/null | sort -rh | head -5 || true)

if [ -z "$found_files" ]; then
    echo -e "  ${YELLOW}No files found in current directory${NC}"
else
    while IFS=$'\t' read -r size filepath; do
        [[ -z "$size" ]] && continue
        if [ ${#filepath} -gt 40 ]; then
            filepath="...${filepath: -37}"
        fi
        printf "  ${GREEN}%-10s${NC} ${CYAN}%s${NC}\n" "$size" "$filepath"
    done <<< "$found_files"
fi

# =============================================================================
# SUMMARY
# =============================================================================
echo ""
echo -e "${CYAN}╭─────────────────────────────────────────────────────╮${NC}"
echo -e "${CYAN}│${NC}  ${WHITE}Summary${NC}                                            ${CYAN}│${NC}"
echo -e "${CYAN}├─────────────────────────────────────────────────────┤${NC}"

# Determine overall status
status="OK"
status_color="${GREEN}"
status_icon="✓"

if (( mem_percent >= 90 )); then
    status="WARNING - High Memory Usage"
    status_color="${RED}"
    status_icon="⚠"
fi

# Check disk usage on root
root_percent=0
if read -r _ _ _ _ percent_value _ < <(df -P / | tail -n +2); then
    root_percent=${percent_value%%%}
fi
if (( root_percent >= 90 )); then
    status="WARNING - Low Disk Space"
    status_color="${RED}"
    status_icon="⚠"
elif (( root_percent >= 70 )) && [ "$status" = "OK" ]; then
    status="NOTICE - Disk Space Getting Low"
    status_color="${YELLOW}"
    status_icon="!"
fi

echo -e "${CYAN}│${NC}  Status: ${status_color}${status_icon} ${status}${NC}"
printf "${CYAN}│${NC}  %-51s${CYAN}│${NC}\n" ""
echo -e "${CYAN}╰─────────────────────────────────────────────────────╯${NC}"
echo ""
