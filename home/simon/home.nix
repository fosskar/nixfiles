{ lib, pkgs, ... }:
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
      SHELL = "${lib.getExe pkgs.fish}";
      TERMINAL = "${lib.getExe pkgs.ghostty}";
      BROWSER = "zen";
      EDITOR = "${lib.getExe pkgs.zed-editor}";
      KUBE_EDITOR = "${lib.getExe pkgs.neovim}";
    };
    stateVersion = "23.11";
  };

  module = {
    browser = {
      zen-browser.enable = true;
      brave.enable = true;
      ladybird.enable = false;
    };
    desktop = {
      wayland = {
        hyprland = {
          enable = true;
          hypridle.enable = true;
          hyprlock.enable = true;
          hyprpaper.enable = true;
          hyprmode.enable = true;
          plugins.enable = true;
        };
        bar = "hyprpanel";
        applauncher = "sherlock";
      };
    };
    editors = {
      zed-editor.enable = true;
      editorconfig.enable = true;
      neovim.enable = true;
      vscodium.enable = false;
    };
    gaming = {
      awakened-poe.enable = true;
      mangohud.enable = true;
      star-citizen.enable = true;
      vkbasalt.enable = true;
    };
    nix = {
      nh.enable = true;
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
      kde-connect.enable = false;
      profile-sync-daemon.enable = false;
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
        gemini-cli.enable = true;
        claude-code.enable = true;
        dircolors.enable = true;
        direnv.enable = true;
        fzf.enable = true;
        k9s.enable = true;
        zellij.enable = false;
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
