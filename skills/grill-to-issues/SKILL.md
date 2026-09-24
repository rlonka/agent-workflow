---
name: grill-to-issues
description: Turn a fuzzy idea into agreed design docs and ready-to-implement issues. A relentless interview that writes the glossary and ADRs as it goes, then opens a merge request (GitLab) or pull request (GitHub) with the docs, optionally publishes a PRD, and breaks the work into issues. First step of the agent-workflow loop. Use when the user wants to plan a feature or change and end up with issues.
disable-model-invocation: true
---

# Grill to issues

Planning step of the agent-workflow loop: **interview → docs → (PRD) → issues**. It chains
existing skills from [mattpocock/skills](https://github.com/mattpocock/skills) (`grilling`,
`domain-modeling`, `to-prd`, `to-issues`) and adds what connects them: the docs land in
their own MR, and the issues point to them. "MR" means a GitLab merge request or a GitHub
pull request.

Never merge, never push to the default branch.

## Setup

- The repo must have `docs/agents/issue-tracker.md`. If it is missing, stop and tell the
  user to run `/setup-matt-pocock-skills`.
- The working tree must be clean, so the docs MR contains only what this session wrote.

| Action | GitLab (`glab`) | GitHub (`gh`) |
|---|---|---|
| Default branch | `glab api projects/:fullpath` → `default_branch` | `gh repo view --json defaultBranchRef` |
| Open MR | `glab mr create -s <branch> -b <default> -t "<title>" -d "$(cat <file>)" -y` | `gh pr create -H <branch> -B <default> -t "<title>" -F <file>` |

## Step 1: Grill and write the docs

Use the `grilling` and `domain-modeling` skills together (in Claude Code: call the Skill
tool for each), exactly as `grill-with-docs` does. Interview in rounds until the design
tree is exhausted; update `CONTEXT.md` and write ADRs as decisions settle.

Don't continue until the user confirms you have a shared understanding.

## Step 2: Docs MR

If the session changed no docs (`CONTEXT.md`, `CONTEXT-MAP.md`, `docs/adr/`), skip this
step. Otherwise:

1. `git switch -c docs/<short-slug>` (the uncommitted docs come along), commit only those
   files (`docs: glossary and ADRs for <topic>`), `git push -u origin docs/<short-slug>`.
2. Open an MR against the default branch. Description: one line on the topic, then a
   list of the ADRs (number, title, one-line decision) and the glossary terms added or
   changed.
3. Switch back to the default branch.

## Step 3: PRD (optional)

Ask the user whether to write a PRD first. Recommend **yes** when the work will split into
more than about three issues or changes behaviour users will notice; **no** for internal
or small changes. On yes, use `to-prd`; the PRD issue becomes the parent of the issues.

## Step 4: Issues

Use `to-issues` on the conversation (with the PRD issue as the parent, if there is one).
In addition to its template, every issue body gets a **Design docs** line: the docs MR
and the ADRs (by path) that constrain that slice.

## Step 5: Hand over

Report the docs MR, the PRD (if any) and the issues in implementation order, then the
next steps:

1. **A human reviews and merges the docs MR first.** `/implement-issue` branches from the
   default branch, so the implementing agent only sees the ADRs and the glossary once
   they are merged.
2. Then `/implement-issue <first unblocked issue>`.
