---
id: "0001"
title: Flow dashboard
status: proposed
author: Nicholas Tucker
origin: idea
product: ""
created: 2026-10-31
---

## Problem

I'm adopting the AI-native SDLC so I can iterate on new product ideas, but
there is nothing that shows me the state of the flow. Once more than one
idea is moving, I can't tell at a glance where each idea is, where it is
stuck, where it is in progress, and where it needs my input. The
information exists — in intent and spec files, PRs, CI runs, deployments —
but it is spread across repos and GitHub pages, and the only way to know
what is waiting on me is to go look everywhere.

## Proposed outcome

A dashboard that shows where ideas are in the flow: which stage each one is
in, which are stuck, which are in progress, and which need input (and from
whom). From the overview I can drill down into each area — a stage, an
idea, a gate — and see the artifacts, the PRs, the checks and the history
behind it.

It should feel like running a real software company: production, source
control, deployment pipelines, and the other things related to building
software at a company are visible in it, so the simulated corporate
environment is something I can watch, not just something that exists in
config.

## Affected users and systems

- Me, as product owner, engineer, code owner, release manager and on-call —
  the dashboard is my to-do list across all those roles.
- `fernhill-platform`: `intent/`, `incidents/`, `releases/`, `personas/`
  are the primary inputs. The dashboard lives in this repo (or a product
  repo it links to — open question).
- Every product repo created from `fernhill-product-template`: plans,
  PRs, CI runs, deployments and environments are read, never written.
- GitHub (source of truth) and Netlify (deploy history).

## Constraints

- Derive state from the artifacts and GitHub; the dashboard must not become
  a second place to maintain status by hand.
- Follow `docs/flow.md`: the stage state machine, the stuck thresholds in
  `flow.config.json`, and the status vocabulary there. Change the doc first
  if the dashboard needs something different.
- Built through this process: this intent → spec → plan → PR → staging →
  release gate. It is the first product to go round the loop.
- Free tier everywhere (GitHub, Netlify); one person operates it.
- Deployed to Netlify like every other Fernhill product.

## Open questions

- ~~Should the dashboard be a product repo (`fernhill-flow`) like everything
  else, or live inside `fernhill-platform`?~~ Answered 2026-10-31: its own
  repo, `fernhill-flow`, with its own Netlify site. `fernhillplatform.netlify.app`
  stays the company front door.
- Read-only, or can gate actions (accept an intent, approve a release) be
  taken from the dashboard? Starting assumption: read-only, deep links to
  GitHub for actions.
- Does it need to know who is logged in, or is it a single-user page with a
  GitHub token?
- What is the simplest refresh model: on page load via the GitHub API, or a
  scheduled job that snapshots state?
- Which drill-downs matter most first: per idea, per stage, or per role
  ("everything waiting on me")?
