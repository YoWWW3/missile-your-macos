#!/bin/bash
#
# backup-projects-execute.sh — Phase 2: Execute Project Backup
#
# Zips all Git projects in a directory (excluding build artifacts),
# verifies each archive, then moves originals to macOS Trash.
#
# Usage:
#   ./backup-projects-execute.sh                # Backs up projects in current directory
#   ./backup-projects-execute.sh /path/to/dir   # Backs up projects in specified directory
#
# Safety:
#   - Originals are moved to macOS Trash (not permanently deleted)
#   - Each ZIP is verified before the original is removed
#   - A log file is created for audit purposes
#

set -euo pipefail

# ─── Configuration ───────────────────────────────────────────────────────────

TARGET_DIR="${1:-$(pwd)}"
TARGET_DIR=$(cd "$TARGET_DIR" 2>/dev/null && pwd) || {
    echo "❌ Error: Directory not found: ${1:-$(pwd)}"
    echo "Usage: $0 [directory]"
    exit 1
}

LOG_FILE="$TARGET_DIR/_backup_execute_log_$(date +%Y%m%d_%H%M%S).txt"

# Exclusion patterns for zip (build artifacts, dependencies)
EXCLUDE_PATTERNS=(
    "node_modules/*"
    ".next/*"
    "dist/*"
    "build/*"
    "vendor/*"
    "__pycache__/*"
    ".gradle/*"
    "target/*"
    "*.pyc"
    ".DS_Store"
    "Thumbs.db"
)

# ─── Colors ──────────────────────────────────────────────────────────────────

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# ─── Helper Functions ────────────────────────────────────────────────────────

log_msg() {
    echo "$1" >> "$LOG_FILE"
}

# ─── Confirmation ────────────────────────────────────────────────────────────

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║       Smart Execute — Project Backup & Archive              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo -e "  ${CYAN}Target:${NC} $TARGET_DIR"
echo ""

cd "$TARGET_DIR"

# Count projects first
project_count=$(find . -name ".git" -type d 2>/dev/null | wc -l | tr -d ' ')

if [ "$project_count" -eq 0 ]; then
    echo "  ⚠ No Git repositories found in this directory."
    exit 0
fi

echo -e "  ${GREEN}Found $project_count Git repositories to back up.${NC}"
echo ""
echo "  This script will:"
echo "    1. Create a ZIP archive for each project"
echo "    2. Verify each ZIP archive is valid"
echo "    3. Move the original project folder to macOS Trash"
echo ""
read -r -p "  Proceed? (y/N): " confirm
echo ""

if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "  Cancelled. No changes were made."
    exit 0
fi

# ─── Build exclude args ─────────────────────────────────────────────────────

build_exclude_args() {
    local project_name="$1"
    local args=()
    for pattern in "${EXCLUDE_PATTERNS[@]}"; do
        args+=(-x "$project_name/$pattern")
    done
    echo "${args[@]}"
}

# ─── Execute ─────────────────────────────────────────────────────────────────

echo "Backup started at $(date)" > "$LOG_FILE"
log_msg "Target directory: $TARGET_DIR"
log_msg "---"

success_count=0
fail_count=0

find . -name ".git" -type d -print0 2>/dev/null | sort -z | while IFS= read -r -d $'\0' git_dir; do

    # Path calculations
    project_dir_rel=$(dirname "$git_dir")
    project_dir_abs=$(cd "$project_dir_rel" && pwd)
    project_name=$(basename "$project_dir_abs")
    parent_dir_abs=$(dirname "$project_dir_abs")

    # Unique timestamp per project
    TS=$(date +%Y%m%d_%H%M%S)
    zip_filename="${project_name// /_}_backup_$TS.zip"

    echo -e "  ${CYAN}📦 Archiving:${NC} $project_name"

    # Navigate to parent for clean relative paths in ZIP
    cd "$parent_dir_abs"

    # Build exclusion arguments
    exclude_args=()
    for pattern in "${EXCLUDE_PATTERNS[@]}"; do
        exclude_args+=(-x "$project_name/$pattern")
    done

    # Create ZIP
    if zip -r -q "$zip_filename" "$project_name" "${exclude_args[@]}" 2>/dev/null; then

        # Verify: check the ZIP is valid and non-empty
        if [ -s "$zip_filename" ] && unzip -t -q "$zip_filename" > /dev/null 2>&1; then

            zip_size=$(du -sh "$zip_filename" | cut -f1)
            echo -e "     ${GREEN}✔ ZIP created:${NC} $zip_filename ($zip_size)"
            log_msg "[OK] $project_name -> $zip_filename ($zip_size)"

            # Move original to Trash (macOS only, safe)
            if command -v osascript &> /dev/null; then
                if osascript -e "tell application \"Finder\" to delete POSIX file \"$project_dir_abs\"" > /dev/null 2>&1; then
                    echo -e "     ${GREEN}✔ Original moved to Trash${NC}"
                    log_msg "     Moved to Trash: $project_dir_abs"
                else
                    echo -e "     ${YELLOW}⚠ Could not move to Trash. Original kept.${NC}"
                    log_msg "     [WARN] Could not move to Trash: $project_dir_abs"
                fi
            else
                echo -e "     ${YELLOW}⚠ Not on macOS — original kept (no Trash support).${NC}"
                log_msg "     [WARN] Not macOS, original kept: $project_dir_abs"
            fi

            success_count=$((success_count + 1))
        else
            echo -e "     ${RED}✖ ZIP verification failed. Original kept.${NC}"
            rm -f "$zip_filename"
            log_msg "[FAIL] ZIP verification failed: $project_name"
            fail_count=$((fail_count + 1))
        fi
    else
        echo -e "     ${RED}✖ ZIP creation failed. Original kept.${NC}"
        log_msg "[FAIL] ZIP creation failed: $project_name"
        fail_count=$((fail_count + 1))
    fi

    # Return to target directory for next iteration
    cd "$TARGET_DIR"

    # Brief pause to ensure unique timestamps
    sleep 1

done

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                   Backup Complete!                          ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "  Log file: $LOG_FILE"
echo ""
echo "  Next steps:"
echo "    1. Verify ZIP files are in the expected locations"
echo "    2. Copy/sync all ZIP files to cloud storage or external drive"
echo "    3. Check macOS Trash to confirm originals are there (safety net)"
echo ""
