{
  lib,
  pkgs,
  self,
  nflib,
  ...
}:
{
  imports = [
    self.modules.nixos.llm
    self.modules.nixos.noctalia
    self.modules.nixos.workspaceClient
  ];

  home-manager.users.simon = {
    imports = [
      self.modules.homeManager.bash
      self.modules.homeManager.bat
      self.modules.homeManager.brave
      self.modules.homeManager.btop
      self.modules.homeManager.cursor
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
      self.modules.homeManager.niri
      self.modules.homeManager.psd
      self.modules.homeManager.nixIndex
      self.modules.homeManager.qt
      self.modules.homeManager.radicle
      self.modules.homeManager.rbw
      self.modules.homeManager.ripgrep
      self.modules.homeManager.shellAliases
      self.modules.homeManager.ssh
      self.modules.homeManager.starship
      self.modules.homeManager.tmux
      self.modules.homeManager.voxtype
      self.modules.homeManager.workspaceClient
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
          # --wait: git, jj and sudoedit prefer VISUAL and need it to block
          VISUAL = "${lib.getExe pkgs.zed-editor} --wait";
          NH_HOME_FLAKE = "/home/simon/Projects/nixfiles";
        };
      };
      systemd.user.startServices = "sd-switch";
      nix.channels = { };
    };
  };
  users.users.simon.shell = pkgs.fish;
}
