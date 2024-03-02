{
  pkgs,
  inputs,
  ...
}: {
  imports = [inputs.stylix.homeManagerModules.stylix];

  stylix = {
    base16Scheme = "${pkgs.base16-schemes}/share/themes/spacemacs.yaml";
    autoEnable = false;
    cursor = {
      package = pkgs.capitaine-cursors;
      name = "capitaine-cursors";
      size = 28;
    };
    fonts = {
      serif = {
        package = pkgs.roboto;
        name = "Roboto";
      };

      sansSerif = {
        package = pkgs.roboto;
        name = "Roboto";
      };

      monospace = {
        package = pkgs.fira-mono;
        name = "FiraCode Mono";
      };

      emoji = {
        package = pkgs.noto-fonts-emoji;
        name = "Noto Color Emoji";
      };
      sizes = {
        applications = 10;
        desktop = 12;
        popups = 14;
        terminal = 10;
      };
    };
    polarity = "dark";
    targets = {
      alacritty.enable = true;
      bat.enable = true;
      dunst.enable = true;
      firefox.enable = true;
      foot.enable = true;
      gtk.enable = true;
      helix.enable = true;
      hyprland.enable = false; # needs image set
      i3.enable = true;
      kde.enable = false; # needs image set
      kitty.enable = true;
      kitty.variant256Colors = true;
      nixvim.enable = true;
      swaylock.enable = false; # needs image set
      tmux.enable = true;
      vim.enable = true;
      vscode.enable = false; # ugly af?!!?!?
      waybar.enable = true;
      xfce.enable = true;
      xresources.enable = true;
      zathura.enable = true;
    };
  };
}
