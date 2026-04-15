______________________________________________________________________

## name: git-commit description: "Git commit workflow skill. MUST USE when creating any git commits. Reads GUIDE.md for structured commit procedure. Complements git-master (general git ops) by focusing on commit composition, staging discipline, and message quality. Triggers: 'commit', 'create commit', 'git commit', 'make a commit', 'commit these changes', 'stage and commit', 'git add and commit'."

# Git Commit Workflow

This skill defines the commit creation workflow. The full procedure is in a separate file.

**IMPORTANT**: Before proceeding, read the full guide using the Read tool:

```
Read file: ~/.config/opencode/skill/git-commit/GUIDE.md
```

Then follow the procedure described in GUIDE.md exactly.

## Quick Reference (use GUIDE.md for details)

1. **Gather Context** — parallel: `git status`, `git diff`, `git diff --staged`, `git log --oneline -20`
1. **Draft Message** — follow repo conventions, WHY over WHAT
1. **Review** — check for secrets, stage only related files
1. **Commit** — `git add` + `git commit -m "..."` + `git status`
1. **Handle Hooks** — never `--no-verify`, fix and retry on failure
1. **Verify** — `git log -1 --oneline`, report to user

## Relationship with git-master

- **git-master**: General git operations (rebase, squash, history search, blame, bisect)
- **git-commit** (this skill): Commit-specific workflow — staging, message drafting, hook handling, verification
- Use both together: git-master for broader git work, this skill for the commit step
