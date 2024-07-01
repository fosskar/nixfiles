{ inputs, ... }:
{
  imports = [ inputs.nixvim.homeManagerModules.nixvim ];

  home = {
    sessionVariables.EDITOR = "nvim";
  };

  programs.nixvim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    defaultEditor = false;
    enableMan = false;

    opts = {
      title = true;

      ignorecase = true; # ignore case when using lowercase in search
      smartcase = true; # but dont ignore it when using upper case

      autoindent = true;
      smartindent = true;
    };

    clipboard = {
      providers.wl-copy.enable = true;
    };
  };
}
