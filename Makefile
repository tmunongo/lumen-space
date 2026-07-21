# ─────────────────────────────────────────────────────────────────────────────
# Lumen Space – Makefile
#
# Version management helpers.
#
# Usage:
#   make bump-patch   1.0.0 → 1.0.1  (bug-fixes, no breaking changes)
#   make bump-minor   1.0.0 → 1.1.0  (new features, backward-compatible)
#   make bump-major   1.0.0 → 2.0.0  (breaking changes)
#
# Each recipe:
#   1. Reads current version from VERSION file (creates 0.1.0 if missing)
#   2. Increments the appropriate segment
#   3. Writes the new version back to VERSION
#   4. Commits VERSION with a conventional-commit message
#   5. Creates an annotated git tag  (vX.Y.Z)
#   6. Pushes the commit and tag, triggering CI/CD (Docker build + release)
# ─────────────────────────────────────────────────────────────────────────────

SHELL := /usr/bin/env bash -o pipefail
.DEFAULT_GOAL := help

VERSION_FILE := VERSION

# ── Read current version ─────────────────────────────────────────────────────
CURRENT_VERSION := $(shell cat $(VERSION_FILE) 2>/dev/null | tr -d '[:space:]' || echo "0.1.0")
MAJOR           := $(word 1, $(subst ., ,$(CURRENT_VERSION)))
MINOR           := $(word 2, $(subst ., ,$(CURRENT_VERSION)))
PATCH           := $(word 3, $(subst ., ,$(CURRENT_VERSION)))

.PHONY: help bump-patch bump-minor bump-major version _ensure-clean _do-bump

# ── Help ─────────────────────────────────────────────────────────────────────
help: ## Show this help
	@echo ""
	@echo "  Lumen Space – version management"
	@echo ""
	@echo "  Current version: $$(cat $(VERSION_FILE) 2>/dev/null || echo '0.1.0')"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'
	@echo ""

# ── Version display ──────────────────────────────────────────────────────────
version: ## Print the current version
	@echo "$(CURRENT_VERSION)"

# ── Guard: must be on a clean working tree ───────────────────────────────────
_ensure-clean:
	@if [ -n "$$(git status --porcelain)" ]; then \
		echo ""; \
		echo "  ✗  Working tree is not clean. Commit or stash changes first."; \
		echo ""; \
		git status --short; \
		echo ""; \
		exit 1; \
	fi

# ── Internal bump helper ─────────────────────────────────────────────────────
# Call as:  make _do-bump NEW_VERSION=X.Y.Z
_do-bump:
	@echo ""; \
	echo "  Bumping $(CURRENT_VERSION) → $(NEW_VERSION)"; \
	echo "$(NEW_VERSION)" > $(VERSION_FILE); \
	git add $(VERSION_FILE); \
	git commit -m "chore(release): bump version to v$(NEW_VERSION)"; \
	git tag -a "v$(NEW_VERSION)" -m "Release v$(NEW_VERSION)"; \
	echo ""; \
	echo "  ✓  Tagged v$(NEW_VERSION)"; \
	echo ""; \
	git push && git push --tags; \
	echo ""; \
	echo "  ✓  Pushed – CI will now build and publish ghcr.io image for v$(NEW_VERSION)"; \
	echo ""

# ── Patch bump  (x.y.Z) ──────────────────────────────────────────────────────
bump-patch: _ensure-clean ## Bump patch version (bug-fixes)
	$(MAKE) _do-bump NEW_VERSION=$(MAJOR).$(MINOR).$(shell echo $$(($(PATCH)+1)))

# ── Minor bump  (x.Y.0) ──────────────────────────────────────────────────────
bump-minor: _ensure-clean ## Bump minor version (new features)
	$(MAKE) _do-bump NEW_VERSION=$(MAJOR).$(shell echo $$(($(MINOR)+1))).0

# ── Major bump  (X.0.0) ──────────────────────────────────────────────────────
bump-major: _ensure-clean ## Bump major version (breaking changes)
	$(MAKE) _do-bump NEW_VERSION=$(shell echo $$(($(MAJOR)+1))).0.0
