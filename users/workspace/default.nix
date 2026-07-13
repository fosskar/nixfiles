{
  lib,
  pkgs,
  self,
  nflib,
  ...
}:
{
  home-manager.users.simon =
    { ... }:
    {
      imports = [
        self.modules.homeManager.bash
        self.modules.homeManager.bat
        self.modules.homeManager.btop
        self.modules.homeManager.dircolors
        self.modules.homeManager.direnv
        self.modules.homeManager.fish
        self.modules.homeManager.fzf
        self.modules.homeManager.git
        self.modules.homeManager.herdr
        self.modules.homeManager.jujutsu
        self.modules.homeManager.llm
        self.modules.homeManager.neovim
        self.modules.homeManager.ripgrep
        self.modules.homeManager.shellAliases
        self.modules.homeManager.shellIntegration
        self.modules.homeManager.starship
        self.modules.homeManager.yazi
        self.modules.homeManager.zellij
      ]
      ++ nflib.scanPaths ./. { };

      home = {
        username = "simon";
        homeDirectory = "/home/simon";
        packages = [
          # nix language servers for zed ssh remoting
          pkgs.nil
          pkgs.nixd
          pkgs.nixfmt
        ];
        sessionVariables = {
          SHELL = "${lib.getExe pkgs.fish}";
          BROWSER = "remote-open";
          EDITOR = "${lib.getExe pkgs.neovim}";
        };

        stateVersion = "25.11";
      };

      # exported in shellInit, not sessionVariables: herdr panes are non-login
      # shells and never source hm-session-vars. SSH_AUTH_SOCK = yubikey agent
      # forwarded from the attached client to a fixed path (users/simon/ssh.nix)
      programs.fish.shellInit = ''
        set -gx SSH_AUTH_SOCK /run/user/1000/ssh-agent.sock
        set -gx BROWSER remote-open
        set -gx EDITOR ${lib.getExe pkgs.neovim}
      '';

      # sign with the yubikey via the forwarded agent socket (same key as
      # users/simon/signing.nix); jj signs on push, which needs the attached
      # client anyway
      programs.git.signing.key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID3AsDe157avF+iFa1TavZHwjDpugyePDqJ6gaRNzGIA";
      programs.jujutsu.settings.signing.key =
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID3AsDe157avF+iFa1TavZHwjDpugyePDqJ6gaRNzGIA";

      systemd.user.startServices = "sd-switch";
      nix.channels = { };
    };

  # let ssh RemoteForward replace a stale forwarded gpg-agent socket (yubikey-forward.nix)
  services.openssh.settings.StreamLocalBindUnlink = true;

  # simon's yubikey pubkeys (same shared generator as modules/nixos/hardware/yubikey/gpg-ssh.nix)
  clan.core.vars.generators.yubikey = {
    share = true;
    files = {
      "gpg-pubkey.asc".secret = false;
      "id_yubikey.pub".secret = false;
    };
    script = "true";
  };

  programs.fish.enable = true;
  users.users.simon.shell = pkgs.fish;
  # keep the old workspace user's uid: /home data ownership and the hardcoded
  # /run/user/1000 gpg-agent forward path (users/simon/ssh.nix) survive the rename
  users.users.simon.uid = 1000;

  # reserve RAM for the interactive dev user against nix builds. MemoryMin/Low
  # only apply when every ancestor slice reserves at least as much, so
  # user.slice carries the same values
  systemd.slices."user".sliceConfig = {
    MemoryMin = "16G";
    MemoryLow = "32G";
  };
  systemd.slices."user-1000".sliceConfig = {
    MemoryMin = "16G";
    MemoryLow = "32G";
  };

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
