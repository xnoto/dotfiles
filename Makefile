SHELL    := /bin/bash
DOTFILES := $(shell find . -maxdepth 1 ! -name '.' ! -name 'README.md' ! -name 'LICENSE' ! -name 'Makefile' ! -path './.git' -printf '%f\n')

.PHONY: help install

help:
	@echo "Available commands:"
	@echo "  help    - Show this help message"
	@echo "  install - Install dotfiles"

install:
	@echo "Installing dotfiles to $(HOME)"
	@for file in $(DOTFILES); do \
		echo "Installing $$file"; \
		cp -r "$$file" "$(HOME)/"; \
	done
	@echo "Dotfiles installation complete."

