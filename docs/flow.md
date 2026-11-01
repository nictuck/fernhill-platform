# The Fernhill flow

How an idea moves from a sentence to production at Fernhill, and how we know
where it is. This is the contract that the skills, hooks, CI checks and the
Flow dashboard all implement. Change it here first.

Adapted from Anthropic's *AI-native SDLC playbook*
([docs/ai-native-sdlc-playbook.pdf](ai-native-sdlc-playbook.pdf)).

## Principles

1. **Artifacts are the interface between stages.** Each stage ends by
   committing a file; the next stage reads it. No tickets, no handoff docs.
2. **Git is the system of record.** A file on `main` has passed its gate.
   Commit history is the audit trail of who asked, what the agent produced,
   and who approved.
3. **Humans hold every judgment call.** Agents work between gates and never
   pass one. The agent may act up to the production gate and cannot pass it.
4. **Advisory vs deterministic.** Personas and skills *advise*. Hooks, branch
   protection and CI *enforce*. Anything that must always hold is a hook.
5. **Hand-prompted first.** Each stage is kicked off by a person running a
   slash command. Automated handover comes after the loop has run end to
   end a few times.

## Where things live

```
fernhill-platform/                 the company: process, policy, personas, dashboard
  intent/NNNN-slug/intent.md       Stage 1 artifact (Plan)
  intent/NNNN-slug/spec.md         Stage 2 artifact (Design)
  incidents/YYYY-MM-DD-slug.md     Stage 6 records; link to the intent they spawn
  releases/NNNN-vX.Y.Z.md          Stage 5 release records (compliance evidence)
  personas/*.md                    advisory personas (toggle with `enabled:`)
  .claude/skills/*                 /intent /design /plan /triage /new-product
  .claude/hooks/*                  deterministic gates
  REVIEW.md                        PR review policy
  docs/flow.md                     this file

<product>/                         one GitHub repo per product (from fernhill-product-template)
  .sdlc.yaml                       links the repo back to its intents
  plan/NNNN-slug.md                Stage 3 artifact: approved plan for one change
  src/, tests/                     the diff and its tests
  .github/workflows/ci.yml         Stage 4: build / test / lint on every PR
  .github/workflows/release.yml    Stage 5: main = staging; production branch moves after approval
  evals/                           regression evals, one per incident
```

## Artifacts and their headers

Every artifact starts with YAML frontmatter. The dashboard reads only the
frontmatter plus git metadata; the body is for people and agents.

### intent.md

```yaml
---
id: "0001"
title: Flow dashboard
status: proposed        # proposed | accepted | parked | rejected | done
author: Nicholas Tucker
origin: idea            # idea | ticket | incident
product: ""             # repo name once one exists, e.g. fernhill-flow
created: 2026-10-31
---
```

Body sections, in order: **Problem**, **Proposed outcome**, **Affected users
and systems**, **Constraints**, **Open questions**.

### spec.md

```yaml
---
intent: "0001"
status: proposed        # proposed | accepted | superseded
personas: [tech-lead, security-lead, ux, compliance]   # consulted
flagged: 2              # open concerns in "Flagged concerns" section
---
```

Body: **Summary**, **Requirements** (numbered, testable), **Design**,
**Out of scope**, **Flagged concerns** (each with owner and resolution),
**Acceptance** (how we will know it is done).

### plan.md (in the product repo)

```yaml
---
intent: "0001"
status: proposed        # proposed | approved | superseded
approved_by: ""         # set by the engineer when accepting the plan
---
```

Body: **Files that change**, **Order of work**, **Risks** (what could break,
riskiest step, what was rejected), **Proof** (the tests that show it works).

### incidents/YYYY-MM-DD-slug.md

```yaml
---
product: fernhill-flow
severity: sev2           # sev1 | sev2 | sev3
status: open             # open | fix-now | scheduled | dismissed | resolved
intent: ""               # intent id this incident spawned, if any
opened: 2026-11-04
triaged_by: ""
reason: ""               # required when dismissed
---
```

Body: **What happened**, **Impact**, **Diagnosis** (agent-written,
read-only), **Recommendation**, **Follow-up** (the eval added, the band
tuned).

### releases/NNNN-vX.Y.Z.md

Written by `/release` before the release manager approves production:
intent, spec commit, PRs, CI run, staging check, open findings and waivers,
rollback command, persona verdicts. The approval itself is recorded by
GitHub.

