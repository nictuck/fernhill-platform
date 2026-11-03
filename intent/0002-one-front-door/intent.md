---
id: "0002"
title: One place to run the loop
status: accepted
author: Nicholas Tucker
origin: idea
product: ""
created: 2026-11-02
---

## Problem

Running the loop is clunky: I start an intent here, in a Claude Code
session in a terminal, with slash commands and files, while the dashboard
that shows the flow lives on Netlify in a browser. The two halves don't
meet. The board tells me what is waiting on me, but to act I go back to the
terminal, the right folder and the right command, and the terminal has no
view of the board. Intent 0001 went round the loop this way, and every
hand-off between the two was a seam someone has to know about.

## Proposed outcome

A newcomer — another person, not me — can take an idea to production from
the platform alone: one place to start an intent, see where it is, and take
the next action, without reading a transcript, asking me, or memorising
which command comes next. The board may act as well as show: a person
signed in as themselves can start, accept, approve or release from it,
under exactly the rules the terminal enforces today.

Done is a counted trial, not a feeling: a named second person, given the
kit below and nothing else, takes a fresh trivial intent to production with
every next step discoverable from the board or the terminal, and the number
of times they have to ask me is zero. The seams in 0001's history are the
baseline the spec counts first. The trial runs with EX-002 active, so it
measures the seams between surfaces, not who passes the gates.

## Affected users and systems

- A second person joining Fernhill, who has not seen how 0001 was built;
  they are the measure of done. Me, in every role, as the second
  beneficiary.
- `fernhill-platform`: `docs/flow.md` (the Roles table first), the stage
  skills, hooks, `personas/compliance.md` (a "role assigned or revoked"
  approval row), and onboarding documentation, which does not exist today
  and counts as a deliverable.
- The Flow dashboard (`fernhill-flow`), which today only shows the loop and
  does not know who is looking at it.
- GitHub as the source of truth and as the identity provider; Netlify as
  the host.

## Constraints

- Artifacts in git stay the source of truth, and gates stay with named
  humans or an active exception. Nothing here weakens the hooks.
- Change `docs/flow.md` before changing skills or the dashboard.
- No second place to maintain status by hand.
- **Identity.** The second person gets their own GitHub account and their
  own Claude Code login; no shared accounts, ever. They get a row in the
  Roles table in `docs/flow.md` before they act.
- **Writes are the human's.** Any gate pass or artifact change made from
  the board is authored by the signed-in person's own GitHub identity
  (OAuth or a GitHub App acting on their behalf), never by the dashboard's
  read-only token or any shared server credential. Hooks, CI and exceptions
  apply to it exactly as to a terminal action, and the evidence is the same
  git and PR record naming the human. The dashboard's read token never
  becomes a write path.
- **Roles and exceptions move together.** A change to the Roles table ends
  or re-grants every active exception over the reassigned gate, and the
  Board shows it.
- **The kit is a precondition, not a deliverable.** I provision it, as a
  recorded change: GitHub collaborator access to the repos, a Netlify seat
  if the role needs one, a Claude Code login, and the Roles row.
- Writing from a browser is a new data class (a person's identity and a
  write-capable credential) on a site that today holds only public data;
  the spec names where identity and authorization live, with the security
  lead present at gate 2, before any write path exists. No identity store
  in Blobs.
- Free tier everywhere; two people at most operate it.
- Built through this process: intent → spec → plan → PR → staging → release.

## Open questions

- Which gates the second person holds for the trial (originator only,
  engineer, or any gate by name) — design decides, and the Roles table
  records it.
- Where this intent's plan lives: the changes span `fernhill-platform`,
  which has no `plan/`, and `fernhill-flow`, which does. Name the home
  (`product:`) before `/design`.
- Whether the flow.md "Automation path" items — the agent opening spec and
  plan PRs on its own — are inside this intent or stay out. The problem
  statement invites them; nothing here asks for them.
- What design must answer for the board: who "you" is on a read-only visit;
  the one action a person can take from where they stand, per state; the
  hand-off written as a visible state ("Run /design 0002 in your
  fernhill-platform clone") rather than a known step; a first-run empty
  state for a person with no clone; and how a board-driven release keeps
  the release record ahead of the deployment.
- Rollback for a board-driven change must name three things: publish the
  previous deploy, revert the flow.md or artifact PR, and remove the
  person's access and tokens.
