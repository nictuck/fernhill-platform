---
intent: "0002"
status: proposed
personas: [compliance, security-lead, tech-lead, ux]
flagged: 0
---

## Summary

Fernhill Flow becomes the front door: a person signed in with their own
GitHub identity sees what is waiting on *them* and takes the next action
from the board, and every board action is a commit, pull request, merge or
deployment review authored by that person, so the evidence and the gates
are exactly what the terminal produces today. The terminal gains the same
view through a `/flow` skill, and every stage skill ends by displaying the
next step, so the hand-off between surfaces is a visible state rather than
a thing to know. Done is measured, not felt: a second person, holding the
engineer role, takes a trivial intent to production with zero questions
asked out of band, and the release record carries the count.

## Requirements

Each is pass/fail. "Board" is the Flow dashboard (`fernhill-flow`);
"terminal" is a Claude Code session in a clone of a Fernhill repo.

**Identity and roles**

- **R1 Sign in as yourself.** The board offers *Sign in with GitHub*
  through a GitHub App owned by Fernhill and installed only on the
  configured repos. Signed out, the board is exactly v0.1: read-only, no
  write path. Sign-in is available on production and staging (`main`)
  only; deploy previews and local dev have no App secrets and show the
  signed-out board.
- **R2 Roles are configuration.** `flow.config.json` gains `roles`: each
  role in `docs/flow.md` maps to one or more GitHub logins. The Roles table
  in `docs/flow.md` and `roles` must agree; `scripts/validate-artifacts`
  fails when they do not. `CODEOWNERS` in the platform and in every product
  repo names the role holder for the artifacts of that role (`intent/**` →
  product owner, `plan/**` → engineer, `releases/**` → release manager,
  `incidents/**` → on-call); the validator checks the platform's file and
  `new-product` writes the product's from `roles`.
- **R3 The board knows who you are.** Signed in, the header shows your
  login and the roles you hold. A signed-in person who holds no role sees
  one state: "You are not in the Roles table yet. Ask the product owner
  (`<login>`) to add you: `<link to onboarding.md#roles>`." Nothing else is
  hidden from them; everything that writes is disabled.
- **R4 Needs you is personal.** Signed in, *Needs you* lists only the rows
  whose waiting role you hold; the rest appear under *Needs others*,
  grouped by role as today. Signed out, the section is *Needs someone*,
  grouped by role, with no actions.

**Actions**

- **R5 One primary action per row.** Every Needs-you row carries exactly
  one primary action: a board action (button) when the action is in the
  board set (R6) and the signed-in person holds the role; otherwise the
  exact terminal command, with the clone it runs in, to copy; or a link.
  A row never says "do the thing" without saying how and where.
- **R6 The board set.** From the board a role holder can: start an intent
  (originator; a form with the template's sections, which commits
  `intent/NNNN-slug/intent.md` on branch `intent/NNNN-slug` and opens the
  gate-1 PR with the standard body); accept, park or reject an intent
  (product owner, gate 1: status flip committed on the PR branch, then
  merge once `check` is green); accept a spec (product owner, gate 2: same,
  allowed only when `flagged: 0`); approve a plan (engineer, gate 3:
  `status: approved`, `approved_by: <their name>` committed on the build
  branch); merge a reviewed build PR (code owner, gate 4: squash merge once
  checks are green and the `/review` comment exists); approve a pending
  production deployment (release manager, gate 5: the GitHub deployment
  review). Everything else — resolving flagged concerns, writing plans,
  triage, releases records — stays a terminal command the row hands you.
- **R7 Writes are the person's.** Every board write goes to GitHub with the
  signed-in person's user token from the App; commits carry them as author
  and committer, merges and deployment reviews name them. The functions
  hold no write-capable server credential: the existing read token stays
  `Contents: read`, and a test proves no action path can run without a user
  token. The App's own installation token is used for nothing but the
  sign-in exchange.
- **R8 Preconditions are checked on the server from the snapshot and live
  GitHub.** Role held for the gate; status vocabulary; `check` green before
  any merge; `flagged: 0` before spec acceptance; the target repo is one of
  `config.repos`; ids and slugs match the contract's patterns. A refused
  action returns the reason, and the board shows it verbatim ("Refused:
  `check` is still running on #13").
- **R9 Gate ownership is enforced by GitHub, not only by the board.** Branch
  protection on `main` of both repos requires review from code owners, so a
  status flip or plan approval merged by someone who does not own the path
  fails at GitHub whether it came from the board, the terminal or `gh`. The
  agent's documented gap (it acts under the owner's credentials) is
  unchanged by this intent and stays listed in `docs/flow.md`.

**Hand-off**

- **R10 The next step is always displayed.** After every board action the
  row re-renders with the new state and next action within one refresh.
  Every stage skill ends by printing `Next: <who> <does what> <where> ·
  board: <url>`; the text is the same text the board shows for that state
  (one copy table, R11).
