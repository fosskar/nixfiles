{ inputs, ... }:
{
  imports = [ inputs.ags.homeManagerModules.ags ];

  programs.ags = {
    enable = true;
  };
}
