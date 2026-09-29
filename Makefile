HOST ?= $(shell scutil --get LocalHostName | tr '[:upper:]' '[:lower:]')
FLAKE := path:$(CURDIR)
NIX := nix --extra-experimental-features 'nix-command flakes'

.PHONY: help check build switch postinstall fmt

help:
	@echo "make build        Build without activating"
	@echo "make switch       Build and activate with nh"
	@echo "make postinstall  Set up SSH keys, GitHub, and Time Machine interactively"
	@echo "make check        Evaluate the configuration"
	@echo "make fmt          Format Nix files"

check:
	$(NIX) flake check --no-build "$(FLAKE)"
	$(NIX) eval "$(FLAKE)#darwinConfigurations.$(HOST).system.drvPath"

build:
	nh darwin build "$(FLAKE)" --hostname "$(HOST)"

switch:
	nh darwin switch "$(FLAKE)" --hostname "$(HOST)"

postinstall:
	fish scripts/postinstall/github-setup.fish
	fish scripts/postinstall/time-machine-setup.fish

fmt:
	$(NIX) run "$(FLAKE)#formatter.$$($(NIX) eval --impure --raw --expr builtins.currentSystem)" -- --tree-root "$(CURDIR)"
