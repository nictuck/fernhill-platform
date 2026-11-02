---
name: release
description: Stage 5 (Deploy). Assemble the release record for an intent whose change is merged and on staging — evidence for every approval, persona verdicts, rollback — so the release manager can authorize production in GitHub, or, when an exception delegates the gate, so the `release` workflow has the record it refuses to deploy without. Never deploys.
argument-hint: "<intent id> <version, e.g. v0.1.0>"
disable-model-invocation: true
---

You prepare the evidence; the gate decides. When the release manager holds
the gate, they approve the `production` environment in the product repo's
GitHub Actions. When an active exception on the platform's `main` grants
`release`, nobody approves: the `release` workflow fast-forwards
`production` itself, and it refuses to until your record is on the
platform's `main` naming the commit. Either way the `production-gate` hook
stops you from going around the workflow.

Input: $ARGUMENTS (intent id, version)

## Where the record lives and what its status means

The record is `releases/<id>-<version>.md` **in `fernhill-platform`** (this
repo), never in the product repo: `docs/flow.md` ("Where things live") keeps
release records with the other compliance evidence, and
`scripts/validate-artifacts` checks them here. The frontmatter is the
contract the `release` workflow reads under a delegated gate:

```yaml
---
intent: "0001"
version: v0.1.0
product: fernhill-flow            # the product repo's name
status: proposed                  # proposed | authorized | rolled-back
prepared: 2026-11-02
commit: <full 40-hex sha>         # the commit on the product's main being released
released:                         # set with authorized: when production served the commit
release_run:                      # set with authorized: the release workflow run id
authorized_by:                    # set with authorized: the approver, or "delegated under EX-NNN"
---
```

- `proposed` — the record is merged and the gate is not yet passed: a
  human approval is pending, or the workflow is waiting for this record.
- `authorized` — gate 5 passed: `production` serves `commit`. Set in a
  follow-up PR together with `released`, `release_run`, `authorized_by`.
- `rolled-back` — production was moved off `commit` (a previous deploy
  published in Netlify, or a revert released through the gate). Say when,
  to what and why in the body.

## Which path

Read `exceptions/*.md` on the platform's `origin/main`. If one is
`active`, unexpired, lists the product repo and grants `release`, the gate
is **delegated**; otherwise it is **held by the release manager**. The
steps below are the same; the ordering and the last step differ.

## Steps

1. **Locate**: the intent dir, its `spec.md`, the product repo from
   `product:`. In the product repo (`../products/<slug>` or via `gh`):
   merged PRs since the current `production` branch commit, the merge
   commit being released (full sha — this is `commit:`), the latest
   `release` run and whether its `staging` job succeeded.
2. **Check staging yourself**: open the staging URL from the run output
   (`https://main--<site>.netlify.app`) once it serves the commit and
   verify the spec's Acceptance items that can be checked by hand. Record
   what you checked and what you could not. Netlify branch deploys have no
   publish pointer, so a rollback rehearsal cannot happen on staging: the
   release manager does it in Netlify, on production, against the previous
   real deploy (publish it, confirm `version.txt` and the page, re-publish
   the current deploy), at the first release where such a deploy exists;
   the `production-gate` hook keeps you from doing it. Record the result,
   or that it has not been done. Where a spec asks for a staging rehearsal
   (fernhill-flow spec R14), note the mismatch in the record; amending the
   spec is a design-gate change for the product owner, not yours.
3. **Consult personas** with `release` in `gates` (enabled only), as
   parallel subagents given the spec, the PR list, CI results and your
   staging notes. Record each verdict verbatim.
4. **Write** `releases/<id>-<version>.md` with the frontmatter above,
   `status: proposed`, `commit:` the merge sha; body: Scope (PRs), Evidence
   table (approval → link), Staging verification, Open findings and
   waivers, Rollback steps (Netlify publish-previous, then revert PR),
   Persona verdicts, Authorization. Under a delegated gate the first
   paragraph says so: gate 5 is delegated under EX-NNN, no person approves,
   and this record is the evidence the workflow waited for.
5. **Commit** on branch `release/<id>-<version>`, open a PR titled
   `release <id> <version>`, class `release`. Do not run any deploy
   command.

## Held by the release manager (no `release` grant)

The product PR merged, the `release` run passed `staging` and is waiting
for review at `production`. Run the steps, then tell the release manager:
merge this record, then *Actions → the `release` run → Review deployments →
production → Approve*. When production serves the commit, a follow-up PR
sets `status: authorized` with `released`, `release_run` and
`authorized_by: <the approver>`.

## Delegated (an active exception grants `release`)

The workflow is already running the moment the product PR merges, so the
record is written in the same `/review` step that merges it, before
anything else:

1. `/review` merges the product PR (gate 4). `gh pr view N --json
   mergeCommit` gives the sha; that is `commit:`.
2. Run this skill at once (steps 1–5) while the run waits for staging.
3. `/review` the record PR and merge it under the exception
   (`Merged under EX-NNN after /review: …`). The product's `release` run
   polls the platform's `main` for the record for ten minutes after
   staging is live and fast-forwards when it finds one with this repo's
   name in `product:`, this sha in `commit:` and status `proposed` or
   `authorized`. If the run timed out first, merge the record and
   `gh run rerun <run id> --failed`: the hook allows reruns because the
   record check and the environment gate still hold on a rerun, which is
   not true of `gh workflow run` or a dispatch, which it blocks.
4. When the run is green and production serves the commit, a follow-up PR
   sets `status: authorized`, `released`, `release_run` and
   `authorized_by: "delegated under EX-NNN"`.

A record written after the deployment is a gap, not a release record: say
so in its first paragraph and list the gap as a finding, as
`releases/0001-v0.1.0.md` does.
