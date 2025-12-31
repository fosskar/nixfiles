{ mylib, ... }:
{
  imports = mylib.scanPaths ./. {
    exclude = [
      "editorconfig.nix" # disabled like the comment showed
    ];
  };

  # set global default editor here
  home = {
    sessionVariables.EDITOR = "nvim";
  };
}
