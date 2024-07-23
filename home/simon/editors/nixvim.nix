{ inputs, ... }:
{
  imports = [ inputs.nixvim.homeManagerModules.nixvim ];

  programs.nixvim = {
    enable = true;
    # now you can use vi, vim, nvim and get always neovim
    viAlias = true;
    vimAlias = true;

    defaultEditor = true;
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
