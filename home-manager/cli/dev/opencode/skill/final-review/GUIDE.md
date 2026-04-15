# Final Review Cycle - Complete Guide

Execute **2 baseline review cycles**, then confirm completion with the user. Additional cycles may follow if the user requests more changes.

## Review Scope

**"Current session"** = all work since the user's initial request (or since the last "Needs more changes" response in a continuation loop). Enumerate changed files via `git diff`/`git status`, tool output history, or explicit file tracking maintained during the session.

Each review cycle covers **only**:

- Changes made in the current session (new files, modified files, deleted files).
- Immediate interfaces affected by those changes — e.g., direct importers/callers, public types/functions, CLI flags/config schema, adjacent tests/docs that reference changed behavior.

Each review cycle does **not** cover:

- Unrelated code or pre-existing issues outside the session's scope.
- Broad style debates or large-scale refactoring suggestions.

## Review Cycle Procedure

Repeat the following cycle **twice** (Cycle 1, then Cycle 2).

### Step 1 — Agent Review

Assess the **scale and complexity** of changes in the session, then decide how many oracle agents to fire and how to split their review focus. More files, more cross-cutting concerns, or higher risk warrants more oracles with narrower focus areas. A single small change may need only one oracle; a large multi-module refactor may warrant many oracles each covering a distinct concern (correctness, architecture, security, performance, etc.).

Prompt each oracle with:

- Summary of all changes made in this session
- File paths of modified, created, and deleted files (mark status for each)
- The original user request or goal
- The specific review focus assigned to this oracle (if split)
- Instruction to produce a structured list of findings categorized as: CRITICAL (must fix), IMPORTANT (should fix), SUGGESTION (nice to have)
- **Exclude credentials, tokens, private keys, and sensitive logs from prompts and summaries.** Sensitive logs include: auth tokens/headers, stack traces containing secrets, customer/user PII, proprietary payloads, and environment variables with credentials.

Pseudocode (adapt prompts and oracle count to session context):

```
# Single oracle — covers all aspects
task(subagent_type="oracle", run_in_background=true, load_skills=[], description="Review cycle N: oracle review", prompt="[CONTEXT]: <session summary, file paths with status, goal> [REQUEST]: Review all changes for correctness, architecture, edge cases, security, performance, requirement adherence. Return findings as: CRITICAL / IMPORTANT / SUGGESTION.")

# Multiple oracles — each with a focused domain
task(subagent_type="oracle", run_in_background=true, load_skills=[], description="Review cycle N: oracle (correctness)", prompt="[CONTEXT]: <...> [FOCUS]: Correctness, edge cases, requirement adherence. [REQUEST]: Return findings as: CRITICAL / IMPORTANT / SUGGESTION.")
task(subagent_type="oracle", run_in_background=true, load_skills=[], description="Review cycle N: oracle (architecture)", prompt="[CONTEXT]: <...> [FOCUS]: Architecture, design patterns. [REQUEST]: Return findings as: CRITICAL / IMPORTANT / SUGGESTION.")
# ... add more oracles as needed for security, performance, etc.
```

Wait for all oracle agents to complete. Collect results via `background_output`.

#### Agent Failure Handling

- **Empty output** = agent returned no findings AND no rationale (a valid "no issues" response with reasoning is NOT empty).
- If an oracle fails (crash, timeout, empty output): **retry once**. If still fails, perform a self-review covering that oracle's focus area.
- If all oracles fail: Perform a thorough self-review covering all domains. Note the failure in the cycle summary.
- If `task`/`background_output` primitives are unavailable: Run a comprehensive self-review.

### Step 2 — Re-evaluate Review Findings

Analyze the combined findings from all oracle agents:

1. **Deduplicate** — Merge overlapping findings across oracles.
1. **Validate** — Check each finding against the actual code. Dismiss false positives with a one-line reason in the dismissed findings log (see Cycle Report below).
1. **Resolve conflicts** — If oracles disagree:
   - Verify against code and tests first.
   - Prefer correctness/security over style/preference.
   - If still ambiguous, classify as decision-required and escalate to user.
1. **Classify** remaining findings:
   - **Auto-fixable**: Code fixes, missing error handling, style issues — no user input needed.
   - **Decision-required**: Behavior/API changes, security trade-offs, scope changes, added dependencies, breaking changes, or anything that changes user-visible output.

