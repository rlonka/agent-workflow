# agent-workflow

Self-contained skills for a plan → issue → merge request → cross-agent review → CI loop
with **Claude Code, Codex and OpenCode**, on **GitLab or GitHub**. One agent implements,
a different agent reviews, the loop is capped at a fixed number of rounds, and **merging
stays with a human**. No other skill set and no per-repository setup is required.

```
PLAN                     IMPLEMENT                 REVIEW LOOP (max 3 rounds)          FINISH
/plan-to-issues          /implement-issue #12      /review-mr !34      ← agent B       /await-ci !34
  interview, glossary,     branch, TDD, tests,       findings + verdict                  waits for the pipeline
  ADRs → docs MR           commit, push,           /address-review !34 ← agent A         green → ready-to-merge
  PRD (optional)           MR "Closes #12"           fix or decline, push                MERGE = HUMAN
  issues                                           limit reached → needs-human
```

## Skills

| Skill | Alias | Run by | What it does |
|---|---|---|---|
| [`plan-to-issues`](skills/plan-to-issues/SKILL.md) | `wf-plan` | you + any agent | Interview in rounds, write glossary and ADRs, open a docs MR, optional PRD, publish issues |
| [`implement-issue`](skills/implement-issue/SKILL.md) | `wf-implement` | implementer (agent A) | Issue → branch → test-first implementation → checks → commit, push → MR that closes the issue |
| [`review-mr`](skills/review-mr/SKILL.md) | `wf-review` | reviewer (agent B) | One review round: spec and standards, findings with IDs and severities, verdict |
| [`address-review`](skills/address-review/SKILL.md) | `wf-respond` | implementer (agent A) | Fix or decline each finding with a reason, push, respond |
| [`await-ci`](skills/await-ci/SKILL.md) | `wf-ship` | implementer (agent A) | Wait for the pipeline; green → `ready-to-merge`; red → fix, at most 2 attempts |
| [`domain-docs`](skills/domain-docs/SKILL.md) | `wf-domain` | you + any agent | Work on the glossary (`CONTEXT.md`) and ADRs without planning issues |

The `wf-*` aliases name the skills by workflow phase; each one just follows the skill it
points to. For a small, clear task, skip planning and write the issue yourself.

Every skill runs only when you invoke it, and you run each step yourself, typically
alternating between two tools (e.g. Claude Code implements, Codex reviews). The loop is
deliberately manual: you see every round, and the state lives in the MR, so nothing
depends on an agent remembering where it was.

## Conventions the skills rely on

- **Tracker:** inferred from the `origin` remote: `github.com` means GitHub (`gh`), any
  other host GitLab (`glab`). If the issues live in a different project than the code,
  add one line to the project's `AGENTS.md`:
  `Issue tracker: https://code.example.com/group/tracker`.
- **Domain docs:** `CONTEXT.md` (glossary) and `docs/adr/` (decisions) at the repo root,
  or a `CONTEXT-MAP.md` pointing to one `CONTEXT.md` per context in a monorepo. Created
  lazily by `plan-to-issues` and `domain-docs`. For agents to read them outside these
  skills too, add a line to your global `AGENTS.md`, for example:
  "If the repo has `CONTEXT.md` or `docs/adr/`, read the relevant parts before exploring
  code, use the glossary's terms, and call out anything that contradicts an ADR."
- **Labels:** `ready-for-agent` (issue ready), `prd` (PRD issue), `agent-approved`
  (review passed), `ready-to-merge` (CI green), `needs-human` (limit reached or a decision
  only a human can make; all skills stop).

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
```

`gh` or `glab` must be authenticated for the repository's host. Install the `wf-*`
aliases together with the skills they point to.

### OpenCode

OpenCode loads skills through its `skill` tool but never lists them as slash commands.
For `/plan-to-issues`, `/wf-plan` and the rest in its command menu, copy the command
files:

```bash
git clone https://github.com/rlonka/agent-workflow.git /tmp/agent-workflow
mkdir -p ~/.config/opencode/commands
cp /tmp/agent-workflow/opencode/commands/*.md ~/.config/opencode/commands/
```

OpenCode ignores `disable-model-invocation`, so its agent may also load these skills on
its own. To be asked first, set `"permission": {"skill": {"*": "allow", "plan-to-issues": "ask", ...}}`
in `opencode.json`.

## Credits and license

The planning, domain-docs, test-first and two-axis review methods are adapted from
[mattpocock/skills](https://github.com/mattpocock/skills) (MIT, © Matt Pocock); each
adapted skill carries a `NOTICE.md` with that license. Everything else: [MIT](LICENSE).
