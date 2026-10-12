{ pkgs, ... }:
{
  home.packages = with pkgs; [
    httpie
    jq
    python3Packages.huggingface-hub
  ];
}
