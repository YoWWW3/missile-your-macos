#!/bin/bash
#
# backup-projects-dry-run.sh — Phase 2: Smart Dry Run
#
# Analyzes all Git projects in a directory and shows what will be
# backed up, without making any changes.
#
# Usage:
#   ./backup-projects-dry-run.sh                # Scans current directory
#   ./backup-projects-dry-run.sh /path/to/dir   # Scans specified directory
#

set -euo pipefail

# ─── Configuration ───────────────────────────────────────────────────────────

TARGET_DIR="${1:-$(pwd)}"
TARGET_DIR=$(cd "$TARGET_DIR" 2>/dev/null && pwd) || {
    echo "❌ Error: Directory not found: ${1:-$(pwd)}"
    echo "Usage: $0 [directory]"
    exit 1
}

# ─── Colors ──────────────────────────────────────────────────────────────────

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
DIM='\033[2m'
NC='\033[0m'

# ─── Scan ────────────────────────────────────────────────────────────────────

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║           Smart Dry Run — Project Backup Preview            ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo -e "  ${CYAN}Scanning:${NC} $TARGET_DIR"
echo ""

cd "$TARGET_DIR"

# Find all Git repositories
projects=()
while IFS= read -r -d $'\0' git_dir; do
    projects+=("$git_dir")
done < <(find . -name ".git" -type d -print0 2>/dev/null | sort -z)

total=${#projects[@]}

if [ "$total" -eq 0 ]; then
    echo "  ⚠ No Git repositories found in this directory."
    echo ""
    exit 0
fi

echo -e "  ${GREEN}Found:${NC} $total Git repositories"
echo ""
echo "── Projects ────────────────────────────────────────────────────"
echo ""

total_estimated_size=0
current=0

for git_rel in "${projects[@]}"; do
    current=$((current + 1))

    # Path calculations
    project_dir_rel=$(dirname "$git_rel")
    project_dir_abs=$(cd "$project_dir_rel" && pwd)
    project_name=$(basename "$project_dir_abs")
    parent_dir_abs=$(dirname "$project_dir_abs")

    # Tree-style connector
    branch="├──"
    [ "$current" -eq "$total" ] && branch="└──"

    # ZIP filename preview
    TS=$(date +%Y%m%d_%H%M)
    zip_name="${project_name// /_}_backup_$TS.zip"

    # Estimate size (excluding common large directories)
    # Use find + awk for macOS compatibility (du --exclude is GNU-only)
    size_kb=$(find "$project_dir_abs" \
        -not -path "*/node_modules/*" \
        -not -path "*/.next/*" \
        -not -path "*/dist/*" \
        -not -path "*/build/*" \
        -not -path "*/vendor/*" \
        -not -path "*/__pycache__/*" \
        -not -path "*/.gradle/*" \
        -not -path "*/target/*" \
        -type f -print0 2>/dev/null | xargs -0 stat -f%z 2>/dev/null | awk '{s+=$1} END {printf "%.0f", s/1024}') || \
    size_kb=$(find "$project_dir_abs" \
        -not -path "*/node_modules/*" \
        -not -path "*/.next/*" \
        -not -path "*/dist/*" \
        -not -path "*/build/*" \
        -not -path "*/vendor/*" \
        -not -path "*/__pycache__/*" \
        -not -path "*/.gradle/*" \
        -not -path "*/target/*" \
        -type f -printf '%s\n' 2>/dev/null | awk '{s+=$1} END {printf "%.0f", s/1024}') || \
    size_kb=0

    size_mb=$(echo "scale=1; ${size_kb:-0} / 1024" | bc 2>/dev/null || echo "?")
    total_estimated_size=$((total_estimated_size + ${size_kb:-0}))

    # Git branch info
    git_branch=$(cd "$project_dir_abs" && git branch --show-current 2>/dev/null || echo "unknown")

    # Check for uncommitted changes
    has_changes="clean"
    if cd "$project_dir_abs" && ! git diff --quiet 2>/dev/null; then
        has_changes="${YELLOW}uncommitted changes${NC}"
    fi

    # Check for untracked files
    untracked_count=$(cd "$project_dir_abs" && git ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')
    untracked_info=""
    if [ "$untracked_count" -gt 0 ]; then
        untracked_info=", ${YELLOW}$untracked_count untracked files${NC}"
    fi

    cd "$TARGET_DIR"

    echo -e "$branch 📁 ${GREEN}$project_name${NC}"
    echo -e "    📍 Path       : ${DIM}$project_dir_abs${NC}"
    echo -e "    🌿 Branch     : $git_branch"
    echo -e "    📊 Status     : $has_changes$untracked_info"
    echo -e "    📏 Est. size  : ${size_mb} MB"
    echo -e "    📦 ZIP target : ${DIM}$parent_dir_abs/$zip_name${NC}"
    echo ""
done

total_mb=$(echo "scale=1; $total_estimated_size / 1024" | bc 2>/dev/null || echo "?")

echo "── Summary ─────────────────────────────────────────────────────"
echo ""
echo -e "  ${GREEN}Total projects:${NC}     $total"
echo -e "  ${GREEN}Estimated total:${NC}    ${total_mb} MB (excluding node_modules, build artifacts)"
echo ""
echo -e "  ${CYAN}Next step:${NC} Run the execute script to create backups:"
echo -e "    ./backup-projects-execute.sh $TARGET_DIR"
echo ""
