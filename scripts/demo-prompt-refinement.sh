#!/usr/bin/env bash
# =============================================================================
# Prompt Refinement Demo — CCA-F Step 2
# =============================================================================
# Demonstrates the 3-stage iterative prompt refinement on a single file.
# Each stage produces visibly better precision (fewer false positives,
# more accurate severity). Run this in your walkthrough video.
#
# Usage: ./scripts/demo-prompt-refinement.sh [file]
# Default file: src/auth/login.ts
# =============================================================================

set -euo pipefail

CYAN='\033[0;36m'; BOLD='\033[1m'; GREEN='\033[0;32m'
YELLOW='\033[1;33m'; RESET='\033[0m'

FILE="${1:-src/auth/login.ts}"
sep() { echo -e "${BOLD}──────────────────────────────────────────────────${RESET}"; }

echo -e "${BOLD}Prompt Refinement Demo — 3 Stages${RESET}"
echo -e "File: ${CYAN}$FILE${RESET}"
sep

# ─────────────────────────────────────────────────────────────────────────────
# STAGE 1: Broad / naive prompt
# Problem: flags style nits, inconsistent severity, vague fixes
# ─────────────────────────────────────────────────────────────────────────────
echo -e "${YELLOW}Stage 1: Broad prompt (no criteria)${RESET}"
echo "Prompt: claude -p \"Review this code and tell me what's wrong.\""
sep

claude -p "Review this code and tell me what's wrong. File: $FILE" \
  --add-dir "$(pwd)" 2>/dev/null || true

sep
echo ""

# ─────────────────────────────────────────────────────────────────────────────
# STAGE 2: Explicit criteria added
# Improvement: stops flagging nits, consistent severity labels
# ─────────────────────────────────────────────────────────────────────────────
echo -e "${YELLOW}Stage 2: Explicit criteria (no examples yet)${RESET}"
echo "Prompt: claude -p \"Review this file for real bugs only; ignore cosmetic style.\""
sep

# ── THIS IS THE EXACT PROMPT REQUIRED IN YOUR WALKTHROUGH VIDEO (Prompt 1) ──
claude -p "Review this file for real bugs only; ignore cosmetic style.

Flag: null dereferences, SQL injection, hardcoded secrets, unhandled exceptions,
      broken HTTP status codes, missing auth checks.
Skip: variable naming, comment style, whitespace, import ordering.

File: $FILE" \
  --add-dir "$(pwd)" 2>/dev/null || true

sep
echo ""

# ─────────────────────────────────────────────────────────────────────────────
# STAGE 3: Explicit criteria + few-shot examples
# Improvement: model calibrates on your definition of bug vs nit
# ─────────────────────────────────────────────────────────────────────────────
echo -e "${GREEN}Stage 3: Explicit criteria + few-shot examples (final quality)${RESET}"
sep

claude -p 'Review this file for real bugs only; ignore cosmetic style.

## Criteria
Flag: null dereferences, SQL injection, hardcoded secrets, unhandled exceptions,
      broken HTTP status codes, missing auth checks.
Skip: variable naming, comment style, whitespace, import ordering.

## Few-shot examples

REAL BUG — flag this:
  const secret = process.env.JWT_SECRET || "hardcoded_fallback";
  Issue: Secret falls back to hardcoded value when env var absent.
  Severity: critical
  Fix: throw new Error("JWT_SECRET env var is required")

NIT — skip this:
  const userList = users.map(u => u.email)
  Not a bug: single-letter variable in a short closure, style only.

## Output format (findings only, no prose)
File: <path>
Line: <line>
Severity: critical | warning | info
Issue: <one sentence>
Fix: <concrete change>

If no real issues: output exactly "No issues found."

File to review: '"$FILE" \
  --add-dir "$(pwd)" 2>/dev/null || true

sep
echo -e "${GREEN}Stage comparison complete.${RESET}"
echo "Observe how each stage reduces noise and improves precision."
