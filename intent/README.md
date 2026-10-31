# Intent home

Every idea at Fernhill starts here as `intent/NNNN-slug/intent.md`, written
in the originator's own words with Claude's help (`/intent`). Once the
product owner accepts it, `spec.md` lands beside it (`/design`). Incident
records that fed the intent go in `incidents/`.

- IDs are zero-padded, sequential, never reused. The next free ID is one
  more than the highest directory here.
- Copy [TEMPLATE.md](TEMPLATE.md); keep the frontmatter keys exactly.
- `status: proposed` means "the author thinks this is ready". Only the
  product owner flips it to `accepted` (or `rejected`/`parked`), in the PR
  that merges it. CI refuses a `proposed` intent on `main`.
- An intent is `done` when its outcome is in production and the on-call
  has had a quiet week. Flip it in a PR.

| Status | Meaning |
|--------|---------|
| proposed | On a branch, waiting for the product owner |
| accepted | On `main`; in design, build, test, deploy or maintain |
| parked | Valid, not now. Leaves the board |
| rejected | Not doing it. Record stays |
| done | In production and stable |
