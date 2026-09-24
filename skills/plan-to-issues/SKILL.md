---
name: plan-to-issues
description: Turn an idea into agreed design docs and ready-to-implement issues. Interviews the user in rounds until every design decision is settled, writes the glossary (CONTEXT.md) and ADRs as they settle, puts them in their own merge request (GitLab) or pull request (GitHub), optionally publishes a PRD, and breaks the work into vertical-slice issues. First step of the agent-workflow loop. Use when the user wants to plan a feature or change.
disable-model-invocation: true
---

# Plan to issues

**Interview → docs → (PRD) → issues.** "MR" means a GitLab merge request or a GitHub pull
request. Never merge, never push to the default branch.

## Setup

**Tracker:** if the project's `AGENTS.md` has a line `Issue tracker: <project URL>`, issues
go to that project (`-R <owner/project>` on issue commands). Otherwise use the `origin`
remote: `github.com` means GitHub (`gh`), any other host GitLab (`glab`; check
`glab auth status`). If neither works, stop and ask.

Run `git status --porcelain` and remember what is already uncommitted: you will commit
only the files this session writes.

| Action | GitLab (`glab`) | GitHub (`gh`) |
|---|---|---|
| Default branch | `glab api projects/:fullpath` → `default_branch` | `gh repo view --json defaultBranchRef` |
| Create issue | `glab issue create -t "<title>" -d "$(cat <file>)" -l <labels> -y` | `gh issue create -t "<title>" -F <file> -l <labels>` |
| Open MR | `glab mr create -s <branch> -b <default> -t "<title>" -d "$(cat <file>)" -y` | `gh pr create -H <branch> -B <default> -t "<title>" -F <file>` |

## Step 1: Interview, writing the docs as you go

Read `AGENTS.md`, `CONTEXT.md` (or `CONTEXT-MAP.md`) and `docs/adr/` first.

**Map the design as a tree:** every decision branches into the decisions that depend on
it. Work it in **rounds**. A round asks the whole **frontier**: every open decision whose
prerequisites are already settled. A question that depends on another question still open
in this round belongs to a later round.

- **Ask with the tool's question dialog if it has one** (in Claude Code: AskUserQuestion,
  up to 4 questions per call, your recommendation as the first option). Otherwise number
  the questions, each with your recommended answer:

  ```
  Q1 - <title>: <question, with the options>
  → Recommended: <answer and why>
  ```

- **Facts are your job, decisions are the user's.** Look up anything the environment can
  answer (code, config, tools) yourself, with a sub-agent if you have them; never ask the
  user for it. Only the questions that depend on a pending lookup wait for it.
- **Keep the language precise.** Challenge terms that conflict with `CONTEXT.md` or are
  vague, and test them with concrete edge cases. Check what the user says against the
  code and point out contradictions.
- **Write the docs as decisions settle:** glossary terms into `CONTEXT.md`
  ([CONTEXT-FORMAT.md](CONTEXT-FORMAT.md)), and an ADR only when a decision is hard to
  reverse, surprising without context and a real trade-off ([ADR-FORMAT.md](ADR-FORMAT.md)).

The interview is done when the frontier is empty. **Don't continue until the user confirms
you have a shared understanding.**

## Step 2: Docs MR

Skip this step if the session wrote no docs. Otherwise:

1. `git switch -c docs/<short-slug>`; stage **only** the `CONTEXT.md`, `CONTEXT-MAP.md` and
   `docs/adr/` files this session wrote; commit (`docs: glossary and ADRs for <topic>`);
   `git push -u origin docs/<short-slug>`.
2. Open an MR against the default branch: one line on the topic, then the ADRs (number,
   title, one-line decision) and the glossary terms added or changed.
3. Switch back to the default branch.

## Step 3: PRD (optional)

Ask whether to write a PRD. Recommend **yes** when the work splits into more than about
three issues or changes behaviour users will notice; **no** for small or internal work.
On yes, agree the test seams with the user (prefer existing ones, as high up as possible,
as few as possible), then publish an issue labelled `prd`:

```markdown
## Problem
<the user's problem, from their perspective>

## Solution
<the solution, from the user's perspective>

## User stories
1. As a <actor>, I want <feature>, so that <benefit>
<a long, numbered list covering every aspect>

## Decisions
<modules and interfaces touched, contracts, schema changes, technical clarifications;
no file paths or code: they go stale>

## Testing
<seams under test, what makes a good test here, existing tests to follow>

## Out of scope
<explicitly excluded>

Design docs: <docs MR, ADR paths>
```

## Step 4: Issues

1. **Draft vertical slices.** Each issue is a thin **tracer bullet** through every layer it
   touches (e.g. config, logic, API, tests), not one layer of many. A finished slice is
   demoable or verifiable on its own. Prefactoring that makes later slices easy comes first.
2. **Show the breakdown** as a numbered list (title, blocked by, user stories covered) and
   ask: is the granularity right, are the dependencies right, merge or split anything?
   Iterate until the user approves.
3. **Publish in dependency order** (blockers first, so "Blocked by" can reference real
   numbers), labelled `ready-for-agent`:

```markdown
## Parent
<the PRD issue, if there is one>

## What to build
<end-to-end behaviour of this slice, not layer-by-layer steps; no file paths or code>

## Acceptance criteria
- [ ] <criterion>

## Blocked by
<issue references, or "None, can start immediately">

Design docs: <docs MR and the ADRs that constrain this slice>
```

Don't close or edit the PRD issue.

## Step 5: Hand over

Report the docs MR, the PRD and the issues in implementation order, then the next steps:

1. **A human reviews and merges the docs MR first.** `/implement-issue` branches from the
   default branch, so the implementing agent sees the ADRs and glossary only once merged.
2. Then `/implement-issue <first unblocked issue>`.

Based on `grilling`, `domain-modeling`, `to-prd` and `to-issues` from mattpocock/skills
(MIT); see [NOTICE.md](NOTICE.md).
