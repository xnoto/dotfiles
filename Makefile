SHELL             := /bin/bash
FIND              := $(shell which gfind 2>/dev/null || which find)
SED               := $(shell which  gsed 2>/dev/null || which sed)
DOTFILES          := $(shell ${FIND} . -maxdepth 1 ! -name '.' ! -name 'README.md' ! -name 'LICENSE' ! -name 'Makefile' ! -path './.git' ! -path './secrets' -printf '%f\n')
MACOS             := $(shell uname -s | grep Darwin >/dev/null 2>&1 && echo true || echo false)
GITHUB_MCP_TOKEN  := $(shell sops decrypt secrets/secrets.yaml | grep ^github_mcp_token | cut -d ' ' -f 2)
GRAFANA_MCP_TOKEN := $(shell sops decrypt secrets/secrets.yaml | grep ^grafana_mcp_token | cut -d ' ' -f 2)

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
	@echo "Adding GitHub MCP Token to .bash_profile and .zprofile"
	@echo "export GITHUB_TOKEN=${GITHUB_MCP_TOKEN}" >>$(HOME)/.bash_profile
	@echo "export GITHUB_TOKEN=${GITHUB_MCP_TOKEN}" >>$(HOME)/.zprofile
	@echo "Adding Grafana MCP Token to .bash_profile and .zprofile"
	@echo "export GRAFANA_TOKEN=${GRAFANA_MCP_TOKEN}" >>$(HOME)/.bash_profile
	@echo "export GRAFANA_TOKEN=${GRAFANA_MCP_TOKEN}" >>$(HOME)/.zprofile
	@echo "Dotfiles installation complete."

