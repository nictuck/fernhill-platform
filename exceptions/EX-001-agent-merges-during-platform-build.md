---
id: EX-001
title: Agent reviews and merges PRs while the platform is being built
status: active
grants: [merge]
repos: [fernhill-platform, fernhill-product-template, fernhill-flow]
authorized_by: Nicholas Tucker
role: product owner, code owner
granted: 2026-10-31
expires: 2026-11-30
---

## Why

While the platform and its first product (intent 0001, the Flow
dashboard) are being built, most PRs are scaffolding that the product
owner has already directed in conversation. Routing each one through a
manual merge puts the one human on the critical path of every change
without adding judgment. Gate 4 is therefore delegated to the agent, on
the conditions below, for the build-out period only.

## Conditions

Before the agent merges a PR it must have:

1. Run `/review` on it: the `tech-reviewer` persona (a fresh subagent that
   did not write the change) runs every REVIEW.md pass; `security-lead`
   joins when the PR touches dependencies, workflows, functions, auth or
   secrets handling; `ux` joins when UI files change.
2. Posted the findings on the PR as a review comment.
3. Confirmed: all checks green; zero Important findings open; the PR is
   not in the *permission* class (anything under `.claude/`, `.github/`,
   `exceptions/`, `CODEOWNERS`, `REVIEW.md`, `personas/` — those stay with
   the human); for `intent.md` / `spec.md` PRs the status has already been
   flipped by the product owner (CI enforces this anyway).

The exception does **not** cover: status flips (gates 1–2), plan approval
(gate 3), production approval (gate 5), pushes to `main` or `production`,
starting `release` runs, or anything outside the listed repos.

## Evidence

- The review comment on the PR, headed `Fernhill review · EX-001`.
- The squash-merge commit body: `Merged under EX-001 after /review: …`.
- The `no-merge` hook's decision, which requires the id in the merge
  command and an active, unexpired exception on the platform's `main`.

## Ends when

Intent 0001 is released to production, or 2026-11-30, or the product
owner sets `status: revoked` — whichever comes first. On ending, gate 4
returns to the code owner with no other change.
