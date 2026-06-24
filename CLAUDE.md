# ClaimFlow CI Review Standards

## Project Overview
ClaimFlow is an AI-powered email marketing automation platform (Node.js + TypeScript).
These standards govern every automated code review run in CI.

---

## What to FLAG (real issues only)

### Critical — must block merge
- Null/undefined dereferences without guards
- Auth bypass or missing permission checks
- Secrets, API keys, or tokens hardcoded in source
- SQL injection or unsanitised user input passed to queries
- Unhandled promise rejections that can crash the process
- Race conditions in async flows (e.g. double-send, double-charge)
- Missing error handling on external API calls (Anthropic, Vertex AI, SMTP)
- JWT secret falling back to hardcoded string when env var is absent

### Warning — should fix before merge
- Memory leaks (event listeners not removed, streams not closed)
- Incorrect HTTP status codes returned to clients
- Business logic that contradicts the spec comment above the function
- Missing input validation on public-facing endpoints
- Broken API contracts between modules (caller passes wrong shape)

### Info — nice to have, non-blocking
- Missing unit test for a critical path
- Overly broad try/catch swallowing specific errors silently

---

## What to SKIP (do not flag)

- Variable naming style (camelCase vs snake_case preferences)
- Comment formatting or missing JSDoc
- Whitespace, blank lines, trailing commas
- Import ordering
- Prefer `const` over `let` when value never reassigns (nit)
- Single-letter variable names in small closures
- Any issue already covered by ESLint rules in `.eslintrc`

---

## Severity Levels

| Level    | Meaning                          |
|----------|----------------------------------|
| critical | Blocks merge, must fix           |
| warning  | Should fix before merge          |
| info     | Non-blocking suggestion          |

---

## Structured Output Format

Every finding must follow this exact format so it can be posted as a PR comment:

```
File: <relative path>
Line: <line number or range>
Severity: <critical | warning | info>
Issue: <one-sentence description of the actual problem>
Fix: <concrete suggestion — what to change>
```

If no real issues are found, output exactly:
```
No issues found.
```

Do not output summaries, explanations, or praise. Findings only.
