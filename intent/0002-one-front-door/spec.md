---
intent: "0002"
status: accepted
personas: [compliance, security-lead, tech-lead, ux]
flagged: 0
---

## Summary

Fernhill Flow becomes the front door: a person signed in with their own
GitHub identity sees what is waiting on *them* and takes the next action
from the board, and every board action is a commit, pull request or merge
authored by that person, so the evidence and the gates are exactly what
the terminal produces today. The terminal gains the same view through a
`/flow` skill, and every stage skill ends by displaying the next step, so
the hand-off between surfaces is a visible state rather than a thing to
know. Done is measured, not felt: a second person, holding the engineer
role, takes a trivial intent to production with zero out-of-band questions
and zero undisplayed next steps, and the release record carries the count.

## Requirements

Each is pass/fail. "Board" is the Flow dashboard (`fernhill-flow`);
"terminal" is a Claude Code session in a clone of a Fernhill repo.

**Identity and roles**

- **R1 Sign in as yourself.** The board offers *Sign in with GitHub*
  through a GitHub App owned by Fernhill and installed only on the
  configured repos. The sign-in round trip carries a random `state` nonce
  held in a short-lived cookie and checked at the callback; there is no
  `redirect` parameter; callback URLs are the production and `main`
  staging origins only. Signed out, the board is exactly v0.1: read-only,
  no write path. Deploy previews and local dev have no App secrets, show
  the signed-out board, and say "Sign in on the live board: `<url>`".
- **R2 Roles have one machine source.** `flow.config.json` gains `roles`:
  each role in `docs/flow.md` maps to one or more GitHub logins. The Roles
  table in `docs/flow.md` and every `CODEOWNERS` (platform and products)
  are **generated** from `roles` by `scripts/validate-artifacts --write`
  and checked by it otherwise; the collector verifies each product's
  `CODEOWNERS` against `roles` at every refresh and shows drift on Systems.
  Path ownership: `intent/**` → product owner, `plan/**` → engineer,
  `releases/**` → release manager, `incidents/**` → on-call, guardrail
  paths → product owner.
- **R3 The board knows who you are.** Signed in, the header shows your
  login and the roles you hold. A signed-in person who holds no role sees
  one state: "You are not in the Roles table yet. Ask the product owner
  (`<login>`) to add you — how: onboarding.md#roles." Nothing is hidden
  from them; everything that writes is disabled.
- **R4 Needs you is personal.** Signed in, *Needs you* lists only the rows
  whose waiting role you hold; the rest appear under *Needs others*,
  grouped by role. When *Needs you* is empty it names who the loop is
  waiting on: "Nothing waits on you. Waiting on product owner (`nictuck`)
  for #14 · 2 h", linking to that row. Signed out, the section is *Needs
  someone*, grouped by role, with no actions.

**Actions**

- **R5 One primary action per row.** Every Needs-you row carries exactly
  one primary action: a board action (button) when the action is in the
  board set (R6) and the signed-in person holds the role; otherwise the
  exact terminal command with the clone it runs in, to copy, followed by
  a "No clone yet? `git clone <url>` then …" line; or a link. A button
  whose precondition is already known false from the snapshot renders
  disabled with the reason and the next step, never as a click that
  refuses. A row never says "do the thing" without saying how and where.
- **R6 The board set.** From the board a role holder can: **start an
  intent** (any signed-in login; `/new`: title, then the template's
  sections each carrying the template's prompt text and one example, slug
  derived from the title; Problem and Proposed outcome required, the rest
  optional; commits `intent/NNNN-slug/intent.md` on branch
  `intent/NNNN-slug` and opens the gate-1 PR with the standard body —
  byte-identical to what `/intent` produces); **decide an intent** (product
  owner, gate 1: accept, park or reject — one click commits the status
  flip on the PR branch and enables GitHub auto-merge (squash), so GitHub
  merges when `check` is green and the person never polls); **accept a
  spec** (product owner, gate 2: same, allowed only when `flagged: 0`);
  **approve a plan** (engineer, gate 3: `status: approved`,
  `approved_by: <their name>` committed on the build branch); **merge a
  reviewed build PR** (code owner, gate 4: squash merge once checks are
  green and the `/review` comment exists; a permission-class PR
  additionally requires the security-lead *clear* in that comment).
  Everything else — resolving flagged concerns, writing plans, triage,
  release records, **and gate 5** — stays a terminal or GitHub action the
  row hands you. Gate 5 is out of the board set in this intent: under
  EX-002 no deployment ever pends, the permission it needs
  (`Deployments: write`) is the App's strongest, and the record-ahead rule
  would need its own precondition; it returns as its own intent when
  EX-002 is revoked.
