---
name: review-mr
description: Review a merge request (GitLab) or pull request (GitHub) written by another agent and post one review round as a comment with a verdict. Part of the agent-workflow loop, which caps the loop at a fixed number of rounds and then hands over to a human. Use when the user asks to review a specific MR/PR.
disable-model-invocation: true
---

# Review MR

Post **one** review round on an MR/PR opened by `/implement-issue`. The round count, the
verdict and the limit live in the MR itself (hidden markers in comments), so any agent
in any session reaches the same conclusion. "MR" means a GitLab merge request or a GitHub
pull request.

**Tracker:** if `docs/agents/issue-tracker.md` exists, follow it. Otherwise infer it from
`git remote get-url origin`: `github.com` means GitHub (`gh`), any other host means GitLab
(`glab`, authenticated for that host: `glab auth status`). If neither works, stop and ask.

You review; you don't fix. Never push to the MR branch, never merge, never approve through
the platform's approval button: the verdict is the comment and the label.

| Action | GitLab (`glab`) | GitHub (`gh`) |
|---|---|---|
| MR data | `glab api projects/:fullpath/merge_requests/<n>` | `gh pr view <n> --json body,labels,state,url,headRefName,baseRefName,headRefOid` |
| Comments | `glab api "projects/:fullpath/merge_requests/<n>/notes?sort=asc&per_page=100"` (skip `system: true`) | `gh pr view <n> --json comments` |
| Check out | `glab mr checkout <n>` | `gh pr checkout <n>` |
| Comment | `glab mr note <n> -m "$(cat <file>)"` | `gh pr comment <n> -F <file>` |
| Add label | `glab mr update <n> -l <label>` | `gh label create <label> --force` then `gh pr edit <n> --add-label <label>` |

## Step 1: Read the state and check the guards

From the MR description, read `<!-- agent-workflow implementer=<tool> max-rounds=<max> -->`
(default max 3). From the comments, collect the `<!-- agent-review ... -->` and
`<!-- agent-response ... -->` markers. This review is round `r = number of reviews + 1`.

Stop and tell the user why, without posting anything, if:

1. the MR is not open;
2. it has the label `needs-human`;
3. the latest review has verdict `approve` (next step is `/await-ci`);
4. the latest review has no `agent-response` with the same round yet (next step is
   `/address-review` in the implementer's agent);
5. `r > max`: add the label `needs-human` and stop.

If `implementer` is the tool you are, say so and ask the user whether to continue: the
point of this loop is a second pair of eyes.

## Step 2: Gather context

1. Make sure the working tree is clean, remember the current branch, check out the MR.
2. **Spec:** the issue(s) referenced by `Closes #n` in the description, with comments.
3. **Standards:** `AGENTS.md`, `CONTEXT.md`, ADRs in the touched area, `CONTRIBUTING.md`.
4. **Diff:** round 1: `git diff origin/<target>...HEAD`. Round 2+: also read the previous
   review and response, and `git diff <head from the previous review>..HEAD`.
5. Run the project's test suite once (as documented in `AGENTS.md`) and note the result.

## Step 3: Review

Review along two separate axes, the way `/review` does (use it, or its sub-agent
approach, if your tool has it):

- **Spec:** is every acceptance criterion met? Anything missing, wrong, or not asked for?
- **Standards:** does the code follow the repo's documented conventions? Skip anything a
  formatter or linter enforces.

Every finding gets an ID `R<r>.<k>`, a severity and a location:

- `blocker`: wrong behaviour, broken or missing test, security problem, unmet criterion;
- `should-fix`: real problem that doesn't break the feature;
- `nit`: optional, never blocks.

Rules for round 2+ (no moving goalposts):

- For each previous finding marked fixed, check that it really is.
- Accept a declined finding if the reason holds. If it doesn't and the finding is a
  blocker, keep it once and explain why; don't argue a point a third time.
- Raise new findings only on code changed since the previous review, unless it's a blocker.

**Verdict:** `changes-requested` if any `blocker` or `should-fix` is open, else `approve`.

## Step 4: Post the round

Write the comment to a temporary file and post it. The first line is the state marker;
keep its format exact:

```markdown
<!-- agent-review round=<r> max=<max> verdict=<approve|changes-requested> reviewer=<tool> head=<full sha of HEAD> -->
## Agent review, round <r> of <max> (<tool>)

**Verdict:** <approve | changes requested>
**Tests:** `<command>`: <passed | failed: summary>

### Spec (#<issue>)
- <criterion>: met | not met (<why>)

### Findings
- **R<r>.1** `blocker` `path/file.py:42`: <what is wrong and why>. Suggestion: <how>.

### Previous round
- **R<r-1>.2**: fixed | declined, accepted | still open: <why>
```

Omit empty sections. Then set the label:

- `approve` → add `agent-approved`;
- `changes-requested` and `r == max` → add `needs-human` and end the comment with
  "Round limit reached; a human decides the open points."

## Step 5: Clean up and hand over

Switch back to the branch you started on. Tell the user the verdict and the next step:
`/address-review <n>` in the implementer's agent, `/await-ci <n>` after an approve, or a
human decision after `needs-human`.
