#!/usr/bin/env bash
# =============================================================================
# The Ultimate Claude Code Setup -- Automation Script
# Version: 1.0.0 | Date: 2026-03-05
#
# Runs 8 progressive, self-updating prompts that configure Claude Code to
# expert-level for any project. Detects your tech stack and adapts everything.
#
# Usage: ./setup-claude-ultimate.sh [OPTIONS]
#
# Options:
#   --prompt N       Run only prompt N (1-8)
#   --from N         Start from prompt N
#   --skip N         Skip prompt N (can be repeated)
#   --verify-only    Only run P8 (verification)
#   --dry-run        Show what would happen without making changes
#   --verbose        Show full Claude output for each step
#   --yes            Non-interactive mode (no confirmation prompts)
#   --fetch-latest   Download latest prompts from GitHub before running
#   --help           Show this help message
# =============================================================================
set -euo pipefail

# === Constants ===
readonly VERSION="1.0.0"
readonly SCRIPT_NAME="setup-claude-ultimate"
readonly LOG_DIR="/tmp/${SCRIPT_NAME}-logs"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CORE_PROMPTS_FILE="${SCRIPT_DIR}/core-setup-prompts.md"
readonly ADVANCED_PROMPTS_FILE="${SCRIPT_DIR}/advanced-setup-prompts.md"
readonly ALLOWED_TOOLS="Read,Write,Edit,Bash,Glob,Grep,WebFetch,WebSearch"

# Prompt names (indexed 1-8)
readonly PROMPT_NAMES=(
    ""  # index 0 unused
    "Discovery and Analysis"
    "Foundation -- Settings, Permissions, CLAUDE.md"
    "Hooks and Quality Gates"
    "Beads Integration"
    "Agent Teams Configuration"
    "MCP Servers and External Tools"
    "System and Performance Optimization"
    "Verification and Testing"
)

# === Colors ===
if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    DIM='\033[2m'
    RESET='\033[0m'
else
    RED='' GREEN='' YELLOW='' BLUE='' CYAN='' BOLD='' DIM='' RESET=''
fi

# === State ===
DRY_RUN=false
VERBOSE=false
AUTO_YES=false
FETCH_LATEST=false
VERIFY_ONLY=false
SINGLE_PROMPT=0
START_FROM=1
declare -a SKIP_PROMPTS=()
TOTAL_PROMPTS=8
PASSED=0
FAILED=0
SKIPPED=0

# === Logging ===

log() {
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    echo "[${timestamp}] $*" >> "${LOG_DIR}/setup.log"
}

info() {
    echo -e "${BLUE}[INFO]${RESET} $*"
    log "INFO: $*"
}

success() {
    echo -e "${GREEN}[PASS]${RESET} $*"
    log "PASS: $*"
}

warn() {
    echo -e "${YELLOW}[WARN]${RESET} $*"
    log "WARN: $*"
}

error() {
    echo -e "${RED}[FAIL]${RESET} $*" >&2
    log "FAIL: $*"
}

step_header() {
    local num=$1
    local name=$2
    local total=$3
    echo ""
    echo -e "${BOLD}${CYAN}=====================================================${RESET}"
    echo -e "${BOLD}  Step ${num}/${total}: ${name}${RESET}"
    echo -e "${BOLD}${CYAN}=====================================================${RESET}"
    echo ""
}

# === Progress ===

show_progress() {
    local current=$1
    local total=$2
    local label=$3
    local pct=$((current * 100 / total))
    local filled=$((pct / 5))
    local empty=$((20 - filled))
    local bar=""

    for ((i = 0; i < filled; i++)); do bar+="#"; done
    for ((i = 0; i < empty; i++)); do bar+="."; done

    printf "\r  ${DIM}[%s] %d%% %s${RESET}" "$bar" "$pct" "$label"
}

# === OS Detection ===

detect_os() {
    case "$(uname -s)" in
        Darwin*)  OS="macos" ;;
        Linux*)
            if grep -qi microsoft /proc/version 2>/dev/null; then
                OS="wsl"
            else
                OS="linux"
            fi
            ;;
        *)        OS="unknown" ;;
    esac
    log "Detected OS: ${OS}"
}

