.PHONY: configure install test check apply

default: test

configure:
	chezmoi init -R --source=$(PWD)

install:
	chezmoi apply --force -R --source=$(PWD)

test:
	pre-commit run --all-files
	chezmoi execute-template --source=$(PWD) '{{ fromYaml (include "encrypted_secrets.yaml.age" | decrypt) | len }}'  > /dev/null

check: test
apply: install
