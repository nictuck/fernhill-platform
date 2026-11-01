---
intent: "0001"
status: proposed
personas: [compliance, security-lead, tech-lead, ux]
flagged: 0
---

## Summary

Fernhill Flow is a read-only web dashboard that derives, from git and
GitHub alone, where every Fernhill idea is in the six-stage loop, whether
it is moving, waiting on a person, or stuck, and what that person must do
next. It lives in its own product repo (`fernhill-flow`), deploys like
every other product, and appears on its own board as intent 0001. It
writes nothing to GitHub; every action is a deep link to the place the
human already does it. `main` is the only trusted source; PR content is
displayed, never trusted.

## Requirements

Each requirement is pass/fail. "Intent" means a directory under
`intent/` on the platform's `main`, or an open same-repo PR that adds one.

- **R1 Board.** The home screen shows every intent exactly once, placed in
  Plan, Design, Build, Test, Deploy, Maintain or Done by the rules in
  `docs/flow.md` → *Stage state machine*. Done holds intents whose
  `status: done` was set within the last `board.done_days` (30) days,
  newest first, with a "Done: N older → Archive" footer; after that, and
  for `parked` and `rejected` at any age, the intent is in Archive only.
- **R2 State, flag and next action.** Every card shows one **state** —
  *Waiting on ‹role›*, *In progress*, *Live*, or *Done* — the days since
  the stage clock started (defined per stage in flow.md), a **Stuck** flag
  when a threshold is exceeded ("Waiting on product owner for 6 days ·
  stuck, limit 3"), and, when a person must act, one action line with a
  link to the exact page where it is done. Commands the person must run
  (`/design 0001`) are shown as copyable text with a *View intent* link,
  not as a link pretending to run them.
- **R3 Stuck.** Stuck is derived only from `flow.config.json` →
  `thresholds` (one key per condition, listed in flow.md), read at refresh
  time. Changing a threshold changes the board on the next refresh with
  no deploy. A test asserts every threshold key is used by the engine and
  every engine condition has a key.
- **R4 Needs you.** Above the board: "Needs you (N)" grouped by role
  (product owner, engineer, code owner, release manager, on-call), stuck
  items first, then oldest; empty role groups are hidden; the count is in
  the document title ("Flow (3)"). CI-red PRs route to the engineer. When
  nothing waits: "Nothing is waiting on you. 2 in progress, 0 stuck."
- **R5 Intent detail.** Clicking an intent shows its timeline: each
  artifact and gate with who (GitHub login or display name — never an
  email) and when, open and merged PRs with CI status, plan files,
  release runs and approvals, incidents (with `reason` on dismissed ones,
  or "no reason recorded"), and the current stuck analysis. Every entry
  links to its source. Active exceptions in effect at merge time are
  shown on the merge entry.
- **R6 Stage detail.** Expanding a stage header (`/?stage=design`) shows
  the intents in it with each one's time-in-stage and the stuck count.
  Median/max statistics appear only once five or more intents have passed
  through the stage.
- **R7 Systems.** A view per repo: staging URL and the commit it serves,
  production URL and the commit it serves, the `production` branch head,
  and a plain-language line — "Production matches staging", "Production
  is 3 commits behind staging (since 28 Oct)", or "Rollback in effect:
  production serves ‹sha›, branch is at ‹sha›" — plus the last `release`
  run (status, pending approval), `main` CI status, open incidents, open
  PRs. The platform repo appears as the company front door. Active
  exceptions are listed here and on the Board.
- **R8 Freshness.** Every screen shows the snapshot age. A snapshot older
  than `refresh.interval_minutes` triggers a background refresh when the
  page is opened (stale-while-revalidate); *Refresh* triggers one on
  demand. The previous snapshot stays visible while refreshing, labelled
  "Showing snapshot from 3 min ago · refreshing…". A snapshot older than
  3× the interval shows the *stale* state.
- **R9 States of the UI.** Each screen has loading, empty, error and
  stale states with the copy in *Design → UI state copy*. No status is
  conveyed by color alone.
- **R10 Read-only.** No write to GitHub. The only Netlify write is the
  dashboard's own snapshot in Blobs. The GitHub token is a fine-grained
  PAT with exactly Metadata, Contents, Pull requests, Actions and
  Deployments: read, on *Selected repositories* only, expiring in ≤ 90
  days, set only in the `production` and `main` branch-deploy contexts of
  Netlify (deploy previews and `dev` get none), and never sent to the
  browser. Logs never contain request objects or headers.
- **R11 Derivation engine is pure and tested.** Stage, state, stuck,
  waiting-on and the action link are computed by pure, dependency-free
  functions from a snapshot. One fixture per flow.md state-machine row,
  one per threshold (at-threshold negative and over-threshold positive),
  named after the row or condition. Fixture 0 is a real snapshot captured
  from the live repos.
- **R12 Form factor.** Usable at 375 px and on a wide monitor per the
  phone layout in *Design*; keyboard-navigable (a smoke test tabs to every
  card's action link); readable in light and dark.
- **R13 Archive.** Every `done`, `parked` and `rejected` intent (including
  those still in the Done column) with its final status, when it was set,
  and by whom.
- **R14 Ships through the loop.** This product passes gates 1 (done:
  intent accepted 2026-10-31), 2 (this spec), 3–5 in `fernhill-flow`, each
  leaving the evidence flow.md names. Its first production release is
  gate-5 approved; rollback is rehearsed on staging first (publish the
  previous deploy; the board still renders; `version.txt` shows the old
  sha).
- **R15 API budget is measured, not guessed.** Plan step 1 runs the
  collector against the real repos and records the call count as the
  baseline; the refresh log carries calls, duration and
  `x-ratelimit-remaining`; a refresh that doubles the baseline logs a
  warning. Collection uses branch-name classification first and
  files-changed only as a fallback, one tree fetch per repo, and
  conditional requests.
- **R16 Config-driven.** Repos and their sites, the owner, all
  thresholds and the Done window come from the platform's `flow.config.json` on `main`
  (schema in *Design*). Deploy-time configuration is exactly
  `PLATFORM_REPO` and `GITHUB_TOKEN`. The engine is the only place the
  state machine is encoded; flow.md is its human-readable statement.
- **R17 Refresh is abuse-resistant.** `POST /api/refresh` returns the
  current snapshot without touching GitHub when it is younger than
  `refresh.floor_seconds` (60); concurrent refreshes coalesce through a
  single-flight lock in Blobs; the route requires the header
  `X-Flow-Refresh: 1` (so cross-site POSTs fail at preflight); each call
  logs trigger (`page` | `manual`), caller IP, outcome (`stored` |
  `kept-previous` + error), call count, duration and snapshot time. There
  is no scheduled function.
- **R18 Trust rule.** `main` is trusted; PR content is display-only.
  Every frontmatter is parsed with a safe YAML loader and validated
  against a schema (status enums, `^\d{4}$` ids, `^[a-z0-9-]{1,100}$`
  for `product` and site slugs, a 64 KB cap per file). Only `main`
  decides which repos and sites are fetched. Build/fix PRs count only
  when head repo = base repo (no forks). `version.txt` must match
  `^[0-9a-f]{40}$`. All strings render as text; the UI emits only links
  the function constructed under `https://github.com/<owner>/` and the
  configured sites.
- **R19 Outbound calls are bounded.** Every fetch has a 5 s timeout, the
  refresh has a total budget under the function limit (or runs as a
  background function), destinations are exactly `api.github.com` and
  `https://[main--]<site>.netlify.app/version.txt` with `<site>` from
  config on `main`, and response bodies are size-capped before parsing.

## Design

### Shape

```
Browser (static SPA) ──GET /api/flow──────▶ Function: flow
                                              │ serves snapshot for this CONTEXT from Blobs;
                                              │ if older than interval → background refresh
                     ──POST /api/refresh───▶ Function: refresh  (X-Flow-Refresh: 1)
                       (also called by flow)   │ floor + single-flight → GitHub REST (read-only PAT)
                                               │ → collect → validate → derive → store snapshot
```

- **Static SPA** (Vite + React + TypeScript). Single user, read-only, no
  login; the page holds no secrets.
- **Two Netlify Functions** (TypeScript): `flow` and `refresh`; `flow`
  imports the refresh module directly for stale-while-revalidate rather
  than calling the public route. No scheduled function: one viewer does
  not need 144 refreshes a day of a board nobody is watching.
- **Netlify Blobs**, keyed by `process.env.CONTEXT` (`production`,
  `branch-deploy`, `deploy-preview`), holds `latest.json` and
  `previous.json` plus the single-flight lock. Each snapshot carries
  `schemaVersion`; `flow` treats a mismatch as "no snapshot, refresh
  needed", so a code rollback is one click and never reads a newer shape.
- **Derivation engine**: a pure TypeScript module shared by the function
  and the tests; the only encoding of the state machine; thresholds come
  in with the snapshot.

### Decisions recorded

| Decision | Reason | Alternative rejected |
|----------|--------|----------------------|
| Stale-while-revalidate instead of a 10-min schedule | Same freshness when someone looks; zero cost otherwise; one fewer writer to the blob | Scheduled function: runs only on the published deploy, so staging would need the on-demand path anyway |
| Keep a public `/api/refresh` with floor + lock + header | Staging needs an on-demand path for R8 acceptance; the floor caps worst-case GitHub spend at 60 calls/min | Scheduled-only: cannot refresh staging; shared secret: more config for little gain |
| Token only in `production` and `main` branch-deploy contexts | Deploy previews build fork PRs of a public repo; a preview with the token is a token exfiltration path | Token in all contexts: previews render live data but leak risk is unacceptable |
| Blobs keyed by context + `schemaVersion` | Staging tests must not write production's board; rollback must not read a newer schema | One shared store: simpler, breaks R8 acceptance and rollback |
| `version.txt` is the liveness source; GitHub deployments give the gate-5 approver | flow.md's deploy model promises `version.txt`, not a GitHub `staging` deployment | GitHub deployments for liveness: not guaranteed to exist |
| Unit of evaluation is the latest build PR per intent | Earlier merged PRs would otherwise hide a red later PR | "Any PR merged" semantics |
| Incidents attach to the product, one Needs-you row each | Three Maintain intents on one product must not list one incident three times | Incident per intent |

### Data sources and collection

| Source | What is read | Used for |
|--------|--------------|----------|
| platform `main` (one tree fetch, then blobs) | `flow.config.json`, `intent/*/intent.md`, `intent/*/spec.md`, `incidents/*.md`, `releases/*.md`, `exceptions/*.md`, `personas/*.md` (frontmatter only) | intents, statuses, thresholds, repos and sites, incidents, active exceptions, personas on/off |
| platform PRs (open + merged, 90 days) | branch name; files only when the branch does not match `intent/NNNN-*`, `design/NNNN-*`, `incident/*`, `release/*`; state; checks; merged by/at | which intent/spec/incident/release PR is open or landed; gate 1/2 evidence |
| platform commits touching an intent dir | login, date | who accepted what, when |
| each product repo from `flow.config.json` → `repos[]` | `.sdlc.yaml`, `plan/*.md` frontmatter, PRs (`build/NNNN-*`, `fix/*`, same-repo only) + checks, `release` runs + jobs + pending deployments, `production` deployments (approver), `main` and `production` heads | Build/Test/Deploy stages, gate 3–5 evidence |
| each site | `https://main--<site>.netlify.app/version.txt`, `https://<site>.netlify.app/version.txt` | what staging and production serve (public, no auth) |

PR classes: `intent`, `spec`, `incident`, `release`, `build`, `fix`,
`permission` (touches `.claude/`, `.github/`, `exceptions/`, `CODEOWNERS`,
`REVIEW.md`, `personas/`), `docs`. The `permission` class is shown so the
Security pass is visible.

### `flow.config.json` schema (read by the engine)

```json
{
  "github_owner": "nictuck",
  "platform_repo": "fernhill-platform",
  "repos": [ { "name": "fernhill-platform", "site": "fernhillplatform", "kind": "platform" },
             { "name": "fernhill-flow", "site": "fernhill-flow", "kind": "product" } ],
  "thresholds": {
    "plan.pr_open_days": 3, "design.no_spec_pr_days": 5, "design.spec_pr_open_days": 3,
    "build.no_repo_days": 5, "build.no_plan_days": 5, "build.branch_idle_days": 3,
    "test.ci_red_days": 1, "test.review_pending_days": 2,
    "deploy.approval_pending_days": 2, "maintain.untriaged_days": 1
  },
  "refresh": { "interval_minutes": 10, "floor_seconds": 60 },
  "board": { "done_days": 30 }
}
```

`scripts/new-product` appends to `repos[]`; adding a repo also means adding
it to the token's *Selected repositories* — a two-step the runbook and the
R9 "repo not found" copy both say.

### Derivation

The engine implements flow.md's state machine, evaluated Done → Maintain
→ Deploy → Test → Build → Design → Plan on the intent's latest build PR,
taking the first match. Result: `{ intent, stage, state, waitingOn?,
action?, clockStart, days, stuck: boolean, limit? }`. Done's clock is the
commit that set `status: done`; its card shows that date and the days on
the board, and the intent leaves the board once `days > board.done_days`.

| Waiting on | Action copy | Link |
|------------|-------------|------|
| product owner (gate 1) | "Accept or reject intent NNNN" | the intent PR |
| product owner (design not started) | `/design NNNN` (copyable) · *View intent* | the intent directory |
| product owner (gate 2) | "Accept spec NNNN (N concerns open)" | the spec PR |
| product owner (no product repo) | `scripts/new-product ‹slug› --intent NNNN` (copyable) · *View spec* | the spec |
| engineer (plan not started) | `/plan NNNN` (copyable) · *View repo* | the product repo |
| engineer (CI red) | "CI failing on PR #N" | the failing check |
| code owner (gate 4) | "Review and merge PR #N" | the PR |
| release manager (gate 5) | "Approve production for run #N" | the run's review page |
| on-call (gate 6) | "Triage incident ‹slug›" | the incident file or PR |

### Screens (four routes)

| Route | Primary question | Contents |
|-------|------------------|----------|
| `/` Board | What is waiting on me, and is anything stuck? | Needs you (R4); seven stage sections (R1–R3) — six stages plus Done, each header expandable in place (R6); "Done: N older → Archive" footer; active exceptions banner; freshness strip (R8) |
| `/intent/NNNN` | Where is this idea and what happened to it? | header (title, stage, state, action); timeline (R5) |
| `/systems` | What is running where, and is production behind? | per-repo table or cards (R7); exceptions |
| `/archive` | What did we decide not to do, or finish? | R13 |

Top bar: Board · Systems · Archive · freshness strip. "← Board" on Intent
and Systems. Status badges always pair a label with the color.

**Phone layout (≤ 600 px).** Board = Needs you, then stages as stacked
sections; empty stages collapse to a one-line header with a count, and
Done is collapsed to its header and count by default.
Systems = one card per repo with staging and production as two rows.

**The card.** Title · stage · state line ("Waiting on product owner for
6 days · stuck, limit 3" / "In progress · 2 days" / "Live since 12 Oct ·
no open incidents" / "Done 12 Oct · 18 days on board") · action line with
link or copyable command (none on Done cards).

### UI state copy

| State | Copy |
|-------|------|
| Empty board | "No intents yet. Run `/intent` in fernhill-platform to write the first one." |
| Empty systems | "No product repos yet. `scripts/new-product` adds one." |
| Nothing waits | "Nothing is waiting on you. 2 in progress, 0 stuck." |
| Refreshing | "Showing snapshot from 3 min ago · refreshing…" |
| Stale | "Stale — last refresh 2 h ago. Refresh now. If it fails, check the function log and the token expiry." |
| Refresh failed | "Refresh failed at 14:02 (GitHub 502). Showing the snapshot from 13:50." |
| Token invalid/expired | "GitHub rejected the token. Rotate `GITHUB_TOKEN` in Netlify → Site configuration → Environment variables, then Refresh." |
| Rate limited | "GitHub rate limit reached; resets at 15:00. Showing the snapshot from 14:10." |
| Repo not found | "`fernhill-x` is in flow.config.json but the token cannot see it. Add it to the token's selected repositories." |
| No token (preview/dev) | "This deploy has no GitHub token; showing fixture data." |

### Mock before build

The plan's step 0 produces a static HTML mock (checked into
`fernhill-flow/docs/mock/`) of: the card in each state, light and dark;
Board at 375 and 1440 populated and with "nothing waits"; one Needs-you
row; the freshness strip in four states; one error screen and the empty
board; Systems at both widths; one timeline entry. The UX persona reviews
the mock at the plan gate.

### Testing

- Engine: Vitest fixtures under `tests/fixtures/`, one per state-machine
  row and per threshold (at and over), plus fixture 0 captured from the
  real repos; a coverage test ties config keys to engine conditions (R3).
- Functions: unit tests with recorded GitHub responses; schema-rejection
  tests for malformed frontmatter and `version.txt` (R18); timeout and
  size-cap tests (R19); floor and single-flight tests (R17).
- UI: a smoke test renders every screen in loading, empty, error, stale
  and populated states (R9) and tabs through the board (R12).
- Manual on staging before release: R2 links resolve; R12 at 375 px; R8
  refresh; rollback rehearsal (R14).

### Dependencies

Lockfile committed; `npm ci` in CI and in the Netlify build; exact
versions; `ignore-scripts=true` in `.npmrc` (verify the Vite/esbuild
build still passes); Dependabot on. Named additions: `yaml` (frontmatter
parsing of untrusted input), `@netlify/blobs`, `@netlify/functions`,
`vitest`, `eslint`. No other runtime dependency without a PR note.

### Deployment, secrets and operations

Standard product pipeline (`main` → staging; `production` branch after
gate 5). `make build` runs Vite and writes `version.txt`; `make test`
Vitest; `make lint` ESLint + `tsc --noEmit`; `make dev` `netlify dev`
with no token (fixture data).

Secrets inventory (copied into the product's CLAUDE.md):

| Secret | Where | Contexts | Permissions | Repos | Expiry | Rotation |
|--------|-------|----------|-------------|-------|--------|----------|
| `GITHUB_TOKEN` | Netlify env var | `production`, `main` branch-deploy | Metadata, Contents, Pull requests, Actions, Deployments: read | selected: platform + products | ≤ 90 days | release manager; recorded in `releases/` before the change |

Rollback: fast — publish the previous deploy in Netlify; the board still
renders because the snapshot schema is versioned and keyed by context;
then `POST /api/refresh`. Durable — revert PR on `main`, released through
gate 5. Rehearsed on staging before the first production release (R14).

The refresh log line: trigger, IP, outcome, calls, duration,
`x-ratelimit-remaining`, snapshot time. The R15 baseline and the token's
permissions page (as text, never the one-time reveal) go in the release
record.

## Out of scope

- Taking gate actions from the dashboard; v1 links out.
- Multi-user accounts, login, per-user views.
- Netlify API integration; `version.txt` is enough.
- Notifications (Slack, email, push).
- Historical analytics beyond git/GitHub timestamps; DORA reporting.
- Editing artifacts, running skills, any write path.
- Repos outside the configured owner; private repos (all Fernhill repos
  are public; if one becomes private, the snapshot becomes a publication
  of private data and needs a new intent).

## Flagged concerns

Four personas were consulted; their 25 Important findings consolidate
into the nine below. Each had a proposed resolution drafted into this
spec; the product owner decided all nine on 2026-11-01 — eight as
proposed, the Done column changed.

- [x] **tech-lead, ux**: the state vocabulary was untestable — *Stuck* as
  a peer of *Waiting on* lost the "who", *In progress* was undefined, no
  stage clock was defined, and shipped products sat as "In progress"
  forever. — *owner:* Nicholas Tucker — *proposed:* states are Waiting on
  / In progress / Live / Done with Stuck as a flag; per-stage clock start
  defined; flow.md state machine amended in this PR — *resolution:* as
  proposed; flow.md § Stage state machine amended in this PR (2026-11-01)
- [x] **tech-lead**: flow.md's state machine had holes the engine cannot
  implement literally: accepted spec with no product repo matched no row;
  Test waited on CI only (a green, unreviewed PR was never stuck);
  one-PR-per-intent assumption; incidents per intent duplicated Needs-you
  rows. — *owner:* Nicholas Tucker — *proposed:* Build pre-row for "no
  repo"; Test waits on CI then code owner with `test.review_pending_days`;
  latest build PR is the unit; incidents attach to the product; amended in
  flow.md in this PR — *resolution:* as proposed; amended in flow.md in
  this PR (2026-11-01)
- [x] **ux**: Done was a seventh column that grows forever. — *owner:*
  Nicholas Tucker — *proposed:* done leaves the board as a count linking
  to Archive; flow.md amended — *resolution:* **changed** — Done stays on
  the board as a seventh column for `board.done_days` (30) days after
  `status: done`, then drops to Archive; `parked` and `rejected` go
  straight to Archive. R1, R13, R16, the config schema, Screens, the card
  and flow.md updated accordingly (2026-11-01)
- [x] **security-lead, tech-lead** (decision 1): `POST /api/refresh` was
  public and unthrottled; ~85 requests/hour would exhaust the account's
  shared GitHub rate limit. — *owner:* Nicholas Tucker — *proposed:* keep
  it with a 60 s floor, single-flight lock, `X-Flow-Refresh` header and
  per-call log (R17); no scheduled function, stale-while-revalidate
  instead — *resolution:* as proposed; R17 stands (2026-11-01)
- [x] **security-lead** (decision 2): the token was available to deploy
  previews, i.e. to fork PRs of a public repo. — *owner:* Nicholas Tucker
  — *proposed:* token only in `production` and `main` branch-deploy
  contexts; previews and `dev` render fixture data (R10) —
  *resolution:* as proposed; R10 stands (2026-11-01)
- [x] **security-lead** (decision 3): PR content and config values were
  trusted inputs (fork PRs could place intents, choose repos and sites).
  — *owner:* Nicholas Tucker — *proposed:* the trust rule in R18: `main`
  trusted, PR content display-only, same-repo PRs only, schema validation
  everywhere — *resolution:* as proposed; R18 stands (2026-11-01)
- [x] **security-lead** (decision 4), **compliance**: the token had no
  permission list, expiry or rotation owner, and deploy-time config
  changes left no record. — *owner:* Nicholas Tucker — *proposed:* exact
  permissions and ≤ 90-day expiry in R10; secrets inventory table;
  changes recorded in `releases/` first (compliance approval list already
  extended) — *resolution:* as proposed — 90-day expiry, the product
  owner rotates; R10 and the secrets inventory stand (2026-11-01)
- [x] **security-lead, tech-lead, compliance**: one Blobs store shared by
  staging and production, no schema version, no rollback rehearsal — a
  staging test would write production's board and a rollback would read a
  newer snapshot. — *owner:* Nicholas Tucker — *proposed:* store keyed by
  context, `schemaVersion`, rollback paragraph and R14 rehearsal row —
  *resolution:* as proposed (2026-11-01)
- [x] **ux**: no mock; the card, phone layout and UI-state copy were the
  design and were unwritten. — *owner:* Nicholas Tucker — *proposed:*
  copy table and phone layout added here; a static HTML mock is plan step
  0, reviewed by the UX persona at the plan gate — *resolution:* as
  proposed; the mock is plan step 0 (2026-11-01)

Folded in without a concern (plainly right): R6 statistics cut until
n ≥ 5; R7 shows the `production` branch head and rollback-in-effect; R15
restated as a measured baseline with branch-name classification; R16
config schema; outbound timeouts and pinning (R19); dependency policy;
author emails never stored; `permission` PR class; dismissed-incident
reasons shown; stale state; copyable commands; Needs-you count in the
title; keyboard smoke test; all repos stated public.

## Acceptance

| Requirement | How we know |
|-------------|-------------|
| R1, R2, R3, R11, R13 | Fixture tests pass in CI: one per state-machine row, one per threshold at and over, fixture 0 from the live repos; config↔engine coverage test |
| R4, R5, R6, R7 | Walkthrough on staging against the real repos: each action link opens the right page; recorded in the release record |
| R8 | On staging: open the page with an old snapshot → background refresh; press Refresh → previous snapshot stays visible and the age resets |
| R9, R12 | Smoke tests render every screen state and tab to every action link; screenshots at 375 px and 1440 px, light and dark, on the PR |
| R10 | Code review: no GitHub write calls; token permissions listed as text in the release record; browser network log shows no token; preview deploy shows "no token" state |
| R14 | Release run shows the gate-5 approval; rollback rehearsal on staging recorded in the release record |
| R15 | Plan step 1 records the baseline; the refresh log shows calls and `x-ratelimit-remaining` |
| R16 | Change a threshold in `flow.config.json`; the board changes after refresh with no deploy |
| R17 | Tests: second refresh within 60 s makes zero GitHub calls; two concurrent refreshes produce one collection; a POST without the header is rejected |
| R18 | Tests: malformed frontmatter, a fork PR and a bad `version.txt` are rejected and logged; a crafted PR cannot add a repo or site |
| R19 | Tests: a hanging upstream times out at 5 s; an oversized body is rejected |
