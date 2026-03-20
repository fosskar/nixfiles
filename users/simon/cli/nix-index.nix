# nix-index-database — pre-built index for `nix-locate` and `comma`
# comma (,) lets you run any command without installing it:
#   , htop    → runs nix run nixpkgs#htop
#   , cowsay  → finds and runs the right package
# also replaces command-not-found with useful "nix run" suggestions
{
  inputs,
  ...
}:
{
  imports = [ inputs.nix-index-database.hmModules.nix-index ];

  programs.nix-index-database.comma.enable = true;
}
