{ mylib, ... }:
{
  imports = mylib.scanPaths ./. {
    exclude = [
      "alacritty.nix"
      "kitty.nix"
    ];
  };
}
