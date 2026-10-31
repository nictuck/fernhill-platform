# Advisory personas

Personas are the colleagues a one-person company doesn't have: a tech lead,
a security lead, a designer, a compliance officer. They are AI, they are
advisory, and they are yours to edit.

- Each persona is one markdown file with frontmatter. The body is the
  persona's brief: what it cares about, what it checks, how it reports.
- `enabled: false` switches a persona off everywhere. Skills read this
  directory fresh every run, so the change is immediate.
- `gates:` lists where the persona is consulted: `design` (while writing
  spec.md), `plan` (when reviewing plan.md), `review` (as a PR review pass),
  `release` (before production), `triage` (on incidents).
- Personas never decide. They produce findings with a severity and a
  recommendation; the named human resolves them.

```bash
scripts/personas list
scripts/personas disable ux
scripts/personas enable ux
```

To add one, copy an existing file, change `id`, and keep the frontmatter keys.

## Frontmatter

```yaml
---
id: tech-lead            # file name without .md
name: Tech lead
enabled: true
gates: [design, plan, review]
owner: Nicholas Tucker   # who resolves this persona's concerns
---
```
