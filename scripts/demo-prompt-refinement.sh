#!/usr/bin/env bash
# =============================================================================
# Prompt Refinement Demo — CCA-F Step 2
# Demonstrates 3-stage iterative prompt refinement on a single source file.
# Each stage shows improved precision: fewer false positives, better severity.
#
# Usage: ./scripts/demo-prompt-refinement.sh [file]
# Default: src/auth/login.ts
# =============================================================================

set -euo pipefail

BOLD='\033[1m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; RESET='\033[0m'

FILE="${1:-src/auth/login.ts}"
FILE_CONTENT="$(cat "$FILE")"

box() {
    local text="$1"
    local inner="  ${text}  "
    local len=${#inner}
    local top="╔" bot="╚"
    for ((i=0; i<len; i++)); do top+="═"; bot+="═"; done
    top+="╗"; bot+="╝"
    echo -e "${BOLD}${top}${RESET}"
    echo -e "${BOLD}║${inner}║${RESET}"
    echo -e "${BOLD}${bot}${RESET}"
}

echo ""
echo -e "${BOLD}Prompt Refinement Demo — 3 Stages${RESET}"
echo -e "File: ${CYAN}${FILE}${RESET}"
echo ""

# =============================================================================
# STAGE 1 — Vague Prompt (Baseline)
# Problem: flags style nits, inconsistent severity, vague fixes
# =============================================================================
box "STAGE 1 — Vague Prompt (Baseline)"
echo ""

claude -p "Review this code and tell me what's wrong.

File: ${FILE}
\`\`\`typescript
${FILE_CONTENT}
\`\`\`"

echo ""
echo "════ END STAGE 1 ════"
echo ""

# =============================================================================
# STAGE 2 — Scoped Prompt (Real Bugs Only)
# Improvement: stops flagging nits, consistent severity labels
# =============================================================================
box "STAGE 2 — Scoped Prompt (Real Bugs Only)"
echo ""

claude -p "Review this file for real bugs only. Skip: variable naming, comment style, whitespace, import ordering. Flag: null dereferences, SQL injection, hardcoded secrets, unhandled exceptions, broken HTTP status codes.

File: ${FILE}
\`\`\`typescript
${FILE_CONTENT}
\`\`\`"

echo ""
echo "════ END STAGE 2 ════"
echo ""

# =============================================================================
# STAGE 3 — Criteria + Few-Shot Examples (Highest Precision)
# Improvement: model calibrates on REAL BUG vs NIT distinction
# =============================================================================
box "STAGE 3 — Criteria + Few-Shot Examples (Highest Precision)"
echo ""

claude -p "Review this file for real bugs only. Skip: variable naming, comment style, whitespace, import ordering. Flag: null dereferences, SQL injection, hardcoded secrets, unhandled exceptions, broken HTTP status codes.

## Few-shot examples

REAL BUG — flag this:
  const secret = process.env.JWT_SECRET || \"hardcoded_fallback\";
  Issue: Secret falls back to hardcoded value when env var absent.
  Severity: critical
  Fix: throw new Error(\"JWT_SECRET env var is required\")

NIT — skip this:
  const userList = users.map(u => u.email)
  Not a bug: single-letter variable in a short closure, style only.

NIT — skip this:
  const userId = user?.id
  Not a bug: optional chaining style preference, not a real bug.

## Output format (findings only, no prose)
File: <path>
Line: <line>
Severity: critical | warning | info
Issue: <one sentence>
Fix: <concrete change>

If no real issues: output exactly \"No issues found.\"

File to review: ${FILE}
\`\`\`typescript
${FILE_CONTENT}
\`\`\`"

echo ""
echo "════ END STAGE 3 ════"
echo ""

# =============================================================================
# Summary
# =============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STAGE COMPARISON SUMMARY"
echo "Stage 1: Vague prompt → noisy output, includes style nits"
echo "Stage 2: Scoped prompt → only real bugs flagged"
echo "Stage 3: Few-shot examples → highest precision, zero false positives"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
