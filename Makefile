SHELL    := /bin/bash
FIND     := $(shell which gfind 2>/dev/null || shell which find)
SED      := $(shell which gsed 2>/dev/null  || shell which sed)
DOTFILES := $(shell ${FIND} . -maxdepth 1 ! -name '.' ! -name 'README.md' ! -name 'LICENSE' ! -name 'Makefile' ! -path './.git' -printf '%f\n')
MACOS    := $(shell uname -s | grep Darwin >/dev/null 2>&1 && echo true || echo false)

.PHONY: help install

help:
	@echo "Available commands:"
	@echo "  help    - Show this help message"
	@echo "  install - Install dotfiles"

install:
	@echo "Installing dotfiles to $(HOME)"
	@for file in $(DOTFILES);\
	do\
		echo "Installing $$file"; \
		cp -r "$$file" "$(HOME)/"; \
	done
	@if [[ ${MACOS} == "true" ]];\
	then\
		echo "Modifying install for MacOS";\
		echo "Removing i3";\
		rm -rf ~/.config/i3;\
		echo "Changing font size for alacritty";\
		${SED} -i s/12/16/g ~/.config/alacritty.toml;\
	fi
	@echo "Dotfiles installation complete."