# === Prerequisites ===

check_prereqs() {
    info "Checking prerequisites..."
    local missing=()
    local warnings=()

    # Required: git
    if ! command -v git &>/dev/null; then
        missing+=("git")
    fi

    # Required: claude CLI
    if ! command -v claude &>/dev/null; then
        missing+=("claude (install: npm install -g @anthropic-ai/claude-code)")
    fi

    # Required: bun or node (at least one)
    if ! command -v bun &>/dev/null && ! command -v node &>/dev/null; then
        missing+=("bun or node (install: https://bun.sh or https://nodejs.org)")
    fi

    # Recommended: jq
    if ! command -v jq &>/dev/null; then
        warnings+=("jq not found -- some hook features will be limited (install: brew install jq / apt install jq)")
    fi

    # Recommended: curl
    if ! command -v curl &>/dev/null; then
        warnings+=("curl not found -- self-update feature will be limited")
    fi

    # Show warnings
    for w in "${warnings[@]+"${warnings[@]}"}"; do
        warn "$w"
    done

    # Fail on missing required tools
    if [[ ${#missing[@]} -gt 0 ]]; then
        error "Missing required tools:"
        for m in "${missing[@]}"; do
            echo -e "  ${RED}-${RESET} $m"
        done
        echo ""
        echo "Install the missing tools and try again."
        exit 1
    fi

    # Check we are in a git repo
    if ! git rev-parse --is-inside-work-tree &>/dev/null; then
        warn "Not inside a git repository. Some features may not work correctly."
        if [[ "$AUTO_YES" != true ]]; then
            read -r -p "Continue anyway? [y/N] " response
            if [[ ! "$response" =~ ^[Yy]$ ]]; then
                exit 1
            fi
        fi
    fi

    success "All prerequisites satisfied"
    info "OS: ${OS} | Claude: $(claude --version 2>/dev/null || echo 'unknown') | Git: $(git --version 2>/dev/null | head -1)"
}

# === Idempotency Checks ===

is_prompt_complete() {
    local num=$1
    case $num in
        1) [[ -f /tmp/claude-setup-discovery.json ]] ;;
        2) [[ -f "${HOME}/.claude/settings.json" ]] && [[ -f ".claude/settings.json" ]] && [[ -f "CLAUDE.md" ]] ;;
        3) [[ -d ".claude/hooks" ]] && [[ -f ".claude/hooks/block-dangerous.sh" ]] ;;
        4) command -v bd &>/dev/null && [[ -d ".beads" ]] ;;
        5) grep -q "AGENT_TEAMS\|agent.teams\|agent-teams" "${HOME}/.claude/settings.json" 2>/dev/null || \
           grep -q "AGENT_TEAMS\|agent.teams\|agent-teams" ".claude/settings.json" 2>/dev/null ;;
        6) claude mcp list 2>/dev/null | grep -qi "context7" 2>/dev/null ;;
        7) [[ -f ".claudeignore" ]] ;;
        8) return 1 ;; # Verification always runs
        *) return 1 ;;
    esac
}

should_skip() {
    local num=$1
    for skip in "${SKIP_PROMPTS[@]+"${SKIP_PROMPTS[@]}"}"; do
        if [[ "$skip" == "$num" ]]; then
            return 0
        fi
    done
    return 1
}

# === Prompt Extraction ===