- **R11 Terminal gains the board.** A platform skill `/flow` prints, for the
  `gh`-authenticated login, the same Needs-you rows the board would show
  them, with the same commands and links, from a new `GET /api/next?login=`
  endpoint that runs the shipped engine over the stored snapshot. For the
  fixture, `/flow` output and the board's Needs-you are identical row for
  row (test).
- **R12 Roles and exceptions move together.** Every exception file records
  the holders of the roles it delegates at the time it was granted. When
  the current `roles` differ for any delegated gate, the validator fails on
  `main`, the exception counts as suspended for that gate (hooks and the
  release workflow treat it as inactive), and the Board banner reads
  "EX-NNN — re-grant needed: `<role>` changed". A roles change therefore
  lands only together with the re-grant or revocation of every exception it
  touches.

**Onboarding and control**

- **R13 The kit is a recorded change.** `docs/onboarding.md` lists the kit
  (GitHub account and collaborator access to the configured repos, a Claude
  Code login, a Netlify seat only for the release manager, the Roles row),
  the first ten minutes on each surface, and the trial script (R16).
  Assigning or revoking a role is a PR that changes `roles`, the Roles
  table and `CODEOWNERS` together, merged by the current holder of that
  role, with the collaborator and seat grants listed in its body;
  `personas/compliance.md` gains the row *Role assigned or revoked*.
- **R14 A kill switch without a deploy.** `flow.config.json` gains
  `board_actions: true|false`; `false` disables every board write at the
  next refresh, leaving sign-in and the personal view intact.
- **R15 Rollback names three things** and the first is rehearsed on
  production before this release: publish the previous Netlify deploy;
  revert the PR that changed artifacts or roles; remove a person's access
  (collaborator removal and App authorization revocation), documented step
  by step in the product `CLAUDE.md`.

**Acceptance**

- **R16 The counted trial.** A named second person, given the kit and
  nothing else, takes a fresh trivial intent through the loop to production
  in `fernhill-flow` with EX-002 active, choosing the board or the terminal
  at each step as they like. Pass: zero questions asked out of band, every
  next step taken from a displayed action or printed `Next:` line, finished
  within one working day. The plan's step 0 counts the seams in 0001's
  history by the same rule (a step whose next action was displayed nowhere)
  as the baseline; the release record carries baseline, trial count and the
  person's name.

**Security and operations**

- **R17 Session and token handling.** The user token and refresh token live
  only in an encrypted, `HttpOnly`, `Secure`, `SameSite=Strict` cookie
  sealed with a server key; nothing about a person is stored in Blobs,
  logs or responses beyond login and roles. Sessions end when the App
  token expires (eight hours) unless refreshed through GitHub; *Sign out*
  clears the cookie. Every action endpoint is `POST`, requires the
  `X-Flow-Action` header and a double-submit CSRF token, checks `Origin`
  against the site's own origins, and keeps the 5 s per-call timeout and
  1 MiB caps. A tampered or expired cookie yields the signed-out board.
- **R18 Audit.** Each action produces the ordinary GitHub evidence under the
  person's login, plus one function log line `action=<name> login=<login>
  target=<repo#n> outcome=ok|refused:<reason>` — never a token, never a
  body.
- **R19 Least privilege.** The App requests only Metadata (read), Contents
  (write), Pull requests (write) and the permission GitHub requires to
  review pending deployments; it is installed on the configured repos only;
  effective rights are the intersection of the App's and the person's.
  Secrets (`GH_APP_ID`, `GH_APP_CLIENT_ID`, `GH_APP_CLIENT_SECRET`,
  `SESSION_KEY`) exist only as Netlify env vars on Production and Branch
  deploys, recorded in `releases/` before they are set.

## Design

### Shape

Same product, one more door. The SPA and the two functions of v0.1 stay;
the engine still runs in the browser over the stored snapshot. New Netlify
Functions: `auth-login` (redirect to GitHub), `auth-callback` (code → user
token, sealed cookie), `auth-logout`, `me` (login and roles from the
cookie and config), `act` (POST; one action enum; preconditions, then the
GitHub calls as the person), `next` (GET; Needs-you rows for a login, for
`/flow`). No database: identity travels in the cookie, state is GitHub,
and the snapshot is what it was. Stack unchanged (Vite 8, React 19,
TypeScript 6, Netlify Functions v2, Node 24); sealing uses WebCrypto
AES-GCM, GitHub calls use `fetch`; no new runtime dependency is expected,
and any that is added goes through the review's dependency pass.

