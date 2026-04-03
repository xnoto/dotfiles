.PHONY: setup init build test check install apply

default: build

setup:
	chezmoi init -R --source=$(PWD)

init: setup

build:
	chezmoi apply --dry-run --force -R --source=$(PWD)

test:
	pre-commit run --all-files
	chezmoi execute-template --source=$(PWD) '{{ fromYaml (include "encrypted_secrets.yaml.age" | decrypt) | len }}'  > /dev/null

check: test

install:
	chezmoi apply --force -R --source=$(PWD)

apply: install
