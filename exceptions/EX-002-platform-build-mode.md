---
id: EX-002
title: Platform build mode — the agent passes gates 1, 2, 3 and 5 and merges guardrail changes
status: proposed
grants: [merge, merge-guardrails, flip-status, approve-plan, release]
repos: [fernhill-platform, fernhill-product-template, fernhill-flow]
authorized_by: Nicholas Tucker
role: product owner, engineer, code owner, release manager
granted: 2026-11-02
expires: 2026-11-30
---

## Why

The product owner directed on 2026-11-02: while the platform and its first
product are being built, a human approval on every deployment, plan and
spec change is the critical path of every iteration without adding
judgment — the fresh-context persona reviews are what have been catching
the real defects. For the build-out period the remaining gates are
delegated to the agent, with the reviews kept mandatory and every use
recorded, so the loop can run end to end many times before the gates
return to people. EX-001 stays in force; this exception widens it.

## Grants

| Grant | Gate | What the agent may do |
|-------|------|-----------------------|
| `merge` | 4 | as EX-001 |
| `merge-guardrails` | 4 (permission class) | merge PRs that change `.claude/`, `.github/`, `exceptions/`, `personas/`, `CODEOWNERS`, `REVIEW.md` |
| `flip-status` | 1, 2 | set `status: accepted` on `intent.md` / `spec.md` and merge |
| `approve-plan` | 3 | set `status: approved`, `approved_by: "agent under EX-002"` on a plan |
| `release` | 5 | the `release` workflow fast-forwards `production` without a required reviewer |

## Conditions

1. **Every gate still gets a fresh-context review** before the agent passes
   it: intents and specs by the personas named in `personas/*.md` for the
   `design` gate; plans by `tech-lead`; PRs by `/review` as in EX-001;
   permission-class PRs additionally by `security-lead`, with zero
   Important findings from both. The verdicts are quoted in the commit
   that flips the status or approves the plan.
2. **Permission-class merges name every guardrail file changed** in the
   merge body (`Merged under EX-002 after /review: … · guardrails: …`), so
   the audit trail of edits to the agent's own guardrails is explicit.
3. **Releases are still gated by evidence**: the `release` workflow waits
   for staging to serve the commit, and the fast-forward only happens
   when the platform's `main` holds an active exception granting
   `release`. Rollback stays one click in Netlify (Publish deploy).
4. **Not covered, in any configuration**: secrets and tokens (the human
   sets `GITHUB_TOKEN` and any Netlify or GitHub secret), pushes to `main`
   or `production` outside the release workflow, force-pushes, deleting
   branches or environments, changing branch protection, editing or
   revoking this file or EX-001, and anything outside the listed repos.

## Evidence

- Status flips and plan approvals: the commit body quotes the persona
  verdicts and names `EX-002`; `approved_by` reads `agent under EX-002`.
- Merges: the `/review` comment and the merge body naming `EX-002`.
- Releases: the GitHub deployment record (actor `github-actions`) and the
  workflow log line `release gate: delegated under EX-002`.
- The dashboard shows EX-002 on the Board and on Systems while it is
  active.

## Ends when

Intent 0001 is live and its first incident has been triaged, or
2026-11-30, or the product owner sets `status: revoked` — whichever comes
first. On ending, the required reviewer is restored on each repo's
`production` environment and every gate returns to its named human.
