---
name: domain-docs
description: Build and sharpen the project's domain glossary (CONTEXT.md) and architecture decision records (docs/adr/) in conversation with the user. Challenges fuzzy or conflicting terms, stress-tests them with scenarios, checks them against the code and writes them down as they settle. Use when the user wants to work on domain terms, a glossary or ADRs.
disable-model-invocation: true
---

# Domain docs

Work on the project's domain model *with* the user: challenge terms, invent edge cases,
check claims against the code, and write the glossary and decisions down the moment they
settle. Reading `CONTEXT.md` for vocabulary is not this skill; this is for changing it.

- Glossary format and one-vs-several contexts: [CONTEXT-FORMAT.md](CONTEXT-FORMAT.md)
- ADR format and when a decision deserves one: [ADR-FORMAT.md](ADR-FORMAT.md)

Create files lazily, only when there is something to write.

## During the session

- **Challenge against the glossary.** When the user uses a term differently from
  `CONTEXT.md`, say so at once: "The glossary defines X as …, you seem to mean …. Which?"
- **Sharpen fuzzy language.** For vague or overloaded words, propose one precise term:
  "By 'account', do you mean the Slurm account or the billing account?"
- **Stress-test with scenarios.** Invent concrete edge cases that force the boundaries
  between concepts to be precise.
- **Cross-reference the code.** When the user states how something works, check the code.
  On a contradiction, surface it: "The code does X, you said Y. Which is right?"
- **Write inline.** Update `CONTEXT.md` as soon as a term is resolved; don't batch.
- **Offer ADRs sparingly**, only when all three criteria in ADR-FORMAT.md hold.

## When you are done

List the terms added or changed and the ADRs written. Don't commit unless the user asks;
if they do, put the docs on their own branch and open a merge request (GitLab) or pull
request (GitHub), since the default branch is usually protected.

Based on `domain-modeling` from mattpocock/skills (MIT); see [NOTICE.md](NOTICE.md).
