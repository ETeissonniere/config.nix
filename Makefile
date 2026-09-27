HOST ?= wintermute
FLAKE := path:$(CURDIR)
NIX := nix --extra-experimental-features 'nix-command flakes'

.PHONY: help check build switch postinstall update clean fmt

help:
	@echo "make check        Evaluate the configuration"
	@echo "make build        Build without activating"
	@echo "make switch       Build and activate with nh"
	@echo "make postinstall  Set up SSH keys, GitHub, and Time Machine interactively"
	@echo "make update       Update flake.lock; review before switching"
	@echo "make fmt          Format Nix files"
	@echo "make clean        Remove old generations and collect garbage with nh"

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

update:
	$(NIX) flake update --flake "$(FLAKE)"

clean:
	sudo nh clean all --keep-since 30d --keep 1 --no-gcroots

fmt:
	$(NIX) run "$(FLAKE)#formatter.$$($(NIX) eval --impure --raw --expr builtins.currentSystem)" -- --tree-root "$(CURDIR)"
