.PHONY: init install check test apply

default: init

init:
	chezmoi init -R --source=$(PWD)

install:
	chezmoi apply -R --source=$(PWD)

check:
	pre-commit run --all-files
	chezmoi execute-template --source=$(PWD) '{{ fromYaml (include "encrypted_secrets.yaml.age" | decrypt) | len }}'  > /dev/null

apply: install
test: check