Why a GitHub App and not an OAuth App or a personal token: the App is
installable on exactly two repos, its user-to-server tokens expire, the
commits it makes on a person's behalf are attributed to that person, and
GitHub's own permission model does the authorization the board only
mirrors. Why no server-side write token: the moment one exists, every
public function is a route to `main`; R7 and R9 depend on there being
none.

### Decisions recorded

Product owner, 2026-11-02, at gate 1 and before this spec:

- The board may act, as the signed-in human. (R6, R7)
- The second person is the **engineer** (gates 3 and 4); the product owner
  keeps gates 1, 2, 5 and 6. The Roles table gains one row and `roles`
  names two logins. (R2)
- The acceptance trial runs with EX-002 active; it measures the seams
  between surfaces, not gate passing. (R16)
- This intent's plan lives in `fernhill-flow` (`product: fernhill-flow`);
  platform changes (flow.md, skills, validator, personas, onboarding) ship
  as platform PRs the plan names, in the order the plan gives, with
  `docs/flow.md` first.
- flow.md's automation path (the agent opening spec and plan PRs by itself)
  is out of this intent.

### Changes to `docs/flow.md`, made first

- Roles table: an Engineer row naming the second person; a sentence that
  `roles` in `flow.config.json` is the machine-read copy and the two must
  agree.
- Gates table, Mechanism column: each gate's mechanism gains "from the
  terminal or the board, as the role holder".
- Exceptions: holders recorded at grant; a roles change suspends the
  exception for the changed gate until re-granted (R12).
- Artifacts: `docs/onboarding.md` listed; `releases/` records sign-in
  secrets before they are set.
- A new approval in the compliance list: *Role assigned or revoked*.

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
unknown keys and logins that are not collaborators on every configured
repo (checked by the collector at refresh and shown on Systems).

### The action path

1. Browser `POST /api/act` with `{ action, target, payload }`, the
   `X-Flow-Action` header, the CSRF token and the cookie.
2. `act` unseals the cookie (else 401 → signed-out board), checks `Origin`,
   loads the latest snapshot and config, and runs the precondition table
   below. Any failure → `409 { refused: "<reason>" }`.
3. The GitHub calls, as the person: contents API for file commits (author
   and committer from the token), pulls API for open and merge, actions
   API for the deployment review. Each call keeps the 5 s timeout; the
   whole action the 8 s deadline.
4. `200 { done: "<text>", next: <Action> }`; the browser calls
   `/api/refresh` with trigger `action` so the board re-derives within one
   refresh (R10).

| Action | Role | Preconditions | GitHub calls |
|--------|------|---------------|--------------|
| `intent.start` | originator (any signed-in login) | slug matches `^[a-z0-9-]{3,40}$`; next id is free | create branch, put `intent.md`, open PR with the standard body |
| `intent.decide` (accept/park/reject) | product_owner | PR open, class intent, `check` green on head | put `intent.md` with the new status on the PR branch; merge (squash) when `check` is green on the flip commit |
| `spec.accept` | product_owner | PR open, class spec, `flagged: 0`, `check` green | same as above for `spec.md` |
| `plan.approve` | engineer | build PR open, plan `status: proposed` | put the plan with `status: approved`, `approved_by: <name>` |
| `pr.merge` | code_owner | checks green; a `/review` comment exists; class ≠ permission unless the person is the code owner | merge (squash) |
| `release.approve` | release_manager | a run is waiting at `production` | review the pending deployment |

`intent.decide` and `spec.accept` are two steps when CI must run on the
flip commit; the row shows "Flip committed — merge when `check` is green"
and the button becomes *Merge* when it is.

### Terminal side

- `/flow` (platform skill): `gh api user` for the login, `GET
  https://<site>/api/next?login=<login>`, prints the rows as
  `· <text> — <command or link>`; ends with the board URL. Works with no
  clone of a product repo.
- Every stage skill's last step prints `Next:` from the same copy table the
  board uses (`src/engine/text.ts` is the source; the skills quote it via a
  generated `docs/next-steps.md` that the validator keeps in sync).
- `/intent` from the terminal and `intent.start` from the board produce
  the same file, branch and PR body.

### Screens

| Route | Primary question | Change |
|-------|------------------|--------|
| `/` Board | What is waiting on **me**? | header: Sign in / `<login> · engineer · Sign out`; *Needs you* (mine) then *Needs others* (by role); each row's primary action per R5; first-run state (R3) |
| `/new` | How do I start an idea? | the intent form: title, five sections from the template, a slug preview, *Open the PR*; signed-out it shows the terminal command instead |
| `/intent/NNNN` | Where is this idea, and what can I do? | header action becomes a button when R5 says so; refusal text inline |
| `/systems` | What is running where? | unchanged, plus the exception banner's re-grant state (R12) and a roles row (logins per role, collaborator check) |
| `/archive` | | unchanged |

