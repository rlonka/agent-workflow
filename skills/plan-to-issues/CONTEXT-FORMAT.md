# CONTEXT.md format

`CONTEXT.md` is the project's domain glossary and nothing else: no implementation details,
no spec, no decisions (those are ADRs).

```md
# {Context name}

{One or two sentences: what this context is and why it exists.}

## Language

**Order**:
A customer's request to buy one or more products.
_Avoid_: purchase, transaction

**Invoice**:
A request for payment sent to a customer after delivery.
_Avoid_: bill, payment request
```

## Rules

- **Be opinionated.** When several words exist for one concept, pick the best one and list
  the others under `_Avoid_`.
- **Keep definitions tight.** One or two sentences; say what it *is*, not what it does.
- **Only project-specific terms.** General programming concepts (timeouts, error types,
  utility patterns) don't belong, even if the project uses them a lot.
- **Group terms under subheadings** when natural clusters emerge; otherwise a flat list.

## One context or several

- **One context (most repos):** a single `CONTEXT.md` at the repo root.
- **Several contexts** (a monorepo where the same word means different things in different
  parts): a root `CONTEXT-MAP.md` lists them and how they relate, and each has its own
  `CONTEXT.md` (and optionally its own `docs/adr/`):

```md
# Context map

## Contexts

- [Ordering](./src/ordering/CONTEXT.md): receives and tracks customer orders
- [Billing](./src/billing/CONTEXT.md): generates invoices and processes payments

## Relationships

- **Ordering → Billing**: Ordering emits `OrderPlaced`; Billing consumes it to invoice
```

If `CONTEXT-MAP.md` exists, find the right context before writing; if it's unclear, ask.
Otherwise use the root `CONTEXT.md`, creating it when the first term is resolved.
