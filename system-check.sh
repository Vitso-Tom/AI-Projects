#!/bin/bash

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

# Function to print a header box
print_header() {
    local title="$1"
    local color="$2"
    local width=50
    local padding=$(( (width - ${#title} - 2) / 2 ))

    echo ""
    echo -e "${color}${TL}$(printf '%0.s═' $(seq 1 $width))${TR}${NC}"
    echo -e "${color}${VLINE}$(printf '%*s' $padding '')${WHITE} $title ${color}$(printf '%*s' $((width - padding - ${#title} - 2)) '')${VLINE}${NC}"
    echo -e "${color}${BL}$(printf '%0.s═' $(seq 1 $width))${BR}${NC}"
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
df -h --output=source,size,used,avail,pcent 2>/dev/null | grep -E "^/dev/" | while read -r line; do
    filesystem=$(echo "$line" | awk '{print $1}')
    size=$(echo "$line" | awk '{print $2}')
    used=$(echo "$line" | awk '{print $3}')
    avail=$(echo "$line" | awk '{print $4}')
    percent=$(echo "$line" | awk '{print $5}' | tr -d '%')

    # Truncate long filesystem names
    if [ ${#filesystem} -gt 18 ]; then
        filesystem="${filesystem:0:15}..."
    fi

    colored_percent=$(colorize_percent "$percent")
    bar=$(progress_bar "$percent")

    printf "  ${CYAN}%-18s${NC} %6s  %6s  %6s  %s %s\n" "$filesystem" "$size" "$used" "$avail" "$colored_percent" "$bar"
done

# =============================================================================
# MEMORY USAGE
# =============================================================================
print_header "MEMORY USAGE" "${MAGENTA}"

echo ""

# Get memory info
mem_total=$(free -h | awk '/^Mem:/ {print $2}')
mem_used=$(free -h | awk '/^Mem:/ {print $3}')
mem_free=$(free -h | awk '/^Mem:/ {print $4}')
mem_available=$(free -h | awk '/^Mem:/ {print $7}')
mem_percent=$(free | awk '/^Mem:/ {printf "%.0f", $3/$2 * 100}')

swap_total=$(free -h | awk '/^Swap:/ {print $2}')
swap_used=$(free -h | awk '/^Swap:/ {print $3}')
swap_free=$(free -h | awk '/^Swap:/ {print $4}')
swap_percent=$(free | awk '/^Swap:/ {if ($2 > 0) printf "%.0f", $3/$2 * 100; else print "0"}')

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
found_files=$(find . -maxdepth 3 -type f -exec du -h {} + 2>/dev/null | sort -rh | head -5)

if [ -z "$found_files" ]; then
    echo -e "  ${YELLOW}No files found in current directory${NC}"
else
    echo "$found_files" | while read -r size filepath; do
        # Truncate long paths
        if [ ${#filepath} -gt 40 ]; then
            filepath="...${filepath: -37}"
        fi
        printf "  ${GREEN}%-10s${NC} ${CYAN}%s${NC}\n" "$size" "$filepath"
    done
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
root_percent=$(df / | awk 'NR==2 {print $5}' | tr -d '%')
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