# Extract a single prompt from the markdown files by its number.
# Prompts are structured as:
#   ## PROMPT N: Title
#   ```
#   [prompt content with inner ```bash / ```json blocks]
#   ```
# We extract the content inside the outer code fence, handling nested
# inner code blocks that use language specifiers (```bash, ```json, etc.)
extract_prompt() {
    local num=$1
    local file

    if [[ $num -le 5 ]]; then
        file="$CORE_PROMPTS_FILE"
    else
        file="$ADVANCED_PROMPTS_FILE"
    fi

    if [[ ! -f "$file" ]]; then
        error "Prompt file not found: ${file}"
        return 1
    fi

    # Use awk to extract the outer code block content after the PROMPT N header.
    # The outer fence opens with bare ```. Inner blocks open with ```lang and
    # close with bare ```. We track inner block state so we only stop at the
    # outer closing ```.
    local content
    content=$(awk -v num="$num" '
        BEGIN { found_header=0; in_outer=0; in_inner=0; }
        /^## PROMPT/ {
            if (found_header && in_outer) { exit }
            if ($0 ~ "^## PROMPT " num ":") { found_header=1; next }
            else if (found_header) { exit }
        }
        found_header == 0 { next }
        # Bare ``` (exactly three backticks, nothing else)
        /^```$/ {
            if (in_outer == 0) {
                in_outer=1
                next
            } else if (in_inner) {
                # Closing an inner block -- print it as part of prompt
                in_inner=0
                print
                next
            } else {
                # Closing the outer block -- done
                exit
            }
        }
        # ```lang (code fence with language specifier) -- inner block opening
        /^```[a-zA-Z]/ {
            if (in_outer) {
                in_inner=1
                print
                next
            }
        }
        in_outer { print }
    ' "$file")

    if [[ -z "$content" ]]; then
        error "Could not extract Prompt ${num} from ${file}"
        error "Expected format: ## PROMPT ${num}: Title followed by a code fence"
        return 1
    fi

    echo "$content"
}

# === Prompt Execution ===

run_prompt() {
    local num=$1
    local name="${PROMPT_NAMES[$num]}"
    local log_file="${LOG_DIR}/prompt-${num}.log"

    step_header "$num" "$name" "$TOTAL_PROMPTS"

    # Idempotency check
    if is_prompt_complete "$num" 2>/dev/null; then
        warn "Prompt ${num} appears to be already configured."
        if [[ "$AUTO_YES" != true ]]; then
            read -r -p "  Run anyway? [y/N] " response
            if [[ ! "$response" =~ ^[Yy]$ ]]; then
                success "Skipped Prompt ${num} (already configured)"
                ((SKIPPED++))
                return 0
            fi
        else
            info "Already configured, skipping (--yes mode)"
            ((SKIPPED++))
            return 0
        fi
    fi

    # Extract the prompt
    local prompt_content
    if ! prompt_content=$(extract_prompt "$num"); then
        error "Failed to extract Prompt ${num}"
        handle_error "$num"
        return $?
    fi

    # Dry run mode
    if [[ "$DRY_RUN" == true ]]; then
        info "[DRY RUN] Would run Prompt ${num}: ${name}"
        info "[DRY RUN] Prompt length: $(echo "$prompt_content" | wc -c | tr -d ' ') characters"
        info "[DRY RUN] Log would be saved to: ${log_file}"
        ((SKIPPED++))
        return 0
    fi

    # Execute via claude CLI
    info "Running Prompt ${num}..."
    log "Executing Prompt ${num}: ${name}"

    local exit_code=0
    if [[ "$VERBOSE" == true ]]; then
        # Show full output in terminal AND save to log
        claude -p "$prompt_content" \
            --allowedTools "$ALLOWED_TOOLS" \
            2>&1 | tee "$log_file" || exit_code=$?
    else
        # Show progress indicator, save output to log only
        show_progress "$num" "$TOTAL_PROMPTS" "Running ${name}..."
        claude -p "$prompt_content" \
            --allowedTools "$ALLOWED_TOOLS" \
            > "$log_file" 2>&1 || exit_code=$?
        echo "" # newline after progress bar
    fi

    if [[ $exit_code -ne 0 ]]; then
        error "Prompt ${num} exited with code ${exit_code}"
        handle_error "$num"
        return $?
    fi

    success "Prompt ${num} completed: ${name}"
    ((PASSED++))
    return 0
}

# === Error Handling ===

handle_error() {
    local num=$1
    local log_file="${LOG_DIR}/prompt-${num}.log"

    echo ""
    error "Prompt ${num} failed. Log: ${log_file}"

    if [[ "$AUTO_YES" == true ]]; then
        warn "Auto-skipping failed prompt (--yes mode)"
        ((FAILED++))
        return 0
    fi

    echo ""
    echo "  Options:"
    echo "    1) Retry this prompt"
    echo "    2) Skip and continue"
    echo "    3) Abort setup"
    echo ""
    read -r -p "  Choice [1-3]: " choice

    case "${choice}" in
        1)
            info "Retrying Prompt ${num}..."
            run_prompt "$num"
            ;;
        2)
            warn "Skipping Prompt ${num}"
            ((FAILED++))
            return 0
            ;;
        3)
            error "Setup aborted by user at Prompt ${num}"
            generate_report
            exit 1
            ;;
        *)
            warn "Invalid choice. Skipping Prompt ${num}"
            ((FAILED++))
            return 0
            ;;
    esac
}

# === Banner ===

show_banner() {
    echo -e "${BOLD}${CYAN}"
    echo "  _____ _                 _   _   _ _ _   _                 _        "
    echo " |_   _| |__   ___      | | | | | | | |_(_)_ __ ___   __ _| |_ ___  "
    echo "   | | | '_ \\ / _ \\     | | | | | | | __| | '_ \` _ \\ / _\` | __/ _ \\ "
    echo "   | | | | | |  __/     | |_| | | | | |_| | | | | | | (_| | ||  __/ "
    echo "   |_| |_| |_|\\___|      \\___/|_|_|_|\\__|_|_| |_| |_|\\__,_|\\__\\___| "
    echo "                                                                      "
    echo "    ____ _                 _         ____          _                   "
    echo "   / ___| | __ _ _   _  __| | ___   / ___|___   __| | ___             "
    echo "  | |   | |/ _\` | | | |/ _\` |/ _ \\ | |   / _ \\ / _\` |/ _ \\            "
    echo "  | |___| | (_| | |_| | (_| |  __/ | |__| (_) | (_| |  __/            "
    echo "   \\____|_|\\__,_|\\__,_|\\__,_|\\___|  \\____\\___/ \\__,_|\\___|            "
    echo "                                                                      "
    echo -e "   ${DIM}Setup v${VERSION}${RESET}"
    echo ""
    echo -e "${RESET}  ${DIM}8 progressive prompts. Any stack. Expert-level config.${RESET}"
    echo ""
}

# === Report ===

generate_report() {
    local report_file="${LOG_DIR}/setup-report.md"
    local total=$((PASSED + FAILED + SKIPPED))
    local score_pct=0
    if [[ $total -gt 0 ]]; then
        score_pct=$((PASSED * 100 / total))
    fi

    local quality="UNKNOWN"
    if [[ $score_pct -ge 90 ]]; then quality="EXCELLENT"
    elif [[ $score_pct -ge 70 ]]; then quality="GOOD"
    elif [[ $score_pct -ge 50 ]]; then quality="FAIR"
    else quality="NEEDS ATTENTION"
    fi

    # Print to terminal
    echo ""
    echo -e "${BOLD}${CYAN}=====================================================${RESET}"
    echo -e "${BOLD}  Setup Report${RESET}"
    echo -e "${BOLD}${CYAN}=====================================================${RESET}"
    echo ""
    echo -e "  Passed:  ${GREEN}${PASSED}${RESET}"
    echo -e "  Failed:  ${RED}${FAILED}${RESET}"
    echo -e "  Skipped: ${YELLOW}${SKIPPED}${RESET}"
    echo -e "  Total:   ${total}"
    echo ""
    echo -e "  Score:   ${BOLD}${PASSED}/${total} (${score_pct}%)${RESET}"
    echo -e "  Quality: ${BOLD}${quality}${RESET}"
    echo ""
    echo -e "  Logs: ${DIM}${LOG_DIR}/${RESET}"
    echo ""

    # Save to file
    cat > "$report_file" << EOF
# Claude Code Setup Report

**Date:** $(date '+%Y-%m-%d %H:%M:%S')
**Version:** ${VERSION}
**OS:** ${OS}
**Project:** $(basename "$(pwd)")
**Path:** $(pwd)

## Results

| Metric | Value |
|--------|-------|
| Passed | ${PASSED} |
| Failed | ${FAILED} |
| Skipped | ${SKIPPED} |
| Total | ${total} |
| Score | ${PASSED}/${total} (${score_pct}%) |
| Quality | ${quality} |

## Steps

EOF

    for i in $(seq 1 8); do
        local status="N/A"
        if [[ -f "${LOG_DIR}/prompt-${i}.log" ]]; then
            status="RAN"
        elif should_skip "$i" 2>/dev/null; then
            status="SKIPPED (user)"
        fi
        echo "- **P${i}: ${PROMPT_NAMES[$i]}** -- ${status}" >> "$report_file"
    done

    cat >> "$report_file" << EOF

## Log Files

$(ls -1 "${LOG_DIR}/" 2>/dev/null | sed 's/^/- /')

## Next Steps

- Run \`./setup-claude-ultimate.sh --verify-only\` to validate the setup
- Review CLAUDE.md and customize for your project
- Check .claude/settings.json permissions and adjust as needed
- Start Claude Code and test the hooks: \`claude\`
EOF

    info "Report saved to: ${report_file}"
}

# === Help ===

show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Configure Claude Code to expert-level with 8 progressive prompts."
    echo ""
    echo "Options:"
    echo "  --prompt N       Run only prompt N (1-8)"
    echo "  --from N         Start from prompt N"
    echo "  --skip N         Skip prompt N (repeatable)"
    echo "  --verify-only    Only run P8 (verification)"
    echo "  --dry-run        Preview what would happen"
    echo "  --verbose        Show full Claude output"
    echo "  --yes            Non-interactive mode"
    echo "  --fetch-latest   Download latest prompts before running"
    echo "  --help           Show this help message"
    echo ""
    echo "Prompts:"
    for i in $(seq 1 8); do
        echo "  P${i}: ${PROMPT_NAMES[$i]}"
    done
    echo ""
    echo "Examples:"
    echo "  $0                          # Run all 8 prompts"
    echo "  $0 --from 3                 # Start from prompt 3"
    echo "  $0 --skip 4 --skip 7        # Skip beads and optimization"
    echo "  $0 --verify-only            # Only run verification"
    echo "  $0 --dry-run                # Preview without changes"
    echo "  $0 --prompt 2 --verbose     # Run only P2, show output"
    echo ""
    echo "Prompt files:"
    echo "  Core (P1-P5):     ${CORE_PROMPTS_FILE}"
    echo "  Advanced (P6-P8): ${ADVANCED_PROMPTS_FILE}"
    echo ""
    echo "Logs saved to: ${LOG_DIR}/"
}

# === Fetch Latest ===

fetch_latest_prompts() {
    info "Fetching latest prompts from GitHub..."

    local base_url="https://raw.githubusercontent.com/YOUR_ORG/claude-setup-ultimate/main/prompts"
    local core_url="${base_url}/core-setup-prompts.md"
    local advanced_url="${base_url}/advanced-setup-prompts.md"

    if curl -fsSL "$core_url" -o "${CORE_PROMPTS_FILE}.latest" 2>/dev/null; then
        mv "${CORE_PROMPTS_FILE}.latest" "$CORE_PROMPTS_FILE"
        success "Updated core prompts"
    else
        warn "Could not fetch latest core prompts. Using local copy."
    fi

    if curl -fsSL "$advanced_url" -o "${ADVANCED_PROMPTS_FILE}.latest" 2>/dev/null; then
        mv "${ADVANCED_PROMPTS_FILE}.latest" "$ADVANCED_PROMPTS_FILE"
        success "Updated advanced prompts"
    else
        warn "Could not fetch latest advanced prompts. Using local copy."
    fi
}

# === Argument Parsing ===

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --prompt)
                SINGLE_PROMPT="$2"
                if [[ "$SINGLE_PROMPT" -lt 1 || "$SINGLE_PROMPT" -gt 8 ]]; then
                    error "Prompt number must be between 1 and 8"
                    exit 1
                fi
                shift 2
                ;;
            --from)
                START_FROM="$2"
                if [[ "$START_FROM" -lt 1 || "$START_FROM" -gt 8 ]]; then
                    error "Start prompt must be between 1 and 8"
                    exit 1
                fi
                shift 2
                ;;
            --skip)
                SKIP_PROMPTS+=("$2")
                shift 2
                ;;
            --verify-only)
                VERIFY_ONLY=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            --yes)
                AUTO_YES=true
                shift
                ;;
            --fetch-latest)
                FETCH_LATEST=true
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                echo "Run '$0 --help' for usage."
                exit 1
                ;;
        esac
    done
}

# === Prompt File Validation ===

validate_prompt_files() {
    local missing=false

    if [[ ! -f "$CORE_PROMPTS_FILE" ]]; then
        error "Core prompts file not found: ${CORE_PROMPTS_FILE}"
        missing=true
    fi

    if [[ ! -f "$ADVANCED_PROMPTS_FILE" ]]; then
        error "Advanced prompts file not found: ${ADVANCED_PROMPTS_FILE}"
        missing=true
    fi

    if [[ "$missing" == true ]]; then
        echo ""
        echo "Expected prompt files in the same directory as this script:"
        echo "  - core-setup-prompts.md     (Prompts 1-5)"
        echo "  - advanced-setup-prompts.md (Prompts 6-8)"
        echo ""
        echo "Try: $0 --fetch-latest  (to download them)"
        exit 1
    fi

    success "Prompt files found"
}

# === Confirmation ===

confirm_execution() {
    if [[ "$DRY_RUN" == true ]]; then
        info "DRY RUN MODE -- no changes will be made"
        echo ""
        return
    fi

    if [[ "$AUTO_YES" == true ]]; then
        return
    fi

    echo -e "  ${BOLD}Project:${RESET}  $(basename "$(pwd)")"
    echo -e "  ${BOLD}Path:${RESET}     $(pwd)"
    echo -e "  ${BOLD}OS:${RESET}       ${OS}"

    if [[ "$SINGLE_PROMPT" -gt 0 ]]; then
        echo -e "  ${BOLD}Running:${RESET}  Prompt ${SINGLE_PROMPT} only"
    elif [[ "$VERIFY_ONLY" == true ]]; then
        echo -e "  ${BOLD}Running:${RESET}  Verification only (P8)"
    else
        echo -e "  ${BOLD}Running:${RESET}  Prompts ${START_FROM}-8"
        if [[ ${#SKIP_PROMPTS[@]} -gt 0 ]]; then
            echo -e "  ${BOLD}Skipping:${RESET} ${SKIP_PROMPTS[*]}"
        fi
    fi

    echo ""
    read -r -p "  Continue? [Y/n] " response
    if [[ "$response" =~ ^[Nn]$ ]]; then
        info "Setup cancelled."
        exit 0
    fi
    echo ""
}

# === Main ===

main() {
    parse_args "$@"

    show_banner

    # Create log directory
    mkdir -p "$LOG_DIR"
    log "=== Setup started at $(date) ==="
    log "Version: ${VERSION}"
    log "Arguments: $*"
    log "Working directory: $(pwd)"

    # Detect OS
    detect_os

    # Check prerequisites
    check_prereqs

    # Fetch latest prompts if requested
    if [[ "$FETCH_LATEST" == true ]]; then
        fetch_latest_prompts
    fi

    # Validate prompt files exist
    validate_prompt_files

    # Confirm with user
    confirm_execution

    # Determine which prompts to run
    local start=1
    local end=8

    if [[ "$SINGLE_PROMPT" -gt 0 ]]; then
        start=$SINGLE_PROMPT
        end=$SINGLE_PROMPT
    elif [[ "$VERIFY_ONLY" == true ]]; then
        start=8
        end=8
    else
        start=$START_FROM
    fi

    # Run prompts
    for i in $(seq "$start" "$end"); do
        # Check if user wants to skip this prompt
        if should_skip "$i"; then
            info "Skipping Prompt ${i}: ${PROMPT_NAMES[$i]} (--skip)"
            ((SKIPPED++))
            continue
        fi

        run_prompt "$i"
    done

    # Generate report
    generate_report

    # Final message
    echo -e "${GREEN}${BOLD}  Setup complete!${RESET}"
    echo ""
    echo "  Next steps:"
    echo "    1. Review CLAUDE.md and customize for your project"
    echo "    2. Check .claude/settings.json permissions"
    echo "    3. Start Claude Code: claude"
    echo ""

    log "=== Setup finished at $(date) ==="

    # Exit with error if any prompts failed
    if [[ $FAILED -gt 0 ]]; then
        exit 1
    fi
}

main "$@"
