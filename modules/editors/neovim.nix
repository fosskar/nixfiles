{
  inputs,
  pkgs,
  ...
}: {
  imports = [inputs.nixvim.homeManagerModules.nixvim];

  programs.nixvim = {
    config = {
      enable = true;
      viAlias = true;
      vimAlias = true;
      defaultEditor = true;

      options = {
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
  };
}
