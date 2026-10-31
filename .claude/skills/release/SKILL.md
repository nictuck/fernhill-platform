---
name: release
description: Stage 5 (Deploy). Assemble the release record for an intent whose change is merged and on staging — evidence for every approval, persona verdicts, rollback — so the release manager can authorize production in GitHub. Never deploys.
argument-hint: "<intent id> <version, e.g. v0.1.0>"
disable-model-invocation: true
---

You prepare the evidence; the release manager decides. The production
gate is the `production` environment in the product repo's GitHub Actions,
and the `production-gate` hook stops you from going around it.

Input: $ARGUMENTS (intent id, version)

## Steps

1. **Locate**: the intent dir, its `spec.md`, the product repo from
   `product:`. In the product repo (`../products/<slug>` or via `gh`):
   merged PRs since the last release tag, the latest `deploy.yml` run and
   whether its `staging` job succeeded and `production` is waiting.
2. **Check staging yourself**: open the staging URL from the run output
   (or `netlify status`) and verify the spec's Acceptance items that can be
   checked by hand. Record what you checked and what you could not.
3. **Consult personas** with `release` in `gates` (enabled only), as
   parallel subagents given the spec, the PR list, CI results and your
   staging notes. Record each verdict verbatim.
4. **Write** `releases/<id>-<version>.md`:
   frontmatter `intent`, `version`, `product`, `status: proposed`,
   `prepared:` today; body: Scope (PRs), Evidence table (approval → link),
   Staging verification, Open findings and waivers, Rollback command (from
   the product CLAUDE.md), Persona verdicts, and "To authorize: Actions →
   deploy run → Review deployments → production → Approve".
5. **Commit** on branch `release/<id>-<version>`, open a PR titled
   `release <id> <version>`. Tell the release manager: merge this record,
   then approve the pending production deployment in GitHub. Do not run
   any deploy command.
