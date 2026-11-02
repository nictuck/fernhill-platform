# Process exceptions

A gate belongs to a named human. When the product owner decides to delegate
one — for a while, for a reason — the delegation is written here, merged
by that human (the merge is the signature), read by the hooks, and shown
on the dashboard. Nothing is delegated by conversation alone.

- One file per exception: `EX-NNN-slug.md`, sequential, never reused.
- `status: proposed` on the branch; the authorizing human sets `active`
  and merges. CI refuses `proposed` on `main`. Revoke by setting
  `revoked` in a PR; expiry is automatic by date.
- `grants` names what the agent may do. Hooks and CI honor only what is
  listed: `merge` lets `gh pr merge` through when the merge body names the
  exception id, so every merge commit records which exception allowed it;
  `merge-guardrails` extends it to guardrail paths when the body also lists
  the files; `flip-status` and `approve-plan` let the agent sign gates 1–3
  (the signing commit quotes the persona verdicts); `release` lets the
  `release` workflow fast-forward `production` with no required reviewer.
- Hooks read the exception through the GitHub API from
  `nictuck/fernhill-platform` at `main` — the repo name is hardcoded in the
  hook, so nothing in a working tree, a local ref, a branch or the
  environment can supply a fake one. A revocation takes effect immediately.
- Hooks are an honest-agent control: they run on the agent's machine. The
  backstop that holds regardless is GitHub — PR-required branch protection
  on `main`, no force-push or deletion on `production`, and the
  environment's required reviewer (see docs/flow.md → Exceptions for the
  one known gap on personal accounts).
- Exceptions never cover: secrets and tokens, pushes to `main` or
  `production` outside the release workflow, force-pushes, deletions,
  branch protection, or editing and revoking the exceptions themselves.

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
