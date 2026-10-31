---
name: design
description: Stage 2 (Design). From an accepted intent, write spec.md with requirements and design, consult every enabled persona whose gates include "design", record their concerns, and open the PR the product owner accepts.
argument-hint: "<intent id, e.g. 0001>"
disable-model-invocation: true
---

You are the requirements-and-design author. Requirements and design happen
in this one session, guided by the personas (our policy skills). The
product owner reviews the spec; they do not write it.

Intent: $ARGUMENTS

## Steps

1. **Check the gate.** The intent directory `intent/$ARGUMENTS-*/` must
   exist on `main` with `status: accepted`. If it is `proposed`, stop: the
   product owner has not accepted it (gate 1). If `spec.md` already exists
   with `status: accepted`, stop and ask whether to supersede it.
2. **Read**: `intent.md`, `docs/flow.md` (Artifacts → spec.md), `REVIEW.md`.
   Run `scripts/personas json` and keep the personas with `enabled: true`
   and `design` in `gates`.
3. **Draft the spec** at `intent/$ARGUMENTS-*/spec.md`:
   - frontmatter: `intent`, `status: proposed`, `personas: [ids consulted]`,
     `flagged: 0` (update at step 5)
   - **Summary** (3 sentences), **Requirements** (numbered `R1..Rn`, each
     testable — a reader can say pass/fail), **Design** (architecture, data,
     interfaces, UI screens if any — name the stack and why), **Out of
     scope**, **Flagged concerns** (empty for now), **Acceptance** (how we
     know R1..Rn are met; which become CI checks).
   - For a product with a UI, include a screen list with each screen's
     primary question. If a mock would help, say so under Open questions.
4. **Consult the personas.** For each persona kept in step 2, launch one
   subagent (general-purpose) whose prompt is: the full body of
   `personas/<id>.md`, then "You are at the design gate. Here is intent.md:
   …, here is the draft spec.md: …. Report as your persona instructs."
   Launch them in parallel. Do not paraphrase them to be nicer.
5. **Record findings.** Under **Flagged concerns**, one entry per
   Important finding:
   `- [ ] **<persona>**: <finding> — *owner:* <persona owner> — *resolution:* pending`.
   Fold Nits into the design where they are plainly right; otherwise drop
   them. Set `flagged:` to the number of unchecked entries. Revise
   requirements or design where a finding shows a gap — but do not mark a
   concern resolved; only its owner does.
6. **Validate**: `scripts/validate-artifacts`.
7. **Commit and open the PR.** Branch `design/$ARGUMENTS-<slug>`; message
   `intent $ARGUMENTS: draft spec`; PR title `spec $ARGUMENTS: <title>`;
   body:

   ```
   Stage 2 → gate 2. Product owner: review the spec against the intent.
   Flagged concerns: N (resolve each with its owner; tick the box and write
   the resolution). When satisfied: set `status: accepted`, merge.
   Tech lead consult recommended when flagged > 0.
   Next after acceptance: `scripts/new-product <slug> --intent NNNN`, then `/plan NNNN` in the product repo.
   ```

8. **Report**: PR URL, the requirement count, and the flagged concerns in
   one line each.
