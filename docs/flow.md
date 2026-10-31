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
  .github/workflows/deploy.yml     Stage 5: staging on merge, production behind a gate
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
| 4 | Code owner approval | Code owner | Merge the PR (CI green, review findings addressed) | PR merge |
| 5 | Release authorized | Release manager | Approve the `production` environment deployment in GitHub | Deployment approval record |
| 6 | Incident triage | On-call | Mark incident `fix-now`, `schedule` or `dismiss` (with reason) | incident file commit |

Rules enforced by hooks and CI, not by goodwill:

- CI fails if any `intent.md`/`spec.md` on `main` (or merging into it) has
  `status: proposed`. The product owner must flip the status; that edit is the
  acceptance signature.
- The agent cannot merge, approve, or push to `main` (`no-merge` hook).
- The agent cannot deploy to production (`production-gate` hook locally;
  `production` environment required reviewer in GitHub).
- During a `/fix` task the agent cannot edit test files (`protect-tests` hook).
- Code changes without a matching `plan/` update get a warning at commit
  time (`plan-sync` hook).

## Stage state machine

The dashboard derives an intent's **stage**, **state** and **who it is
waiting on** from the artifacts. Nobody maintains a board by hand.

| Stage | Entered when | Waiting on | Stuck when |
|-------|--------------|------------|------------|
| 1 Plan | PR adding `intent.md` is open | Product owner (gate 1) | PR open > 3 days |
| 2 Design | `intent.md` on `main`, `status: accepted`, no `spec.md` on `main` | Product owner to run `/design`; then gate 2 | no spec PR within 5 days, or spec PR open > 3 days, or `flagged > 0` on an open spec PR |
| 3 Build | `spec.md` accepted; product repo linked | Engineer to run `/plan`; then build | no `plan/` file within 5 days; branch with no commits for 3 days |
| 4 Test | PR open in product repo | CI | CI red on latest push > 1 day |
| 5 Deploy | PR merged | Staging deploy → release manager (gate 5) | `production` deployment pending approval > 2 days; deploy failed |
| 6 Maintain | Production deployment succeeded | On-call, when an incident file is open | incident `open` and untriaged > 1 day |
| Done | `intent.md` `status: done` | — | — |

`parked` and `rejected` leave the board (shown in an archive view).

Thresholds live in `flow.config.json` so they can be tuned without touching
code.

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
