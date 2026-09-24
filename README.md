# agent-workflow

Skills for an issue → merge request → cross-agent review → CI loop with **Claude Code,
Codex and OpenCode**, on **GitLab or GitHub**. One agent implements, a different agent
reviews, the loop is capped at a fixed number of rounds, and **merging stays with a human**.

```
PLAN                     IMPLEMENT                 REVIEW LOOP (max 3 rounds)          FINISH
/grill-to-issues         /implement-issue #12      /review-mr !34      ← agent B       /await-ci !34
  interview, glossary,     branch, TDD, tests,       findings + verdict                  waits for the pipeline
  ADRs → docs MR           commit, push,           /address-review !34 ← agent A         green → ready-to-merge
  PRD (optional)           MR "Closes #12"           fix or decline, push                MERGE = HUMAN
  issues                                           limit reached → needs-human
```

## Skills

| Skill | Run by | What it does |
|---|---|---|
| [`grill-to-issues`](skills/grill-to-issues/SKILL.md) | you + any agent | Interview in rounds, write glossary and ADRs, open a docs MR, optional PRD, publish issues |
| [`implement-issue`](skills/implement-issue/SKILL.md) | implementer (agent A) | Issue → branch → test-first implementation → checks → commit, push → MR that closes the issue |
| [`review-mr`](skills/review-mr/SKILL.md) | reviewer (agent B) | One review round: spec and standards, findings with IDs and severities, verdict |
| [`address-review`](skills/address-review/SKILL.md) | implementer (agent A) | Fix or decline each finding with a reason, push, respond |
| [`await-ci`](skills/await-ci/SKILL.md) | implementer (agent A) | Wait for the pipeline; green → `ready-to-merge`; red → fix, at most 2 attempts |

These skills build on [mattpocock/skills](https://github.com/mattpocock/skills):
`grill-to-issues` chains `grilling`, `domain-modeling`, `to-prd` and `to-issues`;
`implement-issue` uses `tdd`; `review-mr` follows `review`. For a small, clear task,
skip the planning step and write the issue yourself.

Every skill runs only when you invoke it, and you run each step yourself, typically
alternating between two tools (e.g. Claude Code implements, Codex reviews). The loop is
deliberately manual: you see every round, and the state lives in the MR, so nothing
depends on an agent remembering where it was.

## State: kept in the MR, not in the agent

| Where | Marker | Written by |
|---|---|---|
| MR description | `<!-- agent-workflow implementer=claude-code max-rounds=3 -->` | `implement-issue` |
| Review comment | `<!-- agent-review round=1 max=3 verdict=changes-requested reviewer=codex head=<sha> -->` | `review-mr` |
| Response comment | `<!-- agent-response round=1 head=<sha> -->` | `address-review` |
| CI comment | `<!-- agent-ci attempt=1 max=2 status=failed head=<sha> -->` | `await-ci` |

The markers are HTML comments: invisible in the rendered MR, readable by every agent.
Each skill recomputes the state from them before acting and refuses out-of-order steps
(e.g. a second review before the response).

**Labels:** `agent-approved` (review passed), `ready-to-merge` (CI green),
`needs-human` (round or attempt limit reached, or a decision only a human can make;
all skills stop).

## Keeping the merge with a human

The skills never merge, but an instruction is not a guarantee. Two more layers:

1. **Deny merge commands** in the agents' permissions, e.g. with
   [agents-setup](https://github.com/rlonka/agents-setup) guardrails:
   `gh pr merge` and `glab mr merge` under `deny`.
2. **Require an approval** on the server (GitLab approval rules, GitHub branch
   protection). This is the hard stop: agents run with your token, so they could still
   reach the merge API directly.

## Installation

```bash
npx skills add rlonka/agent-workflow -g
npx skills add mattpocock/skills -g     # grilling, domain-modeling, to-prd, to-issues,
                                        # tdd, review, setup-matt-pocock-skills
```

`gh` or `glab` must be authenticated for the repository's host. The skills infer the
tracker from `git remote`: `github.com` means GitHub, any other host GitLab.

Once per repository, run `/setup-matt-pocock-skills`. It writes
`docs/agents/issue-tracker.md`, which `grill-to-issues` requires (it hands over to
`to-prd` and `to-issues`) and which the other skills follow when present, e.g. when the
issues live in a different project than the code.

## License

[MIT](LICENSE)