Phone layout unchanged; action buttons are full width on the card. Every
button pairs a label with the role it exercises ("Accept as product
owner"). Keyboard: the primary action is the row's first focusable
element.

### UI state copy

| State | Copy |
|-------|------|
| Signed out, Needs section | "Needs someone (N)" |
| Signed in, no role | "You are not in the Roles table yet. Ask the product owner (`<login>`) to add you — how: onboarding.md#roles" |
| Row with board action | button "Accept as product owner" · secondary "View PR" |
| Row with terminal action | "Run `/design 0002` in your `fernhill-platform` clone" · copy |
| Flip committed | "Flip committed · merge when `check` is green" |
| Refused | "Refused: <server reason>" |
| Exception suspended | "EX-002 — re-grant needed: engineer changed" |
| Kill switch | "Board actions are off (`board_actions: false`); use the terminal" |

### Mock before build

Yes: the signed-in board (engineer and product owner views), the
first-run state, `/new`, a refused action, and the suspended-exception
banner, as static HTML reviewed by the UX persona before the plan.

### Testing

- Engine: `needsYou(rows, snapshot, now, login)` fixtures for each role,
  for a login with no role, and signed out; parity test between `/api/next`
  and the board's rows.
- Functions: a fake GitHub for every action's precondition row (held role,
  wrong role, red `check`, `flagged > 0`, repo outside config, tampered
  cookie, bad `Origin`, missing CSRF, kill switch); a test that `act`
  cannot find any write-capable server token; sealing round-trip and
  expiry.
- Validator: roles/table mismatch, `CODEOWNERS` mismatch, exception holder
  drift (R12).
- Skills: `/flow` output against the fixture; every stage skill's `Next:`
  line matches the copy table.
- Smoke: every new screen state at 375 px and 1440 px, light and dark.

### Dependencies

None expected beyond the current lockfile; WebCrypto and `fetch` are in
Node 24. The GitHub App is a configuration object owned by the product
owner, not a dependency.

### Deployment, secrets and operations

| Name | Where | Contexts | Value | Expiry / rotation |
|------|-------|----------|-------|-------------------|
| `GITHUB_TOKEN` | Netlify env var | Production, Branch deploys | unchanged: read-only fine-grained PAT | as in `releases/0001-v0.1.0.md` |
| `GH_APP_ID`, `GH_APP_CLIENT_ID` | Netlify env var | Production, Branch deploys | the App's ids (not secret, but kept with the rest) | n/a |
| `GH_APP_CLIENT_SECRET` | Netlify env var | Production, Branch deploys | the App's client secret | rotate yearly or on suspicion; recorded in `releases/` before the change |
| `SESSION_KEY` | Netlify env var | Production, Branch deploys | 32 random bytes, base64 | rotating it signs everyone out; recorded in `releases/` |

The App's callback URLs are the production and `main` staging origins
only. Deploy previews have none of these and are read-only. Operations:
`board_actions: false` is the first response to any suspicion; the second
is revoking the App's user authorizations in GitHub.

## Out of scope

- The automation path in `docs/flow.md` (the agent opening spec and plan
  PRs on its own, incidents writing intents).
- Resolving flagged concerns, writing plans or specs, triage and release
  records from the board; those remain terminal commands the board hands
  you.
- Identities other than GitHub; more than one organization; private repos.
- A user store, preferences, notifications, per-user history.
- Changing what the agent may do; EX-002 and the hooks are untouched
  except for R12's suspension rule.
- Netlify API integration.

## Flagged concerns

(none yet — the design-gate personas report below this line)

## Acceptance

| Requirement | How we know |
|-------------|-------------|
| R1, R3, R4, R17 | Function and UI tests: signed-out = v0.1 bytes-for-bytes on `/api/flow`; cookie tamper, expiry and preview contexts yield signed-out; roles rendering fixtures; CI |
| R2, R9, R12, R13 | `scripts/validate-artifacts` fails on the planted mismatches (roles vs table, `CODEOWNERS`, exception holder drift); branch protection on both repos requires code-owner review (recorded in the release record); the compliance row exists |
| R5, R6, R8 | Fake-GitHub tests, one per precondition row, pass and refuse; a staging walkthrough by the product owner of every board action against real repos, recorded in the release record |
| R7, R19 | Review: no write-capable server credential in code or env; a test that `act` fails closed without a user token; App permissions and installation listed as text in the release record |
| R10, R11 | Parity test `/api/next` vs board rows; every skill's `Next:` line matches `docs/next-steps.md` (validator) |
| R14 | Flip `board_actions` on staging; writes refuse at the next refresh with no deploy |
| R15 | Rollback steps in `CLAUDE.md`; the publish-previous step rehearsed on production before release and recorded |
| R16 | The counted trial, run before the release is called done, with baseline, count and name in the release record |
| R18 | Function log lines in tests; a staging sample pasted into the release record |
