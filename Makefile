.PHONY: setup init build test check install apply

default: build

setup:
	chezmoi init -R --source=$(PWD)

init: setup

build:
	chezmoi apply --dry-run --force -R --source=$(PWD)

test:
	pre-commit run --all-files

check: test

install:
	chezmoi apply --force -R --source=$(PWD)

apply: install
