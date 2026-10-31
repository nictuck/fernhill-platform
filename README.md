# Fernhill Software — platform

Fernhill is a one-person software company run on the AI-native SDLC: ideas
are captured as `intent.md`, specified as `spec.md`, planned as `plan.md`,
built and tested by agents, reviewed in PRs, deployed behind a human release
gate, and watched in production until the next incident becomes the next
intent.

This repository is the company: the process, the policies, the advisory
personas, and (soon) the Flow dashboard that shows where every idea is.
Each product lives in its own repository created from
[fernhill-product-template](https://github.com/nictuck/fernhill-product-template).

## Start here

- [docs/flow.md](docs/flow.md) — the stages, artifacts, gates and the state
  machine. Everything else implements this.
- [intent/](intent/) — every idea, one directory each.
- [personas/](personas/) — the advisory voices at the gates. Toggle with
  `scripts/personas`.
- [REVIEW.md](REVIEW.md) — how PRs are reviewed.
- [docs/ai-native-sdlc-playbook.pdf](docs/ai-native-sdlc-playbook.pdf) — the
  source material.

## Running an idea through the loop (today, by hand)

```bash
# 1. Plan — capture the idea; opens a PR you accept as product owner
claude  →  /intent

# 2. Design — spec it, with the enabled personas consulted; opens a PR
claude  →  /design 0001

# 3. Create the product repo once the spec is accepted
scripts/new-product flow --intent 0001

# 4. Build — in the product repo, plan mode first, then implement
cd ../products/flow && claude  →  /plan 0001

# 5. Test + Deploy — CI on the PR; merging deploys staging (main--<site>);
#    approve the "production" environment in the release run to ship

# 6. Maintain — incidents become intents
claude  →  /triage
```

## Checks

```bash
make check
```
