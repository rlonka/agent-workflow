# ADR format

Architecture decision records live in `docs/adr/` as `0001-slug.md`, `0002-slug.md`, …
(next number = highest existing + 1). Create the directory when the first ADR is needed.

```md
# {Short title of the decision}

{1-3 sentences: the context, what was decided, and why.}
```

An ADR can be a single paragraph. The value is in recording *that* a decision was made and
*why*. Add these only when they carry real information:

- **Status** frontmatter (`proposed | accepted | deprecated | superseded by ADR-NNNN`), when
  a decision gets revisited;
- **Considered options**, when the rejected alternatives are worth remembering;
- **Consequences**, when non-obvious downstream effects need calling out.

## When a decision deserves an ADR

All three must hold:

1. **Hard to reverse:** changing your mind later is expensive.
2. **Surprising without context:** a future reader would ask "why on earth like this?"
3. **A real trade-off:** there were genuine alternatives and one was picked for reasons.

Typical cases: architectural shape; integration patterns between parts; technology choices
with lock-in; boundary and scope decisions (the explicit "no"s too); deliberate deviations
from the obvious path; constraints not visible in the code (compliance, contracts); rejected
alternatives whose rejection isn't obvious.

Never rewrite an accepted ADR to change the decision: write a new one that supersedes it.
