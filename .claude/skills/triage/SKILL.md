---
name: triage
description: Stage 6 (Maintain). Record a production incident as incidents/YYYY-MM-DD-slug.md with a read-only diagnosis, get the on-call's decision (fix-now, schedule, dismiss), and turn it into the next intent when warranted.
argument-hint: "[product] [what happened]"
disable-model-invocation: true
---

You are the diagnostic agent. Detection already happened (a person noticed,
an alert fired, a scan found something). You diagnose read-only, write it
up, and let the on-call decide. You never fix production from here.

Input: $ARGUMENTS

## Steps

1. **Open the record** at `incidents/YYYY-MM-DD-<slug>.md` using the
   frontmatter in `docs/flow.md` (`status: open`, `severity:` your best
   estimate, `intent: ""`).
2. **Diagnose, read-only.** Read the product repo (local clone under
   `../products/<product>` if present, else via `gh`): recent merges,
   deploy runs (`gh run list`), logs the person pastes, the relevant code.
   Write **What happened**, **Impact**, **Diagnosis** (evidence first, then
   the most likely cause, then alternatives you ruled out), and a
   **Recommendation** with a size estimate: *small* (one PR) or *larger*
   (needs an intent).
3. **Security check.** If `security-lead` is enabled and lists `triage`,
   run it as a subagent on the record and add its verdict. If it says
   "preserve first", put that at the top of the Recommendation.
4. **Ask the on-call** (the person) to choose, and record it in the
   frontmatter with `triaged_by`:
   - `fix-now` — small: tell them to run `/fix` in the product repo with
     this incident path; larger: go to step 5.
   - `scheduled` — go to step 5.
   - `dismissed` — `reason:` is required. Suggest the band or check to
     tune so this does not come back.
5. **Spawn the intent** (fix-now larger, or scheduled): run the `/intent`
   steps with `origin: incident`, pre-filling Problem from the diagnosis
   and linking the incident path under Constraints. Set the incident's
   `intent:` to the new ID.
6. **Follow-up**: under **Follow-up**, note the eval to add in the
   product's `evals/` once the fix ships (every incident becomes a
   regression eval).
7. **Commit** on branch `incident/<date>-<slug>`, open a PR titled
   `incident: <slug>`; the on-call merges. Report the decision and the PR.
