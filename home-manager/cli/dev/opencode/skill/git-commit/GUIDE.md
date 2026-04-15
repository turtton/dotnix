# Git Commit Creation Guide

Execute a structured git commit workflow following best practices for atomic commits with meaningful messages.

## Commit Philosophy

- **Atomic commits**: Each commit represents one logical change
- **Meaningful messages**: Messages explain WHY, not just WHAT
- **Repository conventions**: Follow existing commit style in the repository
- **Safety first**: Review changes before committing, respect hooks

## Commit Procedure

### Step 1 — Gather Context

Collect information about changes and repository conventions in parallel:

```typescript
// Run these in parallel
bash("git status", ...)  // See untracked/modified files
bash("git diff --staged", ...)  // See staged changes
bash("git diff", ...)  // See unstaged changes
bash("git log --oneline -20", ...)  // See recent commit message style
```

Key information to extract:

- **Changed files**: Which files are new, modified, or deleted
- **Change type**: Feature add, enhancement, bugfix, refactor, docs, test
- **Commit style**: Conventional commits, imperative mood, prefix patterns, capitalization
- **Scope**: What subsystem/module is affected

### Step 2 — Draft Commit Message

Based on gathered context, draft a commit message that:

1. **Follows repository conventions**:

   - Conventional Commits format if used: `type(scope): subject`
   - Imperative mood if used: "Add", "Fix", "Update" (not "Added", "Fixed")
   - Capitalization style: match existing commits
   - Subject line length: typically 50-72 characters

1. **Accurately reflects changes**:

   - "add" = wholly new feature/file
   - "update"/"enhance" = improvement to existing feature
   - "fix" = bug correction
   - "refactor" = restructuring without behavior change
   - "docs" = documentation only
   - "test" = test-related changes
   - "chore" = maintenance, dependencies, tooling

1. **Focuses on WHY over WHAT**:

   - Good: "Add user authentication to protect admin endpoints"
   - Bad: "Update auth.ts and middleware.js"
   - Good: "Fix race condition in async data loading"
   - Bad: "Fix bug"

1. **Includes body if needed** (for complex changes):

   - Why the change was necessary
   - How it addresses the problem
   - Any trade-offs or limitations
   - Breaking changes if any

### Step 3 — Review Before Commit

**CRITICAL**: Never commit files likely containing secrets:

- `.env` files
- `credentials.json`, `secrets.yaml`
- Files with API keys, tokens, passwords
- Private keys (`*.pem`, `*.key`)

If such files appear in `git status`, WARN the user and DO NOT stage them unless explicitly confirmed.

**Files to stage**:

- Only files related to the current logical change
- Exclude unrelated modifications (those should be separate commits)
- Include related test updates if present

### Step 4 — Create Commit

Execute commit with the drafted message:

```bash
# Stage relevant files
git add <file1> <file2> ...

# Create commit
git commit -m "commit message here"

# Verify success
git status
```

**Sequential execution**: Use `&&` to chain commands since each depends on the previous.

### Step 5 — Handle Pre-commit Hooks

If pre-commit hook makes changes:

- Hook modified files (e.g., auto-formatting) → `git add` those files and create NEW commit
- Hook rejected commit (errors) → Fix issues and create NEW commit
- NEVER use `--no-verify` unless explicitly requested by user

**CRITICAL**: Only use `git commit --amend` when ALL conditions met:

1. User explicitly requested amend, OR hook auto-modified files after successful commit
1. Commit was created by you in this session (`git log -1 --format='%an %ae'`)
1. Commit has NOT been pushed (`git status` shows "Your branch is ahead")

If commit FAILED or was REJECTED: FIX and create NEW commit. Never amend a failed commit.

### Step 6 — Verify and Report

After successful commit:

```bash
# Show the created commit
git log -1 --oneline

# Verify working tree status
git status
```

Report to user:

- Commit hash and message
- Files committed
- Any warnings (e.g., pre-existing issues not committed)

## Safety Rules

- **NEVER run**:

  - `git push --force` to main/master (warn if requested)
  - `git commit --no-verify` (unless user explicitly requests)
  - `--no-gpg-sign` (unless user explicitly requests)
  - Destructive git commands without confirmation

- **NEVER update** git config (user.name, user.email, etc.)

- **NEVER commit** without user request:

  - Only commit when explicitly asked
  - Being proactive with commits feels intrusive to users

- **NEVER create empty commits**:

  - If `git status` shows no changes, report this and skip commit

## Edge Cases

### Multiple Logical Changes

If `git diff` shows multiple unrelated changes:

1. Inform user: "I see changes to X and Y which are unrelated. Should I create separate commits?"
1. Wait for user decision
1. Create atomic commits as directed

### Commit Message Ambiguity

If unsure about commit type or message:

1. Present draft message with reasoning
1. Ask user: "I drafted this message: '[message]'. Does this accurately reflect the change?"
1. Adjust based on feedback

### Pre-existing Issues

If `git status` shows:

- Untracked files unrelated to current change → Don't stage, note in report
- Pre-existing lint/test failures → Note in report, don't fix unless asked
- Conflicts or rebase in progress → Ask user how to proceed

## Example Workflows

### Simple Feature Commit

```
User: "Commit the authentication changes"

1. Parallel context gathering:
   - git status → shows modified: src/auth.ts, src/middleware/auth.ts
   - git diff --staged → empty (nothing staged yet)
   - git log -20 → shows pattern: "feat(auth): ..." style

2. Draft message: "feat(auth): add JWT token validation"

3. Stage and commit:
   git add src/auth.ts src/middleware/auth.ts && \
   git commit -m "feat(auth): add JWT token validation" && \
   git status

4. Report: "Created commit abc1234: feat(auth): add JWT token validation"
```

### Bugfix with Hook Auto-formatting

```
User: "Commit the bugfix"

1. Context → bugfix in data-loader.ts
2. Draft → "fix: resolve race condition in async data loading"
3. Commit → succeeds, but pre-commit hook runs prettier
4. Hook modified data-loader.ts (auto-formatted)
5. Stage formatted file: git add data-loader.ts
6. Create NEW commit: git commit -m "chore: apply prettier formatting"
   (OR amend if user requested and conditions met)
```

## Integration with Other Workflows

This skill focuses ONLY on the commit creation step. It does NOT:

- Implement code changes (that's before commit)
- Push to remote (that's after commit, needs explicit request)
- Create pull requests (separate workflow)
- Resolve merge conflicts (separate concern)

If user requests "implement X and commit", split the workflow:

1. Implement X (using appropriate tools/agents)
1. Load this skill to execute commit step

## Tool Requirements

This skill requires:

- `bash` tool for git commands
- Working git repository
- Proper git user configuration (user.name, user.email)

If git is not configured, report error and ask user to configure.
