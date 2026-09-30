---
name: implement-issue
description: Implement one issue end to end. Read the issue, create a branch, implement it test-first, run the checks, commit, push and open a merge request (GitLab) or pull request (GitHub) that closes the issue. First step of the agent-workflow review loop. Use when the user asks to implement or pick up a specific issue.
disable-model-invocation: true
---

# Implement issue

Take one issue from the tracker to an open MR/PR that is ready for review by a
**different** agent (`/review-mr`). "MR" below means a GitLab merge request or a GitHub
pull request.

Never merge, never push to the default branch, never force-push.

## Setup

- **Tracker:** if the project's `AGENTS.md` has a line `Issue tracker: <project URL>`, issues
  live in that project (`-R <owner/project>` on issue commands). Otherwise use the `origin`
  remote: `github.com` means GitHub (`gh`), any other host GitLab (`glab`; check
  `glab auth status`). If neither works, stop and ask.
- The working tree must be clean (`git status --porcelain` empty). If not, stop and ask.

| Action | GitLab (`glab`) | GitHub (`gh`) |
|---|---|---|
| Read issue | `glab issue view <n> --comments` | `gh issue view <n> --comments` |
| Default branch | `glab api projects/:fullpath` → `default_branch` | `gh repo view --json defaultBranchRef` |
| Open MR | `glab mr create -s <branch> -b <default> -t "<title>" -d "$(cat <file>)" -y` | `gh pr create -H <branch> -B <default> -t "<title>" -F <file>` |

## Process

### 1. Understand the issue

Read the issue with all comments, the repo's `AGENTS.md`, `CONTEXT.md` and the ADRs in
the area you will touch. Write down the acceptance criteria as a checklist. If they are
missing or ambiguous, ask the user now; don't guess.

### 2. Branch

```bash
git fetch origin && git switch -c <n>-<short-slug> origin/<default-branch>
```

### 3. Agree the seams

A **seam** is the public boundary where you observe behaviour without reaching inside.
Tests live only at seams. List the seams and the tests you plan, one line each, and
confirm them with the user; don't write a test at an unconfirmed seam. Prefer existing
seams, as high up and as few as possible.

### 4. Implement test-first

Red → green, one **vertical slice** at a time: one failing test at an agreed seam, the
minimum code to pass it, repeat. Let each cycle inform the next; don't write all the
tests first. Refactoring is not part of the loop. What makes a test worth keeping, and
when to mock: [TESTS.md](TESTS.md).

Keep the change to what the issue asks for; note anything else you notice for the MR
description instead of fixing it.

### 5. Verify

Run the project's full test suite and linters as documented in `AGENTS.md` (lint only the
files you changed if the repo isn't lint-clean). Everything must pass. Tick off every
acceptance criterion; if one can't be met, stop and tell the user why.

### 6. Commit and push

If the project has a `CHANGELOG.md`, add one short line for this change under
`[Unreleased]`, under the matching [Keep a Changelog](https://keepachangelog.com/) heading
(Added, Changed, Fixed or Removed), in the file's existing style and without an issue
reference. This applies to every MR, with no exceptions: an internal-only change goes
under a fitting heading such as Changed. Skip this if the project has no changelog.

Commit using the repo's commit convention (Conventional Commits unless the repo says
otherwise), referencing the issue (`owner/project#n` if the issues live in another
project). Push the branch: `git push -u origin <branch>`.

### 7. Open the MR

Write the description to a temporary file, then open the MR (commands above) targeting
the default branch. Description template:

```markdown
Closes #<n>   (or Closes <owner/project>#<n> if the issues live in another project)

## What changed
<2-5 bullets; note the CHANGELOG entry, if the project has a changelog>

## How it was verified
<test commands run and their result; acceptance criteria checklist, all ticked>

## Notes for the reviewer
<decisions, trade-offs, things deliberately left out; "none" if nothing>

<!-- agent-workflow implementer=<your tool: claude-code | codex | opencode> max-rounds=3 -->
```

The last line is machine-readable state for the other skills; keep it exactly in that form.

### 8. Hand over

Report the MR URL and the next step: **run `/review-mr <number>` in a different agent**
(e.g. Codex if you are Claude Code). A reviewer that wrote the code misses its own
blind spots.

The test-first rules are based on `tdd` from mattpocock/skills (MIT); see [NOTICE.md](NOTICE.md).
