{
  lib,
  pkgs,
  self,
  mylib,
  ...
}:
{
  home-manager.users.workspace =
    { config, osConfig, ... }:
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
        self.modules.homeManager.jujutsu
        self.modules.homeManager.llm
        self.modules.homeManager.neovim
        self.modules.homeManager.ripgrep
        self.modules.homeManager.shellAliases
        self.modules.homeManager.shellIntegration
        self.modules.homeManager.theme
        self.modules.homeManager.starship
        self.modules.homeManager.yazi
        self.modules.homeManager.zellij
      ]
      ++ mylib.scanPaths ./. { };

      home = {
        username = "workspace";
        homeDirectory = "/home/workspace";
        packages = [
          pkgs.custom.kittylitter
        ];
        sessionVariables = {
          SHELL = "${lib.getExe pkgs.fish}";
          BROWSER = "zen";
          EDITOR = "${lib.getExe pkgs.neovim}";
        };

        stateVersion = "25.11";
      };

      home.file = {
        ".ssh/id_ed25519".source =
          config.lib.file.mkOutOfStoreSymlink
            osConfig.clan.core.vars.generators.workspace-ssh.files."id_ed25519".path;
        ".ssh/id_ed25519.pub".source =
          config.lib.file.mkOutOfStoreSymlink
            osConfig.clan.core.vars.generators.workspace-ssh.files."id_ed25519.pub".path;
      };

      # per-user ssh signing key (the clan-generated workspace key)
      programs.git.signing.key =
        osConfig.clan.core.vars.generators.workspace-ssh.files."id_ed25519.pub".value;
      programs.jujutsu.settings.signing.key =
        osConfig.clan.core.vars.generators.workspace-ssh.files."id_ed25519.pub".value;

      # declarative replacement for `kittylitter install` autostart
      systemd.user.services.kittylitter = {
        Unit = {
          Description = "Alleycat bridge daemon (kittylitter)";
          After = [ "network-online.target" ];
          Wants = [ "network-online.target" ];
        };
        Service = {
          Type = "simple";
          ExecStart = "${pkgs.custom.kittylitter}/bin/kittylitter serve";
          # dump the (stable) pair payload + QR for clients to scan
          ExecStartPost = pkgs.writeShellScript "kittylitter-pair-dump" ''
            out="${config.home.homeDirectory}/.local/state/kittylitter"
            mkdir -p "$out"
            sleep 2
            ${pkgs.custom.kittylitter}/bin/kittylitter pair --qr > "$out/pair.txt" || true
          '';
          Environment = [ "PATH=${config.home.profileDirectory}/bin" ];
          Restart = "on-failure";
          RestartSec = 5;
        };
        Install.WantedBy = [ "default.target" ];
      };

      systemd.user.startServices = "sd-switch";
      nix.channels = { };
    };

  programs.fish.enable = true;
  users.users.workspace.shell = pkgs.fish;
  # run the kittylitter user daemon at boot, not just at login
  users.users.workspace.linger = true;

  clan.core.vars.generators.workspace-ssh = {
    files."id_ed25519".owner = "workspace";
    files."id_ed25519.pub".secret = false;
    runtimeInputs = [ pkgs.openssh ];
    script = ''
      ssh-keygen -t ed25519 -N "" -C "workspace@nixworker" -f "$out/id_ed25519" -q
    '';
  };
}
