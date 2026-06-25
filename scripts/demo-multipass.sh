#!/usr/bin/env bash
# =============================================================================
# Multi-Pass Review Demo — CCA-F Step 3
# Demonstrates per-file review loop (PASS 1) and cross-file integration
# pass (PASS 2). Shows issues that only emerge across module boundaries.
#
# Usage: ./scripts/demo-multipass.sh
# =============================================================================

set -euo pipefail

BOLD='\033[1m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; RESET='\033[0m'

FILES=(
  "src/auth/login.ts"
  "src/routes/campaigns.ts"
)

thin_box() {
    local text="$1"
    local inner=" ${text} "
    local len=${#inner}
    local top="┌" bot="└"
    for ((i=0; i<len; i++)); do top+="─"; bot+="─"; done
    top+="┐"; bot+="┘"
    echo -e "${BOLD}${top}${RESET}"
    echo -e "${BOLD}│${inner}│${RESET}"
    echo -e "${BOLD}${bot}${RESET}"
}

echo ""

# =============================================================================
# PASS 1 — Per-File Review Loop
# Each file gets its own independent claude -p call — no memory carryover
# =============================================================================
thin_box "PASS 1 — Per-File Review Loop"
echo ""

for FILE in "${FILES[@]}"; do
  FILE_CONTENT="$(cat "$FILE")"
  echo -e "${CYAN}[REVIEWING: ${FILE}]${RESET}"
  echo ""

  # -p flag = non-interactive/print mode
  # Removing -p causes claude to hang waiting for user input — pipeline breaks
  claude -p "Review this file for real bugs only. Skip style nits.

Flag: null dereferences, SQL injection, hardcoded secrets, unhandled exceptions, broken HTTP status codes, missing auth checks.
Skip: variable naming, comment style, whitespace, import ordering.

Output ONLY findings in this exact format:
File: <relative path>
Line: <line number>
Severity: critical | warning | info
Issue: <one sentence>
Fix: <concrete change>

If no issues: output exactly: No issues found.

File: ${FILE}
\`\`\`typescript
${FILE_CONTENT}
\`\`\`"

  echo ""
done

# =============================================================================
# PASS 2 — Cross-File Integration Pass
# A single fresh claude -p call sees both files together — catches issues
# that per-file review structurally cannot find
# =============================================================================
thin_box "PASS 2 — Cross-File Integration Pass"
echo ""

FILE1="src/auth/login.ts"
FILE2="src/routes/campaigns.ts"
CONTENT1="$(cat "$FILE1")"
CONTENT2="$(cat "$FILE2")"

# -p flag = non-interactive/print mode
# Removing -p causes claude to hang waiting for user input — pipeline breaks
claude -p "Cross-file review: check for broken contracts, mismatched types, and integration bugs between these files.

Look ONLY for cross-file issues:
- Caller passes wrong shape/type to a function in another file
- Inconsistent error handling creating silent failures at module boundaries
- Missing auth checks that one file assumes another already performed
- Race conditions that only emerge when two modules run concurrently

Do NOT re-flag per-file issues (hardcoded secrets, SQL injection, etc).

Output ONLY findings in this exact format:
File: <file where fix belongs>
Line: <line>
Severity: critical | warning | info
Issue: <one sentence — explain why this is a cross-file issue>
Fix: <concrete change>

If no cross-file issues: output exactly: No cross-file issues found.

--- FILE 1: ${FILE1} ---
\`\`\`typescript
${CONTENT1}
\`\`\`

--- FILE 2: ${FILE2} ---
\`\`\`typescript
${CONTENT2}
\`\`\`"

echo ""

# =============================================================================
# Summary
# =============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "MULTIPASS COMPLETE"
echo "PASS 1 caught per-file bugs (local issues within each file)"
echo "PASS 2 caught cross-file bugs (broken contracts between modules)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
