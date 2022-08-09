.PHONY: test lint

lint:
	hadolint Dockerfile

test:
	bats test