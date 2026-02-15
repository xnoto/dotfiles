.PHONY: all check test install

all: check

check:
	pre-commit run --all-files
	chezmoi cat --source=$(PWD) ~/.bashrc.d/github > /dev/null

test: check

install:
	chezmoi init --source=$(PWD)
	chezmoi apply --source=$(PWD)