### Step 3 — User Decision (if needed)

If any findings are classified as **decision-required**:

- Present them to the user via the `question` tool (or via normal chat if `question` tool is unavailable).
- Include context, the oracle's reasoning, and your own assessment for each finding.
- Wait for the user's response before proceeding.

**CRITICAL + decision-required**: If a CRITICAL finding is also decision-required, escalate to user immediately. Block cycle completion until the user decides. If user declines the fix, record an explicit "accepted risk" decision in the cycle report and proceed (do NOT silently suppress it).

If all findings are auto-fixable or no findings remain, skip this step.

### Step 4 — Apply Fixes

Apply all validated fixes, then run diagnostics:

1. Apply each fix (directly or via delegated task).
1. After **all** fixes in this cycle are applied, run `lsp_diagnostics` on all changed files. If `lsp_diagnostics` is unavailable for the file type, run project lint/format/type-check commands instead. If none are available, note this and proceed.
1. Run build/test commands. Discover commands from: package.json scripts, Makefile, CI config, flake checks, or commands used earlier in the session. If none are discoverable, note "no project commands found; skipped."
1. **If diagnostics, lint, build, or tests fail**: Treat each failure as a CRITICAL finding. Fix and re-run, or escalate to user as decision-required. Do NOT proceed to final confirmation with failing checks — record as "accepted risk" only if user explicitly approves.

If no findings require fixes, explicitly state: "No issues found in Cycle N."

### Cycle Report

After each cycle, output a summary in this format in the conversation:

```
## Cycle N Report
- **Files reviewed**: [list with status: new/modified/deleted]
- **Oracle agents used**: [count and focus areas]
- **Findings kept**: [list with severity]
- **Dismissed findings**: [list with one-line reason each]
- **Accepted risks**: [CRITICAL findings user declined to fix, if any]
- **Fixes applied**: [list]
- **Diagnostics**: [lsp_diagnostics/lint/build result or "skipped: reason"]
```

This report persists in the conversation and serves as the dismissed findings log. Cycle 2 MUST reference the Cycle 1 report to avoid re-raising dismissed items — **but re-open a dismissed finding if** (a) the relevant code changed since dismissal, (b) new evidence appears, or (c) the original dismissal reason no longer applies.

______________________________________________________________________

## After Both Baseline Cycles Complete

### Final Confirmation (CRITICAL - MANDATORY question tool usage)

**YOU MUST use the `question` tool** to ask the user whether the overall work is complete. This is a non-negotiable requirement.

```typescript
question(questions=[{
  question: "Both review cycles complete. Summary:\n\n[summary of original work + all fixes from both cycles]\n\nShall I finalize this work?",
  header: "Work completion",
  options: [
    { label: "Complete", description: "Work is done, no further changes needed" },
    { label: "Needs more changes", description: "I have additional requests or modifications" }
  ]
}])
```

**If `question` tool is unavailable**, fallback to normal chat confirmation (but always prefer `question` tool).

If the user selects "Needs more changes", address their feedback, then run **one additional review cycle** (Steps 1–4 + Cycle Report) before asking for confirmation again. Repeat until the user confirms completion.

## Rules

- MUST run 2 baseline review cycles before the first final confirmation.
- **MUST use `question` tool for final confirmation** (or normal chat if tool unavailable).
- MUST fire oracle agents in parallel when using multiple oracles.
- MUST scale oracle count to match change complexity.
- MUST collect and wait for all oracle results before re-evaluation (unless agent failure handling applies).
- MUST NOT skip re-evaluation — never blindly apply agent suggestions.
- MUST NOT apply decision-required fixes without user approval.
- MUST NOT suppress or ignore CRITICAL findings — if user declines, record as accepted risk.
- MUST NOT include credentials, tokens, private keys, or sensitive logs in agent prompts.
- MUST run `lsp_diagnostics` (or equivalent checks) after all fixes in each cycle.
- MUST output a Cycle Report after each cycle to serve as dismissed findings log.
- MUST reference prior Cycle Reports to avoid re-raising dismissed findings — but re-open if code changed, new evidence appears, or dismissal reason no longer applies.
- MUST NOT proceed to final confirmation with failing diagnostics/build/tests — fix or escalate as accepted risk.
- If a cycle finds zero issues, still proceed to the next cycle (fresh perspective may catch different things).