- **R7 Writes are the person's, and only the person's.** Every board write
  goes to GitHub with the signed-in person's user token; commits carry
  them as author and committer; merges name them. The functions hold no
  write-capable credential of their own: the existing read token stays
  `Contents: read`, the App has **no private key** anywhere (it is used as
  an OAuth client only — client id and secret for the sign-in exchange;
  no installation token is ever minted), and a test asserts that the
  function environment contains no private key and no write-capable PAT
  and that every action path fails closed without a user token.
- **R8 Preconditions are checked on the server from the snapshot and live
  GitHub, and every action is resumable.** Role held for the gate; status
  vocabulary; `check` green before any merge; `flagged: 0` before spec
  acceptance; the target repo is one of `config.repos`; ids and slugs
  match the contract's patterns. `act` fails closed when no snapshot or
  config is readable. A refused action returns a reason from the board's
  own vocabulary (never a GitHub error body) **and** the next step
  ("Refused: 2 concerns still flagged — resolve them: `/design 0002`").
  Multi-call actions detect their own partial state (an existing branch,
  an existing commit, an existing PR) and continue rather than refuse; the
  row shows the partial state meanwhile.
- **R9 What enforces gate ownership.** In this intent the controls are:
  the board's server-side role check (R8), the validator's checks on
  `roles`, the Roles table and `CODEOWNERS` (R2), and CI on every PR.
  GitHub branch protection stays as it is (PR required, `check` required,
  admins enforced) and is the backstop, **not** a required code-owner
  review: with every path owned by the product owner and the agent acting
  under the owner's credentials, a required owner review deadlocks every
  owner-authored PR. This is recorded in `docs/flow.md` as a known gap
  beside the agent-identity one, with the trigger for closing it: when
  EX-002 is revoked and a second human holds the code owner role, enable
  required code-owner review on guardrail paths first.

**Hand-off**

