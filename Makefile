.PHONY: all check test install

all: check

check:
	@echo "Verifying chezmoi is valid and can decrypt secrets..."
	@echo
	pre-commit run --all-files && chezmoi cat --source=$(PWD) ~/.bashrc.d/github > /dev/null && echo "Success"

test: check

install:
	chezmoi init --source=$(PWD)
	chezmoi apply --source=$(PWD)
