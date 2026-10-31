# Process exceptions

A gate belongs to a named human. When the product owner decides to delegate
one — for a while, for a reason — the delegation is written here, merged
by that human (the merge is the signature), read by the hooks, and shown
on the dashboard. Nothing is delegated by conversation alone.

- One file per exception: `EX-NNN-slug.md`, sequential, never reused.
- `status: proposed` on the branch; the authorizing human sets `active`
  and merges. CI refuses `proposed` on `main`. Revoke by setting
  `revoked` in a PR; expiry is automatic by date.
- `grants` names what the agent may do. Hooks honor only what is listed:
  `merge` lets `gh pr merge` through when the merge body names the
  exception id, so every merge commit records which exception allowed it.
- Hooks read the exception from the platform's `origin/main`, never from a
  working tree or branch, so a fake exception on a branch grants nothing.
  A revocation takes effect at the next fetch.
- Exceptions never cover: status flips on `intent.md` / `spec.md` (gates 1
  and 2), production approval (gate 5), pushes to `main` or `production`,
  or PRs that change the guardrails themselves (`.claude/`, hooks,
  workflows, `exceptions/`, `CODEOWNERS`, branch protection).

```yaml
---
id: EX-001
title: Short description
status: proposed        # proposed | active | expired | revoked
grants: [merge]
repos: [fernhill-platform, fernhill-product-template, fernhill-flow]
authorized_by: Nicholas Tucker
role: product owner, code owner
granted: 2026-10-31
expires: 2026-11-30
---
```

Body: **Why**, **Conditions** (what must be true before the grant is used),
**Evidence** (what each use leaves behind), **Ends when**.
