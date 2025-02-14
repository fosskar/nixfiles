{ pkgs, ... }:
{
  imports = [
    ./browser
    ./desktop/wayland
    ./editors
    ./gaming
    ./nix
    ./pkgs
    ./programs
    ./services
    ./terminal
    ./themes
  ];

  home = {
    username = "simon";
    homeDirectory = "/home/simon";
    sessionVariables = {
      SHELL = "${pkgs.fish}/bin/fish";
      BROWSER = "zen";
    };
    stateVersion = "23.11";
  };

  module = {
    browser = {
      firefox.enable = false;
      zen-browser.enable = true;
      brave.enable = false;
    };
    desktop = {
      wayland = {
        hyprland = {
          enable = true;
          hypridle.enable = true;
          hyprlock.enable = true;
          hyprmode.enable = true;
          plugins.enable = true;
        };
        cosmic.enable = false;
        bar = "hyprpanel";
        applauncher = "anyrun";
      };
    };
    editors = {
      zed-editor.enable = true;
      editorconfig.enable = true;
      neovim.enable = true;
      vscodium.enable = true;
    };
    gaming = {
      awakened-poe.enable = true;
      mangohud.enable = true;
      star-citizen.enable = true;
      vkbasalt.enable = true;
    };
    nix = {
      nh.enable = true;
      nix-index.enable = true;
    };
    programs = {
      gpg.enable = true;
      mpv.enable = true;
      ssh.enable = true;
      xdg.enable = true;
      zathura.enable = true;
    };
    services = {
      audio.enable = false;
      dconf.enable = true;
      kde-connect.enable = true;
      polkit.enable = false; # use hyprpolkitagent
      tailray.enable = true;
      udiskie.enable = true;
    };
    terminal = {
      emulators = {
        alacritty.enable = false;
        kitty.enable = false;
        wezterm.enable = true;
        ghostty.enable = true;
      };
      programs = {
        git.enable = true;
        jujutsu.enable = true;
        yazi.enable = true;
        bat.enable = true;
        btop.enable = true;
        dircolors.enable = true;
        direnv.enable = true;
        fzf.enable = true;
        k9s.enable = true;
      };
      shell = {
        aliases.enable = true;
        zsh.enable = true;
        bash.enable = true;
        fish.enable = true;
        starship.enable = true;
      };
    };
    themes = {
      gtk.enable = true;
      qt.enable = true;
    };
  };

  # reload system units when changing configs
  systemd.user.startServices = "sd-switch"; # or "legacy" if "sd-switch" breaks again
}
