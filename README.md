# ClaimFlow CI Review Pipeline
### CCA-F: Claude Code for Continuous Integration

A simulated CI pipeline using Claude Code non-interactively to review pull requests — real bugs flagged, cosmetic nits skipped, consistent across large change-sets.

---

## Project Structure

```
claimflow-ci-review/
├── CLAUDE.md                          ← Project review standards (auto-read by Claude Code)
├── .github/workflows/
│   └── claude-review.yml              ← GitHub Actions CI workflow
├── scripts/
│   ├── review.sh                      ← Main CI review script
│   ├── demo-prompt-refinement.sh      ← Step 2: staged prompt demo
│   └── demo-multipass.sh              ← Step 3+6: multi-pass + structured output
├── src/
│   ├── auth/login.ts                  ← JWT auth (intentional bugs)
│   ├── ai/personalize.ts              ← Anthropic API calls (intentional bugs)
│   ├── ai/competitorDiscovery.ts      ← Google Search API (intentional bugs)
│   ├── email/sender.ts                ← SMTP sender (intentional bugs)
│   ├── routes/campaigns.ts            ← Campaign API (intentional bugs)
│   ├── routes/dashboard.ts            ← Dashboard API (intentional bugs)
│   ├── webhooks/stripeWebhook.ts      ← Stripe webhooks (intentional bugs)
│   ├── scraper/memberScraper.ts       ← Website scraper (intentional bugs)
│   ├── tracking/costTracker.ts        ← Token cost tracker (intentional bugs)
│   ├── queue/campaignQueue.ts         ← Bull queue processor (intentional bugs)
│   ├── reporting/reportGenerator.ts   ← Report generator (intentional bugs)
│   ├── models/member.ts               ← Member model (intentional bugs)
│   ├── db/connection.ts               ← DB connection pool (intentional bugs)
│   └── types/index.ts                 ← Type definitions (clean — no bugs)
└── review-output/                     ← Generated reports (gitignored)
```

**Total: 13 buggy files + 1 clean file = 14 files reviewed**

---

## Setup

```bash
# 1. Install Claude Code CLI
npm install -g @anthropic-ai/claude-code

# 2. Authenticate
claude auth login

# 3. Make scripts executable
chmod +x scripts/*.sh

# 4. Create output directory
mkdir -p review-output
```

---

## Walkthrough Video — Required Demo Prompts

Run these **in order** for your video. Show the output of each.

### Demo 1 — Prompt 1: Non-interactive + refined prompt on a single file

```bash
claude -p "Review this file for real bugs only; ignore cosmetic style." src/auth/login.ts
```

**What to show:** Claude prints structured findings and exits — no hanging, no prompts.

---

### Demo 2 — Prompt 2: Per-file pass vs cross-file pass comparison

```bash
./scripts/demo-prompt-refinement.sh src/auth/login.ts
```

This runs 3 stages on the same file so you can show the precision improvement.

Then show the split:

```bash
# Per-file pass (one file)
claude -p "Review this file for LOCAL bugs only. Skip cross-file issues.
File: src/ai/personalize.ts" --add-dir .

# Cross-file pass (all files)
claude -p "Review ALL these files for INTEGRATION issues only.
Files: src/ai/personalize.ts src/email/sender.ts src/queue/campaignQueue.ts" --add-dir .
```

**What to show:** Per-file catches local bugs. Cross-file catches things like both `personalize.ts` and `sender.ts` calling `Promise.all` without rate limiting — which compounds into a worse problem at the integration level.

---

### Demo 3 — Prompt 3: 12+ file PR with split passes + structured output

```bash
./scripts/demo-multipass.sh
```

**What to show:**
- 14 files reviewed in two passes
- Each file gets its own independent Claude instance (no memory carryover)
- Cross-file pass catches integration issues the per-file pass couldn't
- Structured `review-output/structured_findings_*.md` report printed at the end
- CI exit code 1 if criticals found

---

## Concepts Demonstrated

| CCA-F Concept | Where it appears |
|---|---|
| **1.6 Task decomposition** | Per-file pass splits the 14-file PR into atomic units |
| **3.4 Plan mode vs direct execution** | `-p` flag = direct execution, no interactive plan mode |
| **3.5 Iterative refinement** | `demo-prompt-refinement.sh` — 3 visible stages |
| **3.6 Claude Code in CI/CD** | `claude-review.yml` GitHub Actions workflow |
| **4.1 Explicit criteria** | CLAUDE.md + prompt criteria reduce false positives |
| **4.2 Few-shot prompting** | Bug vs nit examples in every review prompt |
| **4.6 Multi-instance/multi-pass** | Per-file: N independent instances; Cross-file: 1 fresh instance |

---

## Key Design Decisions

**Why `-p` instead of interactive mode?**  
CI has no human. `-p` makes Claude print-and-exit. Without it the pipeline hangs waiting for input.

**Why one Claude instance per file?**  
Each `claude -p` invocation is stateless — it has no memory of writing the code. This is the "independent reviewer" effect: it catches assumptions the original author would forgive.

**Why two passes (per-file + cross-file)?**  
Attention dilution: dumping 14 files into one prompt spreads the model thin. Per-file pass = local issues with full attention. Cross-file pass = integration issues with full context.

**Why CLAUDE.md?**  
Every review automatically inherits your team's standards. No need to repeat criteria in every prompt call.
