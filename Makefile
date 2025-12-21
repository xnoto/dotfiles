.PHONY: install

install:
	chezmoi init --source=$(PWD) --apply
