# fernhill-platform

The company repo for Fernhill Software: how ideas become products. Read
[docs/flow.md](docs/flow.md) before touching anything under `intent/`.

## Commands

- `make check` — validate every artifact, persona and hook (what CI runs).
  Healthy output ends with `OK: N intents, M specs, P personas`.
- `scripts/personas list|enable|disable <id>` — manage advisory personas.
- `scripts/new-product <slug> --intent NNNN` — create a product repo from the template.
- `scripts/validate-artifacts [--target main]` — run just the artifact checks.

## Stage skills (run by a person)

`/intent` → `/design` → `/plan` (in the product repo) → build → PR → `/triage`
for incidents. `/new-product` links an accepted spec to a new repo.

## Conventions

- One directory per intent: `intent/NNNN-slug/` with `intent.md`, then
  `spec.md`. IDs are zero-padded, sequential, never reused.
- Every artifact carries YAML frontmatter exactly as shown in docs/flow.md.
  The dashboard reads frontmatter; keep keys lowercase and stable.
- `status: proposed` is the author's claim. Only the product owner flips it
  to `accepted`, and only in the PR that merges it. Never flip it yourself.
- All changes land through a PR. Never push to `main`, never merge, never
  approve. Hooks block this; CLAUDE.md is the reason.
- Personas are advisory. Quote their findings under "Flagged concerns"; do
  not resolve a concern on their behalf.
- Commit messages: imperative, one line, then why. Artifact commits name
  the intent: `intent 0001: draft spec`.

## Things Claude gets wrong here

- Writing specs that restate the intent. A spec has numbered, testable
  requirements and an explicit out-of-scope list.
- Skipping disabled personas is right; skipping enabled ones is not. Always
  read `personas/*.md` fresh — the set changes.
- Treating a persona's concern as resolved because it sounds reasonable.
  Only the named owner resolves it.

## Verifying your work

Before reporting done on any change in this repo, run `make check` and paste
the last line of its output. If you changed a hook, also run the hook's
self-test: `.claude/hooks/<name>.sh --test`.
