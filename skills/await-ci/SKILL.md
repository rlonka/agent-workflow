---
name: await-ci
description: Wait for the CI pipeline of an approved merge request (GitLab) or pull request (GitHub). On green, label it ready-to-merge for a human; on red, fix failures the MR caused, within a small attempt limit. Never merges. Last step of the agent-workflow loop. Use when the user asks to wait for or check CI on a specific MR/PR.
disable-model-invocation: true
---

# Await CI

Get an approved MR/PR to a green pipeline and hand it to a human. **Merging is always a
human's decision: never merge, never enable auto-merge.** "MR" means a GitLab merge
request or a GitHub pull request.

**Tracker:** if the project's `AGENTS.md` has a line `Issue tracker: <project URL>`, issues
live in that project (`-R <owner/project>` on issue commands). Otherwise use the `origin`
remote: `github.com` means GitHub (`gh`), any other host GitLab (`glab`; check
`glab auth status`). If neither works, stop and ask.

| Action | GitLab (`glab`) | GitHub (`gh`) |
|---|---|---|
| MR data | `glab api projects/:fullpath/merge_requests/<n>` (`sha`, `head_pipeline`) | `gh pr view <n> --json labels,state,url,headRefName,headRefOid` |
| Pipeline status | `head_pipeline.status` from MR data; `null` = no pipeline | `gh run list --commit <sha> --json databaseId,name,status,conclusion`; empty = no CI |
| Failed logs | `glab api "projects/:fullpath/pipelines/<id>/jobs?scope[]=failed"`, then `glab api projects/:fullpath/jobs/<job>/trace` | `gh run view <databaseId> --log-failed` |
| Comment | `glab mr note <n> -m "$(cat <file>)"` | `gh pr comment <n> -F <file>` |
| Add label | `glab mr update <n> -l <label>` | `gh label create <label> --force` then `gh pr edit <n> --add-label <label>` |

## Step 1: Guards

Stop and tell the user why if the MR is not open or has the label `needs-human`. If it
doesn't have `agent-approved`, say that it hasn't passed agent review and ask whether to
continue anyway.

Count earlier `<!-- agent-ci ... status=failed ... -->` comments where you pushed a fix;
at most **2** fix attempts.

## Step 2: Wait for the pipeline of the current head

Poll every 30 seconds, up to 60 minutes, until the pipeline for the MR's current head
commit has finished (GitLab: `success`, `failed`, `canceled`, `skipped`; GitHub: every run
`completed`). Make sure the status belongs to the current head sha, not an older push.

- **No pipeline / no runs at all:** the repo has no CI. Tell the user, don't add
  `ready-to-merge`, and stop: a human has to verify it.
- **Timeout:** report the pipeline URL and stop.

## Step 3a: Green

Post the comment below and add the label `ready-to-merge`. List every commit pushed after
the approving review (CI fixes), because the reviewer never saw them.

```markdown
<!-- agent-ci status=success head=<full sha> -->
## CI green, ready for a human to merge

- Pipeline: <url>
- Commits after the agent review: <short shas and subjects, or "none">
```

Then tell the user the MR URL and that merging is up to them.

## Step 3b: Red

Read the failed jobs' logs and decide whether the MR caused the failure.

- **Not caused by the MR** (infrastructure, a flaky test that fails the same way on the
  default branch, expired credentials): don't change code. Report it and stop.
- **Caused by the MR** and attempts left: check out the MR branch, fix test-first, run the
  suite locally, commit (`fix: <what broke in CI>`), `git push` (no force), post the
  comment below, and go back to step 2.
- **Caused by the MR** and no attempts left: add `needs-human`, post the comment, and stop.

```markdown
<!-- agent-ci attempt=<k> max=2 status=failed head=<full sha of the failing head> -->
## CI failed (attempt <k> of 2)

- Failed job: <name>: <one-line cause>
- Action: <fixed in <short sha> | not caused by this MR: <why> | attempt limit reached>
```
