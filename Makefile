.PHONY: install

install:
	chezmoi init --source=$(PWD)
	chezmoi apply --source=$(PWD)
