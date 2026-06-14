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
      self.modules.homeManager.jujutsu
      self.modules.homeManager.llm
      self.modules.homeManager.k9s
      #self.modules.homeManager.ladybird
      self.modules.homeManager.mpris-proxy
      self.modules.homeManager.mpv
      self.modules.homeManager.neovim
      self.modules.homeManager.niri
      self.modules.homeManager.nixIndex
      self.modules.homeManager.qt
      self.modules.homeManager.rbw
      self.modules.homeManager.ripgrep
      self.modules.homeManager.shellAliases
      self.modules.homeManager.shellIntegration
      self.modules.homeManager.starship
      self.modules.homeManager.theme
      self.modules.homeManager.tmux
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
        };
      };
      systemd.user.startServices = "sd-switch";
      nix.channels = { };
    };
  };
  users.users.simon.shell = pkgs.fish;

  # session link for kagi-search skill (modules/home/llm/skills)
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
