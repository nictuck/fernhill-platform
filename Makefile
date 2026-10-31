.PHONY: check validate hooks personas

check: validate hooks personas
	@echo "OK: $$(ls -d intent/[0-9]*/ 2>/dev/null | wc -l | tr -d ' ') intents, $$(ls intent/[0-9]*/spec.md 2>/dev/null | wc -l | tr -d ' ') specs, $$(scripts/personas list | wc -l | tr -d ' ') personas"

validate:
	@scripts/validate-artifacts $(ARGS)

hooks:
	@for h in .claude/hooks/*.sh; do bash -n "$$h" || exit 1; "$$h" --test || exit 1; done

personas:
	@scripts/personas json > /dev/null
