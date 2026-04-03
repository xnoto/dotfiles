.PHONY: configure build test check install apply

default: build

configure:
	chezmoi init -R --source=$(PWD)

build:
	chezmoi apply --dry-run --force -R --source=$(PWD)

test:
	pre-commit run --all-files
	chezmoi execute-template --source=$(PWD) '{{ fromYaml (include "encrypted_secrets.yaml.age" | decrypt) | len }}'  > /dev/null

check: test

install:
	chezmoi apply --force -R --source=$(PWD)

apply: install
