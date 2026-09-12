{
  lib,
  pkgs,
  self,
  nflib,
  ...
}:
{
  home-manager.users.simon = {
    imports = [
      self.modules.homeManager.bash
      self.modules.homeManager.bat
      self.modules.homeManager.brave
      self.modules.homeManager.btop
      self.modules.homeManager.dircolors
      self.modules.homeManager.direnv
      self.modules.homeManager.editorconfig
      self.modules.homeManager.fish
      self.modules.homeManager.fzf
      self.modules.homeManager.ghostty
      self.modules.homeManager.git
      self.modules.homeManager.gtk
      self.modules.homeManager.hunk
      self.modules.homeManager.jujutsu
      self.modules.homeManager.llm
      self.modules.homeManager.k8s
      #self.modules.homeManager.ladybird
      self.modules.homeManager.mpris-proxy
      self.modules.homeManager.mpv
      self.modules.homeManager.neovim
      self.modules.homeManager.niri
      self.modules.homeManager.nixIndex
      self.modules.homeManager.qt
      self.modules.homeManager.radicle
      self.modules.homeManager.rbw
      self.modules.homeManager.ripgrep
      self.modules.homeManager.shellAliases
      self.modules.homeManager.shellIntegration
      self.modules.homeManager.starship
      self.modules.homeManager.tmux
      self.modules.homeManager.voxtype
      self.modules.homeManager.udiskie
      self.modules.homeManager.wezterm
      self.modules.homeManager.yazi
      self.modules.homeManager.gpg
      self.modules.homeManager.yubikeyGpg
      self.modules.homeManager.zed
      self.modules.homeManager.zathura
      self.modules.homeManager.zellij
      self.modules.homeManager.zen
    ]
    ++ nflib.scanPaths ./. { };

    config = {
      home = {
        username = "simon";
        homeDirectory = "/home/simon";
        stateVersion = "25.11";
        sessionVariables = {
          SHELL = "${lib.getExe pkgs.fish}";
          TERMINAL = "${lib.getExe pkgs.ghostty}";
          BROWSER = "zen";
          VISUAL = "${lib.getExe pkgs.zed-editor}";
          EDITOR = "${lib.getExe pkgs.neovim}";
          KUBE_EDITOR = "${lib.getExe pkgs.neovim}";
          NH_HOME_FLAKE = "/home/simon/Projects/nixfiles";
        };
      };
      systemd.user.startServices = "sd-switch";
      nix.channels = { };
    };
  };
  users.users.simon.shell = pkgs.fish;

  # master key for noctalia private storage (clipboard history, calendar cache);
  # noctalia requires exactly 64 lowercase hex chars and never rotates it
  clan.core.vars.generators.noctalia-storage = {
    files.key.owner = "simon";
    runtimeInputs = [ pkgs.openssl ];
    script = ''
      openssl rand -hex 32 > "$out/key"
    '';
  };

  # caldav password for the noctalia opencloud calendar account
  clan.core.vars.generators.noctalia-caldav = {
    files.password.owner = "simon";
    prompts.password = {
      type = "hidden";
      persist = true;
      description = "opencloud caldav password for noctalia";
    };
  };

  # session link for kagi-search skill (modules/llm/skills)
  clan.core.vars.generators.kagi = {
    share = true;
    files."session-link".owner = "simon";
    prompts."session-link" = {
      type = "hidden";
      persist = true;
      description = "kagi session link";
    };
  };
}
