---
name: new-product
description: Create a product repository from fernhill-product-template for an intent whose spec is accepted, link it in .sdlc.yaml and the intent, and set up branch protection and the production environment gate.
argument-hint: "<slug> --intent <id>"
disable-model-invocation: true
---

Run `scripts/new-product $ARGUMENTS` and follow its output. It will:

1. Check the intent's `spec.md` is on `main` with `status: accepted` (gate 2).
2. `gh repo create nictuck/<slug>` from the template and clone it to
   `../products/<slug>`.
3. Fill `.sdlc.yaml`, `CLAUDE.md` and `README.md` placeholders.
4. Protect `main` (PR required, no force push, enforce for admins) and
   create the `production` environment with the release manager as
   required reviewer.
5. Open a PR in this repo that sets `product: <slug>` in the intent's
   frontmatter.

Things only the human can do afterwards, which the script prints:
- Create the Netlify site and add `NETLIFY_AUTH_TOKEN` / `NETLIFY_SITE_ID`
  as repo secrets (never paste tokens into this session).
- Optionally add `ANTHROPIC_API_KEY` and set the repo variable
  `CLAUDE_REVIEW_ENABLED=true` to turn on AI PR review.

If the script fails partway, fix the cause and re-run; every step is
idempotent.
