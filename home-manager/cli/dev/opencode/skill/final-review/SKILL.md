______________________________________________________________________

## name: final-review description: "End-of-work review cycle skill. Run two baseline rounds of oracle agent review, re-evaluate findings, ask user decisions if needed, apply fixes, then confirm completion. Triggers: 'final review', 'end of work review', 'review cycle'."

# Final Review Cycle

This skill defines the end-of-work review procedure. The full procedure is in a separate file.

**IMPORTANT**: Before proceeding, read the full guide using the Read tool:

```
Read file: ~/.config/opencode/skill/final-review/GUIDE.md
```

Then follow the procedure described in GUIDE.md exactly.

## Quick Reference (use GUIDE.md for details)

1. **Review Cycle 1** — Fire oracle agents, re-evaluate findings, apply fixes
1. **Review Cycle 2** — Repeat with fresh perspective
1. **Final Confirmation** — **MUST use `question` tool** to ask user completion

## Critical Requirements

### MANDATORY: question Tool for Completion

After both baseline review cycles complete, you **MUST** use the `question` tool to confirm with the user whether work is complete:

```typescript
question(questions=[{
  question: "Both review cycles complete. Summary:\n\n[work summary + fixes]\n\nShall I finalize this work?",
  header: "Work completion",
  options: [
    { label: "Complete", description: "Work is done, no further changes needed" },
    { label: "Needs more changes", description: "I have additional requests or modifications" }
  ]
}])
```

**This step is NON-NEGOTIABLE.** Do NOT report completion without user confirmation via `question` tool.

If `question` tool is unavailable, use normal chat for confirmation (but always prefer `question` tool when available).

## Review Scope

- **Covers**: Changes in current session, immediate interfaces affected
- **Does NOT cover**: Unrelated code, pre-existing issues, broad refactoring debates

For complete procedure, diagnostics handling, cycle report format, and all rules → **Read GUIDE.md**.