## Gates

A gate is passed only by a named human. The mechanism makes the pass
visible and the agent's exclusion deterministic.

| # | Gate | Decider | Mechanism | Evidence |
|---|------|---------|-----------|----------|
| 1 | Intent accepted | Product owner | Flip `status: proposed → accepted`, merge PR to `main` | Merge commit author |
| 2 | Spec accepted | Product owner (tech lead consulted when `flagged > 0`) | Flip `status → accepted`, merge PR | Merge commit |
| 3 | Plan approved | Engineer | Accept in plan mode; set `status: approved`, `approved_by` | plan.md commit |
| 4 | Code owner approval | Code owner (delegable, see Exceptions) | Merge the PR (CI green, review findings addressed) | PR merge; review comment |
| 5 | Release authorized | Release manager | Approve the `production` environment in the `release` workflow; it fast-forwards the `production` branch Netlify publishes | GitHub deployment record (approver, commit) |
| 6 | Incident triage | On-call | Mark incident `fix-now`, `schedule` or `dismiss` (with reason) | incident file commit |

Rules enforced by hooks and CI, not by goodwill:

- CI fails if any `intent.md`/`spec.md` on `main` (or merging into it) has
  `status: proposed`. The product owner must flip the status; that edit is the
  acceptance signature.
- The agent cannot merge, approve, or push to `main` or `production`
  (`no-merge` hook).
- The agent cannot deploy to production (`production-gate` hook locally;
  only the `release` workflow moves `production`, behind the environment's
  required reviewer in GitHub).
- During a `/fix` task the agent cannot edit test files (`protect-tests` hook).
- Code changes without a matching `plan/` update get a warning at commit
  time (`plan-sync` hook).

## Stage state machine

The dashboard derives an intent's **stage**, **state**, **stuck flag** and
**who it is waiting on** from the artifacts. Nobody maintains a board by
hand.

**States.** An intent is in exactly one state: *Waiting on ‹role›* (a
named human must act), *In progress* (an agent, CI or a build is working),
*Live* (in production with no open incident), or *Done*. **Stuck** is a
flag on top of a state, set when the stage's threshold is exceeded; a
stuck intent still says who it is waiting on, and *Needs you* lists it
first. The **clock** restarts when a stage is entered, at the event in the
table. The **unit of evaluation** in Build, Test and Deploy is the
intent's latest build PR (highest number, branch `build/NNNN-*`, same-repo
only); earlier PRs do not count. Incidents attach to a **product**, not an
intent: each open incident is one *Needs you* row under on-call, and every
Maintain card on that product shows the count.

| Stage | Entered when | Clock starts | State / waiting on | Stuck when (threshold key) |
|-------|--------------|--------------|--------------------|----------------------------|
| 1 Plan | PR adding `intent.md` is open | PR opened | Waiting on product owner (gate 1) | open > `plan.pr_open_days` |
| 2 Design | `intent.md` on `main`, `status: accepted`, no accepted `spec.md` on `main` | intent PR merged | no spec PR: waiting on product owner to run `/design`; spec PR open: waiting on product owner (gate 2) | no spec PR after `design.no_spec_pr_days`; spec PR open > `design.spec_pr_open_days` |
| 3 Build | `spec.md` accepted on `main` | spec PR merged | `product: ""`: waiting on product owner to create the repo; no `plan/NNNN-*.md`: waiting on engineer to run `/plan`; plan approved, no PR yet: In progress | no repo after `build.no_repo_days`; no plan after `build.no_plan_days`; build branch idle > `build.branch_idle_days` |
| 4 Test | latest build PR open | PR opened | CI running: In progress; CI red: waiting on engineer; CI green: waiting on code owner (gate 4) | CI red > `test.ci_red_days`; green and unmerged > `test.review_pending_days` |
| 5 Deploy | latest build PR merged, its commit not in `production` | PR merged | staging job running: In progress; `production` environment pending: waiting on release manager (gate 5) | pending approval > `deploy.approval_pending_days`; `release` run failed (no timer) |
| 6 Maintain | merge commit in `production` and served live (`version.txt`) | production deployment | no open incident on the product: Live; open incident: waiting on on-call (gate 6) | incident `open` > `maintain.untriaged_days` |
| Done | `intent.md` `status: done` | the commit that set it | Done | — |

