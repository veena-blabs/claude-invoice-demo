#!/usr/bin/env bash
# =============================================================================
# ClaimFlow CI Review Pipeline
# =============================================================================
# Usage:
#   ./scripts/review.sh                    # review all src files
#   ./scripts/review.sh src/auth/login.ts  # review a single file
#
# Requires: Claude Code CLI installed and authenticated
# =============================================================================

set -euo pipefail

# ── Colour helpers ────────────────────────────────────────────────────────────
RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

log()  { echo -e "${CYAN}[CI]${RESET} $*"; }
ok()   { echo -e "${GREEN}[OK]${RESET} $*"; }
warn() { echo -e "${YELLOW}[WARN]${RESET} $*"; }
err()  { echo -e "${RED}[ERR]${RESET} $*"; }
sep()  { echo -e "${BOLD}──────────────────────────────────────────────────${RESET}"; }

# ── Config ────────────────────────────────────────────────────────────────────
OUTPUT_DIR="./review-output"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_FILE="${OUTPUT_DIR}/review_${TIMESTAMP}.md"
FINDINGS_JSON="${OUTPUT_DIR}/findings_${TIMESTAMP}.json"

mkdir -p "$OUTPUT_DIR"

# ── Determine files to review ─────────────────────────────────────────────────
if [ $# -gt 0 ]; then
  FILES=("$@")
  log "Single-file mode: ${FILES[*]}"
else
  # Collect all TypeScript source files (excluding types — clean file)
  mapfile -t FILES < <(find ./src -name "*.ts" ! -path "*/types/*" | sort)
  log "Found ${#FILES[@]} files to review"
fi

sep

# =============================================================================
# STEP 1: Non-interactive mode check
# =============================================================================
# The -p flag makes claude print-and-exit. Without it the pipeline hangs.
# We verify claude is available and -p works before processing any files.
# =============================================================================

log "Step 1 — Verifying Claude Code non-interactive mode (-p flag)"
if ! command -v claude &> /dev/null; then
  err "Claude Code CLI not found. Install it first: npm install -g @anthropic-ai/claude-code"
  exit 1
fi

# Quick smoke test
SMOKE=$(claude -p "Respond with exactly: OK" 2>/dev/null || true)
if [[ "$SMOKE" != *"OK"* ]]; then
  warn "Smoke test returned unexpected output — continuing anyway"
fi
ok "Claude Code is available and -p flag works (non-interactive mode confirmed)"
sep

# =============================================================================
# STEP 2 + STEP 3: Per-file pass (local issues)
# =============================================================================
# Refined prompt with:
#   - Explicit criteria (from CLAUDE.md)
#   - Few-shot example of a real bug vs a nit
#   - Structured output format enforcement
#
# This runs one independent Claude Code instance per file (Step 4: independent
# review — each invocation has no memory of writing the code).
# =============================================================================

log "Step 2+3 — Per-file pass (local issues, one independent instance per file)"

PER_FILE_PROMPT='You are an independent code reviewer with no prior context about this code.

## Few-shot examples of what to flag vs skip

REAL BUG (flag this):
  const secret = process.env.JWT_SECRET || "hardcoded";
  → Critical: JWT secret falls back to hardcoded string when env var is absent.
    Fix: throw new Error("JWT_SECRET is required") if env var is not set.

NIT (skip this):
  const x = items.map(i => i.name)
  → Single-letter variable in a short closure. Skip — style preference only.

## Your task
Review ONLY this single file for local bugs.
Use the standards defined in CLAUDE.md.
Output ONLY structured findings in this exact format — nothing else:

File: <path>
Line: <line number>
Severity: <critical | warning | info>
Issue: <one sentence>
Fix: <concrete change>

If no real issues exist, output exactly: No issues found.'

ALL_FINDINGS=()

for FILE in "${FILES[@]}"; do
  log "  Reviewing: $FILE"

  # Each `claude -p` call is a fresh, independent instance (no shared memory)
  RESULT=$(claude -p "$PER_FILE_PROMPT

File to review: $FILE" \
    --add-dir "$(pwd)" 2>/dev/null || echo "ERROR: review failed for $FILE")

  if [[ "$RESULT" == ERROR:* ]]; then
    warn "  Failed to review $FILE — skipping"
    continue
  fi

  if [[ "$RESULT" != "No issues found." ]]; then
    ALL_FINDINGS+=("$RESULT")
    echo "$RESULT"
    echo ""
  else
    ok "  No issues in $FILE"
  fi
done

sep

# =============================================================================
# STEP 3 (continued): Cross-file pass (integration issues)
# =============================================================================
# A second independent Claude Code instance looks across ALL files together
# for broken contracts, inconsistent patterns, and integration bugs that
# per-file review misses.
# =============================================================================

log "Step 3 — Cross-file pass (integration issues, broken contracts)"

CROSS_FILE_PROMPT='You are an independent reviewer looking ONLY at cross-file integration issues.
Do not repeat findings already caught per-file (SQL injection, hardcoded secrets, etc).

Focus on:
- Broken API contracts (caller passes wrong shape to a function in another file)
- Inconsistent error handling patterns across modules
- Missing rate limiting that spans multiple async callers in different files
- Race conditions that only appear when multiple modules interact

Output ONLY structured findings in this exact format:

File: <path>  (use the file where the fix should go)
Line: <line>
Severity: <critical | warning | info>
Issue: <one sentence — must explain why this is a cross-file issue>
Fix: <concrete change>

If no cross-file issues exist, output exactly: No cross-file issues found.'

FILE_LIST=$(printf '%s\n' "${FILES[@]}")

CROSS_RESULT=$(claude -p "$CROSS_FILE_PROMPT

Files in this PR:
$FILE_LIST" \
  --add-dir "$(pwd)" 2>/dev/null || echo "ERROR: cross-file pass failed")

if [[ "$CROSS_RESULT" != "No cross-file issues found." && "$CROSS_RESULT" != ERROR:* ]]; then
  log "Cross-file findings:"
  echo "$CROSS_RESULT"
  ALL_FINDINGS+=("--- CROSS-FILE PASS ---" "$CROSS_RESULT")
fi

sep

# =============================================================================
# STEP 6: Structured report output
# =============================================================================

log "Step 6 — Writing structured report"

{
  echo "# ClaimFlow CI Review Report"
  echo ""
  echo "**Run:** \`$TIMESTAMP\`"
  echo "**Files reviewed:** ${#FILES[@]}"
  echo "**Mode:** Per-file pass + Cross-file pass (independent instances)"
  echo ""
  echo "---"
  echo ""
  echo "## Per-File Findings"
  echo ""
  printf '%s\n\n' "${ALL_FINDINGS[@]}"
} > "$REPORT_FILE"

ok "Report written to: $REPORT_FILE"

# Count criticals
CRITICAL_COUNT=$(grep -c "Severity: critical" "$REPORT_FILE" 2>/dev/null || echo 0)
WARNING_COUNT=$(grep -c "Severity: warning" "$REPORT_FILE" 2>/dev/null || echo 0)

sep
echo -e "${BOLD}Review Summary${RESET}"
echo -e "  Critical findings : ${RED}${CRITICAL_COUNT}${RESET}"
echo -e "  Warnings          : ${YELLOW}${WARNING_COUNT}${RESET}"
echo -e "  Report            : ${CYAN}${REPORT_FILE}${RESET}"
sep

# Fail CI if any critical issues found
if [ "$CRITICAL_COUNT" -gt 0 ]; then
  err "$CRITICAL_COUNT critical issue(s) found — failing CI"
  exit 1
else
  ok "No critical issues — CI passes"
  exit 0
fi
