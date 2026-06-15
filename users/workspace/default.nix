{
  lib,
  pkgs,
  self,
  nflib,
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
      ++ nflib.scanPaths ./. { };

      home = {
        username = "workspace";
        homeDirectory = "/home/workspace";
        packages = [
          pkgs.local.kittylitter
          # nix language servers for zed ssh remoting
          pkgs.nil
          pkgs.nixd
          pkgs.nixfmt
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

      # auto-attach the persistent "workspace" zellij session on ssh logins so
      # any client (desktop/laptop) lands in the same long-running state. zed
      # terminals are excluded: agent panel terminal threads must run their
      # agent, not attach the session; attach manually there with `za`.
      programs.fish.interactiveShellInit = ''
        if set -q SSH_CONNECTION; and not set -q ZELLIJ; and not set -q ZED_TERM; and isatty stdin
          exec zellij attach -c workspace
        end
      '';
      programs.fish.shellAbbrs.za = "zellij attach -c workspace";

      # key file path: git/jj sign with the on-disk key, no ssh-agent involved
      programs.git.signing.key = "~/.ssh/id_ed25519";
      programs.jujutsu.settings.signing.key = "~/.ssh/id_ed25519";

      # declarative replacement for `kittylitter install` autostart
      systemd.user.services.kittylitter = {
        Unit = {
          Description = "Alleycat bridge daemon (kittylitter)";
          After = [ "network-online.target" ];
          Wants = [ "network-online.target" ];
        };
        Service = {
          Type = "simple";
          ExecStart = "${pkgs.local.kittylitter}/bin/kittylitter serve";
          # dump the (stable) pair payload + QR for clients to scan
          ExecStartPost = pkgs.writeShellScript "kittylitter-pair-dump" ''
            out="${config.home.homeDirectory}/.local/state/kittylitter"
            mkdir -p "$out"
            sleep 2
            ${pkgs.local.kittylitter}/bin/kittylitter pair --qr > "$out/pair.txt" || true
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
  users.users.workspace.shell = pkgs.fish;
  # run the kittylitter user daemon at boot, not just at login
  users.users.workspace.linger = true;

  # session link for kagi-search skill (modules/home/llm/skills)
  clan.core.vars.generators.kagi = {
    share = true;
    files."session-link".owner = "workspace";
    prompts."session-link" = {
      type = "hidden";
      persist = true;
      description = "kagi session link";
    };
  };

  clan.core.vars.generators.workspace-ssh = {
    files."id_ed25519".owner = "workspace";
    files."id_ed25519.pub".secret = false;
    runtimeInputs = [ pkgs.openssh ];
    script = ''
      ssh-keygen -t ed25519 -N "" -C "workspace@nixworker" -f "$out/id_ed25519" -q
    '';
  };
}
