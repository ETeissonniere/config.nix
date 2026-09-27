HOST ?= wintermute
FLAKE := path:$(CURDIR)
NIX := nix --extra-experimental-features 'nix-command flakes'

.PHONY: help check build switch update fmt

help:
	@echo "make check   Evaluate the configuration"
	@echo "make build   Build without activating"
	@echo "make switch  Build and activate (also bootstraps nix-darwin)"
	@echo "make update  Update flake.lock; review before switching"
	@echo "make fmt     Format Nix files"

check:
	$(NIX) flake check --no-build "$(FLAKE)"
	$(NIX) eval "$(FLAKE)#darwinConfigurations.$(HOST).system.drvPath"

build:
	$(NIX) build "$(FLAKE)#darwinConfigurations.$(HOST).system"

switch: build
	sudo ./result/sw/bin/darwin-rebuild switch --flake "$(FLAKE)#$(HOST)"

update:
	$(NIX) flake update --flake "$(FLAKE)"

fmt:
	$(NIX) run "$(FLAKE)#formatter.$$($(NIX) eval --impure --raw --expr builtins.currentSystem)" -- --tree-root "$(CURDIR)"
