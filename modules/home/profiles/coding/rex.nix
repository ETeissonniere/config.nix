{
  config,
  inputs,
  lib,
  osClass,
  ...
}:
{
  imports = lib.optional (osClass == "nixos") inputs.rex.homeManagerModules.default;

  home.activation.rexAgentSetup =
    lib.hm.dag.entryAfter [ "linkGeneration" "claudeCodeSettings" "codexMutableSettings" ]
      ''
        rex=${config.home.path}/bin/rex
        if "$rex" version >/dev/null 2>&1; then
          run --quiet "$rex" skill setup --autostart=false \
            || warnEcho "could not set up Rex's agent skill; the next switch will retry"
        fi
      '';
}
