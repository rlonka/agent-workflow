---
name: address-review
description: Respond to the latest agent review on a merge request (GitLab) or pull request (GitHub). Fix or explicitly decline each finding, push, and post a response. Part of the agent-workflow loop; refuses to run once the round limit handed the MR to a human. Use when the user asks to address review comments on a specific MR/PR.
disable-model-invocation: true
---

# Address review

Answer **one** review round posted by `/review-mr`: every finding gets fixed or a reasoned
decline, then one response comment. "MR" means a GitLab merge request or a GitHub pull
request.

**Tracker:** if the project's `AGENTS.md` has a line `Issue tracker: <project URL>`, issues
live in that project (`-R <owner/project>` on issue commands). Otherwise use the `origin`
remote: `github.com` means GitHub (`gh`), any other host GitLab (`glab`; check
`glab auth status`). If neither works, stop and ask.

Never merge, never force-push, never rewrite commits the reviewer already saw.

| Action | GitLab (`glab`) | GitHub (`gh`) |
|---|---|---|
| MR data | `glab api projects/:fullpath/merge_requests/<n>` | `gh pr view <n> --json body,labels,state,url,headRefName,headRefOid` |
| Comments | `glab api "projects/:fullpath/merge_requests/<n>/notes?sort=asc&per_page=100"` (skip `system: true`) | `gh pr view <n> --json comments` |
| Check out | `glab mr checkout <n>` | `gh pr checkout <n>` |
| Comment | `glab mr note <n> -m "$(cat <file>)"` | `gh pr comment <n> -F <file>` |

## Step 1: Read the state and check the guards

Find the latest comment starting with `<!-- agent-review round=<r> ... verdict=<v> ... -->`.
Stop and tell the user why, without changing anything, if:

1. the MR is not open, or it has the label `needs-human`;
2. there is no agent review yet (next step: `/review-mr <n>` in another agent);
3. an `<!-- agent-response round=<r> -->` already exists for that round;
4. the verdict is `approve` (next step: `/await-ci <n>`).

## Step 2: Decide per finding

Check out the MR branch and pull. Read the review, the linked issue, and the code at
each location. For every finding `R<r>.<k>` decide:

- **Fix:** the reviewer is right. `blocker` and `should-fix` findings are fixed unless
  you can show they are wrong.
- **Decline:** the reviewer is wrong or the change is out of scope. Give a concrete
  reason (a spec line, a test, an ADR, a measurement), not an opinion.
- `nit`: fix if trivial, otherwise decline briefly.

If a finding needs a decision only a human can make (requirements, product behaviour),
don't guess: add the label `needs-human`, say why in the response, and stop after posting.

## Step 3: Fix

Fix test-first where behaviour changes: a failing test at a public seam, then the fix. Run the full test suite and
the linters as documented in `AGENTS.md`; everything must pass. Commit using the repo's
commit convention (e.g. `fix: address review round <r>`), then `git push` (no force).

## Step 4: Respond

Write the response to a temporary file and post it. The first line is the state marker;
keep its format exact:

```markdown
<!-- agent-response round=<r> head=<full sha of HEAD after your push> -->
## Response to review round <r>

- **R<r>.1** fixed in <short sha>: <one line>
- **R<r>.2** declined: <concrete reason>

**Tests:** `<command>`: passed
```

## Step 5: Hand over

Tell the user what was fixed and declined, and the next step: `/review-mr <n>` in the
reviewer's agent (round `r + 1`).
