{
  pkgs,
  inputs,
  ...
}: {
  imports = [inputs.stylix.homeManagerModules.stylix];

  stylix = {
    base16Scheme = "${pkgs.base16-schemes}/share/themes/google-dark.yaml";
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
        applications = 14;
        desktop = 14;
        popups = 16;
        terminal = 13;
      };
    };
    polarity = "dark";
    targets = {
      bat.enable = true;
      firefox.enable = true;
      foot.enable = true;
      gtk.enable = true;
      helix.enable = true;
      hyprland.enable = true;
      i3.enable = true;
      kde.enable = true;
      kitty.enable = true;
      kitty.variant256Colors = true;
      nixvim.enable = true;
      swaylock.enable = true;
      tmux.enable = true;
      vim.enable = true;
      vscode.enable = true;
      waybar.enable = true;
      xfce.enable = true;
      xresources.enable = true;
      zathura.enable = true;
    };
  };
}
