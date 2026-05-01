SWIFTFORMAT := .nest/bin/swiftformat
SWIFTLINT := .nest/bin/swiftlint
AST_LINT := .nest/bin/my-swift-linter

.PHONY: install-commands format lint ast-lint format-lint hooks test check

install-commands:
	./scripts/nest.sh bootstrap nestfile.yaml

format:
	@test -f "$(SWIFTFORMAT)" || (echo "Run: make install-commands" && exit 1)
	"$(SWIFTFORMAT)" --config .swiftformat .

lint:
	@test -f "$(SWIFTLINT)" || (echo "Run: make install-commands" && exit 1)
	"$(SWIFTLINT)" lint --config .swiftlint.yml --strict

ast-lint:
	@test -f "$(AST_LINT)" || (echo "Run: make install-commands" && exit 1)
	"$(AST_LINT)" Sources Tests

format-lint: format lint

hooks:
	./scripts/setup-hooks.sh

test:
	swift test

check: format lint ast-lint test
