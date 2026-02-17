{
  config,
  lib,
  ...
}:
{

  programs.ripgrep = {
    enable = true;

    arguments = [
      # Don't have ripgrep vomit a bunch of stuff on the screen
      # show a preview of the match
      "--max-columns=150"
      "--max-columns-preview"

      # ignore git files
      "--glob=!.git/*"

      "--smart-case"
    ];
  };

  home.shellAliases = {
    grep = lib.mkForce (lib.getExe config.programs.ripgrep.package);
  };
}