Done intents stay in the Done column for `board.done_days` days (30),
then appear only in Archive; `parked` and `rejected` go straight to
Archive. Thresholds live in `flow.config.json` → `thresholds`, one key per
condition above, so they can be tuned without touching code. Active
exceptions (see Exceptions) are shown on the board.

## Deploy model

Every repo that ships (the platform's front door and each product) is
connected to one Netlify site through Netlify's GitHub integration. No
deploy tokens exist anywhere.

| Branch | Netlify context | URL | Who moves it |
|--------|-----------------|-----|--------------|
| any PR | deploy preview | `deploy-preview-N--<site>.netlify.app` | the author |
| `main` | branch deploy = **staging** | `main--<site>.netlify.app` | code owner, by merging |
| `production` | production | `<site>.netlify.app` | the `release` workflow only, after gate 5 |

- Every build writes `version.txt` containing the commit sha (`COMMIT_REF`
  in `netlify.toml`). The `release` workflow waits for staging to serve the
  sha, then holds at the `production` environment until the release manager
  approves, then fast-forwards `production` and waits for the live site to
  serve the sha. Approver, commit and time are a GitHub deployment record.
- Netlify settings per site (set by a person, once): production branch
  `production`; branch deploys include `main`; deploy previews on.
- **Rollback.** Fast: the release manager publishes a previous deploy in
  Netlify (Deploys → pick one → Publish deploy); the live site and the
  `production` branch then differ until the next release, and the dashboard
  shows both. Durable: a revert PR on `main`, released through gate 5.
  `production` never moves backwards and never force-pushes.
- Re-releasing a specific commit: run the `release` workflow by hand with
  that sha (`workflow_dispatch`); the same approval applies.

## Exceptions

A gate can be delegated to the agent for a bounded time by a file in
[`exceptions/`](../exceptions/), merged by the human who owns the gate.
Hooks read exceptions through the GitHub API from the platform repo's
`main` (repo name hardcoded in the hook), so a delegation exists exactly
when a human merged it and until it expires or is revoked.

Two layers, honestly described: **hooks** run on the agent's machine and
stop an honest agent before it tries, with a reason; **GitHub** is the
backstop that holds regardless — `main` requires a PR and a green check
(admins included), `production` cannot be force-pushed or deleted, and the
`production` environment requires a named reviewer; the release workflow
refuses to run in a repo whose environment has no reviewer. One gap is
real and recorded: on a personal GitHub account a ruleset cannot name the
Actions app as its only bypass actor, so "only the release workflow moves
`production`" is enforced by the hook and by the fact that the agent acts
under the owner's credentials. The durable fix is a separate, low-privilege
GitHub identity for the agent (or an organization account); until then
this is a known, accepted limit. Each use leaves evidence: the `/review` comment on the PR and
the merge commit body naming the exception id.

What can be delegated: gate 4 (`grants: [merge]`), on the conditions in
the exception file — a fresh-context review by the `tech-reviewer`
persona, zero Important findings, green checks, and never for PRs that
change the guardrails themselves (`.claude/`, `.github/`, `exceptions/`,
`CODEOWNERS`, `REVIEW.md`, `personas/`).

What cannot: gates 1, 2 and 5 (status flips and production approval),
gate 3 (plan approval), pushes to `main` or `production`, starting
`release` runs. Those stay with named humans in every configuration.

The dashboard shows active exceptions on the Board, because a board that
hides who is really merging is lying.

## Roles

| Role | Held by | Decides |
|------|---------|---------|
| Originator | anyone | writes the intent in their own words |
| Product owner | Nicholas | gates 1 and 2; whether an intent becomes a product |
| Engineer | Nicholas with Claude Code | gate 3; runs build sessions |
| Code owner | Nicholas (`CODEOWNERS`) | gate 4 |
| Release manager | Nicholas | gate 5 |
| On-call | Nicholas | gate 6 |
| Advisory personas | `personas/*.md` (AI) | nothing — they flag, rank and recommend |

## Automation path

Today every stage is started by a person with a slash command. The order in
which we will automate, once the loop is proven:

1. `claude-code-action` reviews every PR against `REVIEW.md` (needs an
   `ANTHROPIC_API_KEY` secret; enabled per repo with `CLAUDE_REVIEW_ENABLED`).
2. Merging an `intent.md` opens a `spec.md` PR automatically.
3. Merging a `spec.md` opens a plan PR in the product repo.
4. Band breaches in production write incident files and new intents.