- **R10 The next step is always displayed.** After every board action the
  row re-renders (in an `aria-live` region, focus kept on the replaced
  control) with the new state and next action within one refresh; a
  waiting state names the actor and the clock ("Waiting on `check`
  (running, 1 min) — merges automatically when green"; "Run `/review` in
  your `fernhill-flow` clone · Merge appears when the review comment
  exists"). Every stage skill ends by printing `Next: <who> <does what>
  <where> · board: <url>` from the same copy table the board uses (R11).
- **R11 One copy table, in the platform.** The hand-off copy lives in
  `next-steps.json` beside `flow.config.json`; the engine receives it in
  the snapshot's config, the skills read it locally, and
  `scripts/validate-artifacts` fails when a skill's `Next:` text or the
  engine's fixture output differs from it. A platform skill `/flow`
  prints, for the `gh`-authenticated login, the same Needs-you rows the
  board would show them, with the same commands and links, from a new
  `GET /api/next?login=` endpoint that runs the shipped engine over the
  stored snapshot (milliseconds; `/api/flow`'s caching and `no-store`
  headers). For the fixture, `/flow` output and the board's rows are
  identical (test).
- **R12 Roles and exceptions move together.** Every exception file records
  the **logins** holding the roles it delegates at the time it was granted.
  When the current `roles` differ for any delegated gate, the validator
  fails on `main`, `no-merge.sh` and `release.yml` treat the exception as
  inactive for that gate (both gain the holder check; they are in scope),
  and the Board banner reads "EX-NNN — re-grant needed: `engineer`
  changed · product owner re-grants in `fernhill-platform`". A roles
  change therefore lands only in a PR that also re-grants or revokes every
  exception it touches; the first such PR (adding the engineer) re-grants
  EX-002 for gates 3 and 4 in the same PR, merged by the product owner
  with the new holder's approval recorded on the PR.

**Onboarding and control**

- **R13 Role changes are never delegated.** `roles`, the Roles table and
  `CODEOWNERS` are added to the list of what no exception can delegate
  (`docs/flow.md`, and EX-002 amended by the product owner); such a PR is
  merged by the current holder of the reassigned role, named in the body,
  with collaborator and seat grants listed there. `docs/onboarding.md`
  lists the kit (GitHub account and collaborator access to the configured
  repos, a Claude Code login, a Netlify seat only for the release manager,
  the Roles row), the first ten minutes on each surface including the
  no-clone path, and the trial script (R16). `personas/compliance.md`
  gains three rows: *Role assigned or revoked*, *GitHub App configuration
  change* (permissions, callback URLs, installation; product owner;
  recorded in `releases/` before), *Branch protection change*.
- **R14 Two kill switches.** Instant: suspend the App installation in
  GitHub (server-side, no deploy; the first response to any suspicion).
  Configured: `flow.config.json` `board_actions: true|false`; `false`
  disables every board write at the next refresh, rows degrade to their
  R5 terminal command, and the banner names it. `roles` absent means
  `board_actions: false`.
- **R15 Rollback names three things**, each with its performer and record:
  publish the previous Netlify deploy (release manager; rehearsed on
  production before this release); revert the PR that changed artifacts
  or roles (the role holder, through gate 4); remove a person's access
  (product owner: collaborator removal, App authorization revocation,
  Netlify seat, Claude Code login, and `SESSION_KEY` rotation, which
  signs everyone out) — all in the product `CLAUDE.md`.

**Acceptance**

- **R16 The counted trial.** A named second person, given the kit and
  nothing else, takes a fresh trivial intent through the loop to
  production in `fernhill-flow` with EX-002 active, choosing the board or
  the terminal at each step. Recorded by the baseline rule, per step: the
  surface chosen, time to first action, every moment the next step was
  not displayed (a stall counts whether or not they asked), and every
  out-of-band question. Pass: zero stalls, zero questions, within one
  working day. The plan's step 0 counts 0001's history by the same rule as
  the baseline. Because the trial needs the live board, its evidence lands
  in the release record's `authorized` amendment, and the validator
  refuses `authorized` on 0002's record without baseline, count, surface
  log and the person's name. Gate 5 is outside the trial (R6).

**Security and operations**

- **R17 Session and token handling.** The user token lives only in an
  encrypted, `HttpOnly`, `Secure`, `SameSite=Lax` cookie (Lax, not Strict:
  the cross-site return from GitHub must carry it; CSRF is covered three
  ways below) sealed with AES-GCM: 256-bit `SESSION_KEY`, fresh 96-bit
  random IV per seal, deploy context in the additional data, a distinct
  key per context. **No refresh token**: sessions are hard-limited to the
  App token's eight hours; the App's "expire user authorization tokens"
  setting is on and recorded in the release record. Nothing about a person
  is stored in Blobs, logs or responses beyond login and roles. *Sign out*
  clears the cookie **and** revokes the token at GitHub
  (`DELETE /applications/{client_id}/token`). Every action endpoint is
  `POST`, requires the `X-Flow-Action` header and a double-submit CSRF
  token, checks `Origin` against the site's own origins, caps each
  upstream call at 2.5 s inside the 8 s deadline, and keeps the 1 MiB
  caps. A tampered or expired cookie yields the signed-out board.
- **R18 Audit.** GitHub is the record: each action produces the ordinary
  commit, PR or merge under the person's login. The function also logs
  one line `action=<name> login=<login> target=<repo#n>
  outcome=ok|refused:<reason>` — never a token, never a body — for
  operations only; it is not evidence.
- **R19 Least privilege, recorded first.** The App requests only Metadata
  (read), Contents (write) and Pull requests (write); it is installed on
  the configured repos only; effective rights are the intersection of the
  App's and the person's. Secrets (`GH_APP_CLIENT_ID`,
  `GH_APP_CLIENT_SECRET`, `SESSION_KEY`) exist only as Netlify env vars on
  Production and Branch deploys, set by the release manager **after**
  `releases/0002-v0.2.0.md` exists on platform `main` with
  `status: proposed` (no `commit` yet — the validator does not require
  one) naming key, contexts, who and expiry, and **after** F1 from
  `releases/0001-v0.1.0.md` is closed (platform-site token deleted, PAT
  permissions and expiry attested).
- **R20 Migration.** `SCHEMA_VERSION` becomes 2; a snapshot or config
  without `roles` renders the signed-out board with `board_actions`
  off; fixtures gain the roles and a signed-in derivation; v0.1 bytes on
  `/api/flow` for signed-out clients are unchanged except the schema
  field.

## Design

### Shape

Same product, one more door. The SPA and the two functions of v0.1 stay;
the engine still runs in the browser over the stored snapshot. New Netlify
Functions: `auth-login` (sets the `state` cookie, redirects to GitHub),
`auth-callback` (checks `state`, exchanges the code with client id and
secret, seals the user token into the session cookie), `auth-logout`
(revokes at GitHub, clears), `me` (login and roles from cookie and
config), `act` (POST; one action enum; preconditions, then the GitHub
calls as the person), `next` (GET; Needs-you rows for a login, for
`/flow`). No database: identity travels in the cookie, state is GitHub,
and the snapshot is what it was. Stack unchanged (Vite 8, React 19,
TypeScript 6, Netlify Functions v2, Node 24); sealing uses WebCrypto
AES-GCM, GitHub calls use `fetch`; no new runtime dependency is expected,
and any that is added goes through the review's dependency pass.

Why a GitHub App used as an OAuth client, and not a personal token or a
server-side App identity: installable on exactly two repos, user-to-server
tokens that expire, commits attributed to the person, and GitHub's own
permission model doing the authorization the board mirrors. Why no
server-side write credential and no App private key: the moment one
exists, every public function is a route to `main`; R7 and R9 depend on
there being none.

**Riskiest part, de-risked first (plan step 1):** the App acting as the
second person against branch protection. Create the App, sign in as the
second person on staging, commit one status flip with auto-merge and one
plan approval on scratch PRs, before any UI exists.

### Decisions recorded

Product owner, 2026-11-02 and 2026-11-03:

- The board may act, as the signed-in human. (R6, R7)
- The second person is the **engineer** (gates 3 and 4); the product owner
  keeps gates 1, 2, 5 and 6. (R2)
- The acceptance trial runs with EX-002 active; it measures the seams
  between surfaces, not gate passing. (R16)
- This intent's plan lives in `fernhill-flow` (`product: fernhill-flow`);
  platform changes ship as platform PRs the plan names, `docs/flow.md`
  first.
- flow.md's automation path is out of this intent.
- At gate 2 (2026-11-03): no refresh tokens; gate 5 off the board in this
  intent; no required code-owner review in this intent (known gap with a
  closing trigger); `/new` stays in the first slice, with prompts; the
  trial is recorded by the second person as they go and reviewed by the
  product owner against git timestamps. All 27 flagged concerns resolved
  as proposed.

### Changes to `docs/flow.md`, made first

- Roles table generated from `roles`, with the Engineer row naming the
  second person.
- Gates table, Mechanism column: "from the terminal or the board, as the
  role holder".
- Exceptions: holders (logins) recorded at grant; a roles change suspends
  the exception for the changed gate until re-granted (R12); `roles`, the
  Roles table and `CODEOWNERS` added to "what cannot be delegated" (R13).
- Known gaps: the agent-identity gap (existing) and the no-required-owner-
  review gap (R9), each with its closing trigger.
- Artifacts: `docs/onboarding.md`, `next-steps.json`; `releases/` records
  sign-in secrets and App configuration before they are set.
- Compliance list: *Role assigned or revoked*, *GitHub App configuration
  change*, *Branch protection change*.

### `flow.config.json` additions

```json
"roles": {
  "product_owner": ["nictuck"],
  "engineer": ["nictuck", "<second-login>"],
  "code_owner": ["nictuck", "<second-login>"],
  "release_manager": ["nictuck"],
  "on_call": ["nictuck"]
},
"board_actions": true,
"github_app": { "client_id": "<public id>", "slug": "fernhill-flow" }
```

Role keys are the Roles table's rows in snake case; the validator rejects
unknown keys. Logins that are not collaborators on every configured repo
are reported by the collector at refresh and shown on Systems.

### The action path

1. Browser `POST /api/act` with `{ action, target, payload }`, the
   `X-Flow-Action` header, the CSRF token and the cookie.
2. `act` unseals the cookie (else 401 → signed-out board), checks
   `Origin`, loads the latest snapshot and config (none readable → 503,
   fail closed), and runs the precondition table. Any failure →
   `409 { refused: "<reason>", next: <Action> }`.
3. The GitHub calls, as the person, each resumable: contents API for file
   commits, pulls API for open, auto-merge and merge. Each call ≤ 2.5 s;
   the action ≤ 8 s.
4. `200 { done: "<text>", next: <Action> }`; the browser calls
   `/api/refresh` with trigger `action` so the board re-derives within one
   refresh (R10).

| Action | Role | Preconditions | GitHub calls |
|--------|------|---------------|--------------|
| `intent.start` | any signed-in login | slug matches `^[a-z0-9-]{3,40}$`; next id free, or this login's own branch already exists (resume) | create branch, put `intent.md`, open PR with the standard body |
| `intent.decide` (accept/park/reject) | product_owner | PR open, class intent, `check` green on head | put `intent.md` with the new status on the PR branch; enable auto-merge (squash) |
| `spec.accept` | product_owner | PR open, class spec, `flagged: 0`, `check` green | same, for `spec.md` |
| `plan.approve` | engineer | build PR open, plan `status: proposed` | put the plan with `status: approved`, `approved_by: <name>` |
| `pr.merge` | code_owner | checks green; `/review` comment exists; permission class also needs security-lead *clear* in it | merge (squash) |

### Terminal side

- `/flow` (platform skill): `gh api user` for the login, `GET
  https://<site>/api/next?login=<login>`, prints the rows as
  `· <text> — <command or link>` with the no-clone line where it applies;
  ends with the board URL. Works with no clone of a product repo.
- Every stage skill's last step prints `Next:` from `next-steps.json`.
- `/intent` from the terminal and `intent.start` from the board produce
  the same file, branch and PR body.

### Screens

| Route | Primary question | Change |
|-------|------------------|--------|
| `/` Board | What is waiting on **me**? | header: *Start an idea* · Sign in / `<login> · engineer · Sign out`; *Needs you* (mine, with the who-we-wait-on line when empty) then *Needs others* (by role); each row's primary action per R5; first-run state (R3); *Start an idea* also in the empty-board state |
| `/new` | How do I start an idea? | title; sections with the template's prompt and one example each; slug preview; *Open the PR*; signed out it shows the `/intent` command and the no-clone line |
| `/intent/NNNN` | Where is this idea, and what can I do? | header action becomes a button when R5 says so; disabled-with-reason and refusal-with-next-step inline |
| `/systems` | What is running where? | unchanged, plus the exception re-grant state (R12), a roles row (logins per role, collaborator and `CODEOWNERS` drift) |
| `/archive` | | unchanged |

Phone layout unchanged; action buttons are full width on the card. Every
button pairs a label with the role it exercises ("Accept as product
owner"). Keyboard: the primary action is the row's first focusable
element; re-rendered rows keep focus.

### UI state copy

| State | Copy |
|-------|------|
| Signed out, Needs section | "Needs someone (N)" |
| Signed in, nothing for you | "Nothing waits on you. Waiting on product owner (`nictuck`) for #14 · 2 h" |
| Signed in, no role | "You are not in the Roles table yet. Ask the product owner (`nictuck`) to add you — how: onboarding.md#roles" |
| Row with board action | button "Accept as product owner" · secondary "View PR" |
| Row with terminal action | "Run `/design 0002` in your `fernhill-platform` clone" · copy · "No clone yet? `git clone …` then …" |
| Flip committed | "Waiting on `check` (running, 1 min) — merges automatically when green" |
| Not yet reviewed | "Run `/review` in your `fernhill-flow` clone · Merge appears when the review comment exists" |
| Disabled | "Merge — not yet: `check` is red on #14" |
| Refused | "Refused: 2 concerns still flagged — resolve them: `/design 0002`" |
| Exception suspended | "EX-002 — re-grant needed: `engineer` changed · product owner re-grants in `fernhill-platform`" |
| Kill switch | "Board actions are off (`board_actions: false`) — every row shows its terminal command" |
| Deploy preview | "Preview: read-only. Sign in on the live board: `<url>`" |

### Mock before build

Yes, reviewed by the UX persona before the plan: the engineer view with
empty *Needs you* and populated *Needs others*; a no-clone row; the flip →
waiting → merged sequence; a disabled button and a refusal with next step;
`/new` with section prompts; the terminal `/flow` output and one skill
`Next:` line as text; the suspended-exception banner; all at 375 px and
1440 px.

### Testing

- Engine: `needsYou(rows, snapshot, now, login)` fixtures for each role, a
  login with no role, signed out, and the empty-with-who line; parity test
  between `/api/next` and the board's rows.
- Functions: a fake GitHub for every precondition row (held role, wrong
  role, red `check`, `flagged > 0`, repo outside config, tampered cookie,
  expired cookie, bad `state`, bad `Origin`, missing CSRF, kill switch, no
  snapshot → 503, partial state → resume); a test that the environment
  holds no private key and no write-capable PAT and that `act` fails
  closed without a user token; sealing round-trip, IV uniqueness, AAD
  mismatch, expiry; sign-out revocation call.
- Validator: generated table and `CODEOWNERS` drift, exception holder
  drift (R12), `next-steps.json` vs skills, `authorized` refused without
  trial evidence (R16).
- Hooks and workflow: `no-merge.sh` and `release.yml` treat a
  holder-drifted exception as inactive (self-tests).
- Smoke: every new screen state at 375 px and 1440 px, light and dark.

### Dependencies

None expected beyond the current lockfile; WebCrypto and `fetch` are in
Node 24. The GitHub App is configuration owned by the product owner, with
its own compliance row.

### Deployment, secrets and operations

| Name | Where | Contexts | Value | Expiry / rotation | Who / record |
|------|-------|----------|-------|-------------------|--------------|
| `GITHUB_TOKEN` | Netlify env var | Production, Branch deploys | unchanged: read-only fine-grained PAT | per `releases/0001-v0.1.0.md`, F1 closed first | release manager |
| `GH_APP_CLIENT_ID` | Netlify env var | Production, Branch deploys | the App's client id (public) | n/a | release manager; `releases/0002-v0.2.0.md` before |
| `GH_APP_CLIENT_SECRET` | Netlify env var | Production, Branch deploys | the App's client secret | yearly or on suspicion | same |
| `SESSION_KEY` | Netlify env var, one per context | Production, Branch deploys | 32 random bytes, base64 | rotating signs everyone out | same |

The App: no private key generated; callback URLs = production and `main`
staging origins; "expire user authorization tokens" on; permissions per
R19; installation on the two repos. Operations: first response to any
suspicion is suspending the App installation; second is
`board_actions: false`; third is `SESSION_KEY` rotation.

## Out of scope

- The automation path in `docs/flow.md` (the agent opening spec and plan
  PRs on its own, incidents writing intents).
- Gate 5 from the board (its own intent after EX-002 is revoked).
- Resolving flagged concerns, writing plans or specs, triage and release
  records from the board; those remain terminal commands the board hands
  you.
- Identities other than GitHub; more than one organization; private repos.
- A user store, preferences, notifications, per-user history, refresh
  tokens.
- Required code-owner review on `main` (R9; its own change when EX-002 is
  revoked).
- Netlify API integration.

## Flagged concerns

One entry per Important finding from the design-gate review (posted on
the PR). All resolved by the product owner on 2026-11-03; the design above
reflects each resolution.

**Tech lead**

- [x] **tech-lead**: required code-owner review deadlocks owner-authored PRs — *owner:* Nicholas Tucker — *resolution:* R9 — server check, validator and CI are the control; branch protection unchanged as backstop; known gap with closing trigger — Nicholas Tucker, 2026-11-03
- [x] **tech-lead**: `release.approve` untestable under EX-002 — *owner:* Nicholas Tucker — *resolution:* gate 5 off the board set in this intent, R6 — Nicholas Tucker, 2026-11-03
- [x] **tech-lead**: deployment-review permission unnamed — *owner:* Nicholas Tucker — *resolution:* moot once gate 5 is off the board; R19 names only Metadata, Contents, Pull requests — Nicholas Tucker, 2026-11-03
- [x] **tech-lead**: two-step flip makes the person poll — *owner:* Nicholas Tucker — *resolution:* flip + GitHub auto-merge in one click, R6/R10 — Nicholas Tucker, 2026-11-03
- [x] **tech-lead**: four copies of roles — *owner:* Nicholas Tucker — *resolution:* `roles` the sole source; table and `CODEOWNERS` generated; collector checks products at refresh, R2 — Nicholas Tucker, 2026-11-03
- [x] **tech-lead**: `Next:` copy table cross-repo — *owner:* Nicholas Tucker — *resolution:* `next-steps.json` in the platform, R11 — Nicholas Tucker, 2026-11-03
- [x] **tech-lead**: R12 changes hooks and `release.yml` though Out of scope said otherwise — *owner:* Nicholas Tucker — *resolution:* in scope, holder check in both; first roles PR re-grants EX-002 in the same PR, R12 — Nicholas Tucker, 2026-11-03
- [x] **tech-lead**: no migration or partial-failure story — *owner:* Nicholas Tucker — *resolution:* R20; resumable actions in R8 — Nicholas Tucker, 2026-11-03

**Security lead**

- [x] **security-lead**: OAuth return has no `state`; `SameSite=Strict` drops the cookie on return — *owner:* Nicholas Tucker — *resolution:* `state` cookie checked at callback, session cookie `Lax`, R1/R17 — Nicholas Tucker, 2026-11-03
- [x] **security-lead**: refresh token extends exposure to six months; sign-out revokes nothing — *owner:* Nicholas Tucker — *resolution:* no refresh tokens, hard 8 h sessions, sign-out revokes at GitHub, R17 — Nicholas Tucker, 2026-11-03
- [x] **security-lead**: "no write-capable server credential" only if no App private key exists; installation-token wording wrong — *owner:* Nicholas Tucker — *resolution:* R7 reworded; test asserts no private key and no write PAT — Nicholas Tucker, 2026-11-03
- [x] **security-lead**: `Deployments: write` for one action — *owner:* Nicholas Tucker — *resolution:* gate 5 off the board, R6 — Nicholas Tucker, 2026-11-03
- [x] **security-lead**: `board_actions` in the snapshot is not an instant kill switch; stays on while refresh fails — *owner:* Nicholas Tucker — *resolution:* `act` fails closed without readable config; App suspension is the first response, R8/R14 — Nicholas Tucker, 2026-11-03
- [x] **security-lead**: F1 open — *owner:* Nicholas Tucker — *resolution:* F1 closed before any 0002 secret is set, R19 — Nicholas Tucker, 2026-11-03

**UX**

- [x] **ux**: empty *Needs you* says nothing about who the loop waits on — *owner:* Nicholas Tucker — *resolution:* R4 copy — Nicholas Tucker, 2026-11-03
- [x] **ux**: no first-run state for a person with no clone — *owner:* Nicholas Tucker — *resolution:* no-clone line on every terminal row and in onboarding, R5/R13 — Nicholas Tucker, 2026-11-03
- [x] **ux**: gate 4's hidden precondition (no review yet) has no copy — *owner:* Nicholas Tucker — *resolution:* "Not yet reviewed" state, R10 — Nicholas Tucker, 2026-11-03
- [x] **ux**: refusals are dead ends; known-false preconditions should disable with reason — *owner:* Nicholas Tucker — *resolution:* R5/R8 — Nicholas Tucker, 2026-11-03
- [x] **ux**: flip state names no actor or duration — *owner:* Nicholas Tucker — *resolution:* R10 copy — Nicholas Tucker, 2026-11-03
- [x] **ux**: `/new` has no entry point and blank sections are hostile — *owner:* Nicholas Tucker — *resolution:* *Start an idea* in header and empty state; prompts and examples per section; the tech lead would defer `/new` to a second slice — Nicholas Tucker, 2026-11-03
- [x] **ux**: the trial counts only questions, not stalls; needs an observer who is not the product owner — *owner:* Nicholas Tucker — *resolution:* R16 counts stalls, surfaces and time by rule; recorded by the second person as they go, reviewed against git timestamps by the product owner — Nicholas Tucker, 2026-11-03

**Compliance**

- [x] **compliance**: R9 does not enforce as written; listing both logins on every path lets the engineer approve intent flips — *owner:* Nicholas Tucker — *resolution:* R9 as above; per-path ownership in R2; no required owner review in this intent — Nicholas Tucker, 2026-11-03
- [x] **compliance**: role changes are delegable under `merge-guardrails` — *owner:* Nicholas Tucker — *resolution:* R13 — never delegated; flow.md and EX-002 amended by the product owner — Nicholas Tucker, 2026-11-03
- [x] **compliance**: who merges a re-grant when a gate has two holders — *owner:* Nicholas Tucker — *resolution:* product owner merges with the new holder's approval on the PR, R12 — Nicholas Tucker, 2026-11-03
- [x] **compliance**: `release.approve` ignores record-ahead-of-deployment — *owner:* Nicholas Tucker — *resolution:* gate 5 off the board, R6 — Nicholas Tucker, 2026-11-03
- [x] **compliance**: secrets cannot be recorded before the change in a form the validator accepts — *owner:* Nicholas Tucker — *resolution:* `releases/0002-v0.2.0.md` with `status: proposed` and no `commit` precedes the secrets; F1 closed first, R19 — Nicholas Tucker, 2026-11-03
- [x] **compliance**: trial evidence lands only in the `authorized` amendment — *owner:* Nicholas Tucker — *resolution:* validator refuses `authorized` on 0002 without baseline, count, surface log and name, R16 — Nicholas Tucker, 2026-11-03

## Acceptance

| Requirement | How we know |
|-------------|-------------|
| R1, R3, R4, R17, R20 | Function and UI tests: signed-out `/api/flow` unchanged but for the schema field; `state`, cookie tamper, expiry and preview contexts yield signed-out; sign-out revokes; roles rendering fixtures; CI |
| R2, R9, R12, R13 | `scripts/validate-artifacts` fails on planted drift (generated table, `CODEOWNERS`, exception holders); hook and workflow self-tests treat drifted exceptions as inactive; flow.md lists both known gaps; the three compliance rows exist |
| R5, R6, R8 | Fake-GitHub tests, one per precondition row, pass, refuse and resume; the plan-step-1 spike on staging as the second person; a staging walkthrough by the product owner of every board action, recorded in the release record |
| R7, R19 | Review: no write-capable credential and no App private key in code or env; a test that `act` fails closed without a user token; App permissions, callback URLs and installation listed as text in the release record; `releases/0002-v0.2.0.md` precedes the secrets; F1 closed |
| R10, R11 | Parity test `/api/next` vs board rows; the validator checks skills against `next-steps.json`; `aria-live` and focus in the smoke tests |
| R14 | Suspend the App on staging: every action fails closed; flip `board_actions` on staging: writes refuse at the next refresh |
| R15 | Rollback steps in `CLAUDE.md` with performer and record; publish-previous rehearsed on production before release |
| R16 | The counted trial; the validator refuses `authorized` without its evidence |
| R18 | Function log lines in tests; a staging sample in the release record |
