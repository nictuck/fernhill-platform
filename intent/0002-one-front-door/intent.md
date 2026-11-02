---
id: "0002"
title: One place to run the loop
status: proposed
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
which command comes next.
Whether that place is the dashboard, the terminal, or the two talking to
each other is for design to decide.

## Affected users and systems

- A second person joining Fernhill, who has not seen how 0001 was built;
  they are the measure of done. Me, in every role, as the second
  beneficiary.
- `fernhill-platform`: the stage skills, `docs/flow.md`, hooks, onboarding
  docs.
- The Flow dashboard (`fernhill-flow`), which today only shows the loop.
- GitHub as the source of truth; Netlify as the host.

## Constraints

- Artifacts in git stay the source of truth, and gates stay with named
  humans or an active exception. Nothing here weakens the hooks.
- Change `docs/flow.md` before changing skills or the dashboard.
- No second place to maintain status by hand.
- The dashboard is read-only today, with a read-only token. Anything that
  writes to GitHub from a browser is a new data class and a security
  decision, not a given.
- Free tier everywhere; one person operates it.
- Built through this process: intent → spec → plan → PR → staging → release.

## Open questions

- What does the second person need to be given: a GitHub account on the
  repos, a Netlify seat, a Claude Code login, a role in `docs/flow.md`?
- Does "one place" mean the dashboard becomes the front door (start an
  intent, accept, approve from the board), the terminal gains the board, or
  both talk to each other?
- If the board acts, where do identity and authorization live?
- How much of this is onboarding documentation versus product?
