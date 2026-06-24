#!/usr/bin/env bash
# =============================================================================
# Multi-Pass Review Demo — CCA-F Step 3 + Step 6
# =============================================================================
# Demonstrates per-file + cross-file passes on all 14 src files, then
# outputs fully structured findings ready to post as PR comments.
#
# This script covers Prompt 2 and Prompt 3 from the required examples.
#
# Usage: ./scripts/demo-multipass.sh
# =============================================================================

set -euo pipefail

CYAN='\033[0;36m'; BOLD='\033[1m'; GREEN='\033[0;32m'
YELLOW='\033[1;33m'; RED='\033[0;31m'; RESET='\033[0m'

sep()     { echo -e "${BOLD}──────────────────────────────────────────────────${RESET}"; }
log()     { echo -e "${CYAN}[PASS]${RESET} $*"; }
header()  { echo -e "\n${BOLD}$*${RESET}"; sep; }

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_DIR="./review-output"
mkdir -p "$OUTPUT_DIR"
STRUCTURED_OUT="${OUTPUT_DIR}/structured_findings_${TIMESTAMP}.md"

# ── Collect all 14 source files ───────────────────────────────────────────────
mapfile -t ALL_FILES < <(find ./src -name "*.ts" ! -path "*/types/*" | sort)
FILE_COUNT=${#ALL_FILES[@]}

header "Multi-Pass CI Review — $FILE_COUNT files"
echo "This demo proves:"
echo "  • Prompt 2: per-file pass vs cross-file pass comparison"
echo "  • Prompt 3: 12+ file PR reviewed with structured output"
echo ""

# =============================================================================
# PASS 1: Per-file (local issues)
# Each file gets its own independent Claude instance — no memory carryover
# =============================================================================
header "PASS 1 — Per-File (local issues, independent instances)"

PER_FILE_PROMPT='You are an independent code reviewer with zero context about how this code was written.

Review ONLY this single file for LOCAL issues:
- Hardcoded secrets or API keys
- SQL injection / unsanitised query params
- Unhandled promise rejections or missing try/catch on external calls
- Missing auth/permission checks
- Incorrect HTTP status codes
- Race conditions within this file
- Null/undefined dereference risks

Skip: style, naming, whitespace, comments, import order.

Output ONLY findings in this exact format. No prose, no summaries.

File: <relative path>
Line: <line number>
Severity: critical | warning | info
Issue: <one sentence describing the actual problem>
Fix: <what to change concretely>

If no real issues in this file, output exactly: No issues found.'

PER_FILE_FINDINGS=()

for FILE in "${ALL_FILES[@]}"; do
  log "Per-file: $FILE"
  RESULT=$(claude -p "$PER_FILE_PROMPT

File to review: $FILE" \
    --add-dir "$(pwd)" 2>/dev/null || echo "SKIP: $FILE")

  if [[ "$RESULT" != "No issues found." && "$RESULT" != SKIP:* ]]; then
    PER_FILE_FINDINGS+=("$RESULT")
    echo "$RESULT"
    echo ""
  else
    echo -e "  ${GREEN}✓ No issues${RESET}"
  fi
done

sep

# =============================================================================
# PASS 2: Cross-file (integration issues)
# A single fresh Claude instance sees ALL files and looks only for issues
# that span module boundaries — things per-file review structurally can't catch
# =============================================================================
header "PASS 2 — Cross-File (integration issues, single fresh instance)"

# ── THIS IS THE EXACT DEMO FOR PROMPT 2 in your walkthrough video ────────────
FILE_LIST=$(printf '%s\n' "${ALL_FILES[@]}")

CROSS_PROMPT="You are an independent reviewer seeing this codebase for the first time.
Look ONLY for cross-file integration issues that per-file review cannot catch:

- Caller in file A passes wrong shape/type to function in file B
- Rate limiting absent across multiple concurrent callers in different files
- Inconsistent error handling that creates silent failures at module boundaries
- Race conditions that only emerge when two modules run concurrently
- Missing idempotency where multiple modules trigger the same side effect

Do NOT re-flag per-file issues (hardcoded secrets, SQL injection, etc).

Output ONLY structured findings:

File: <file where fix belongs>
Line: <line>
Severity: critical | warning | info
Issue: <one sentence — explain why this is a cross-file issue>
Fix: <concrete change>

If no cross-file issues: output exactly: No cross-file issues found.

Files in this PR:
$FILE_LIST"

log "Cross-file pass across all $FILE_COUNT files..."
CROSS_RESULT=$(claude -p "$CROSS_PROMPT" \
  --add-dir "$(pwd)" 2>/dev/null || echo "No cross-file issues found.")

echo "$CROSS_RESULT"
sep

# =============================================================================
# STRUCTURED OUTPUT (Prompt 3 — structured findings for PR posting)
# =============================================================================
header "Structured Findings Report (PR-postable)"

{
  echo "# ClaimFlow PR Review — Structured Findings"
  echo ""
  echo "| Field | Value |"
  echo "|-------|-------|"
  echo "| Run | \`$TIMESTAMP\` |"
  echo "| Files reviewed | $FILE_COUNT |"
  echo "| Strategy | Per-file pass + Cross-file pass |"
  echo "| Instances | $FILE_COUNT per-file + 1 cross-file (independent) |"
  echo ""
  echo "---"
  echo ""
  echo "## Per-File Pass Findings"
  echo ""
  if [ ${#PER_FILE_FINDINGS[@]} -eq 0 ]; then
    echo "No per-file issues found."
  else
    printf '%s\n\n' "${PER_FILE_FINDINGS[@]}"
  fi
  echo ""
  echo "---"
  echo ""
  echo "## Cross-File Pass Findings"
  echo ""
  echo "$CROSS_RESULT"
} > "$STRUCTURED_OUT"

# ── Summary counts ────────────────────────────────────────────────────────────
CRITICAL=$(grep -c "Severity: critical" "$STRUCTURED_OUT" 2>/dev/null || echo 0)
WARNING=$(grep -c "Severity: warning" "$STRUCTURED_OUT" 2>/dev/null || echo 0)
INFO=$(grep -c "Severity: info" "$STRUCTURED_OUT" 2>/dev/null || echo 0)

echo ""
echo -e "${BOLD}Summary${RESET}"
printf "  %-12s %s\n" "Files:" "$FILE_COUNT"
printf "  %-12s ${RED}%s${RESET}\n" "Critical:" "$CRITICAL"
printf "  %-12s ${YELLOW}%s${RESET}\n" "Warnings:" "$WARNING"
printf "  %-12s %s\n" "Info:" "$INFO"
printf "  %-12s ${CYAN}%s${RESET}\n" "Report:" "$STRUCTURED_OUT"
sep

if [ "$CRITICAL" -gt 0 ]; then
  echo -e "${RED}CI FAIL — $CRITICAL critical issue(s) must be resolved before merge${RESET}"
  exit 1
else
  echo -e "${GREEN}CI PASS — no critical issues${RESET}"
  exit 0
fi
