{ pkgs, ... }:
{
  home.packages = with pkgs; [
    httpie
    jq
  ];
}
