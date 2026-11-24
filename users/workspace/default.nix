{
  config,
  inputs,
  lib,
  pkgs,
  self,
  nflib,
  ...
}:
let
  # a file, not a literal: git only takes a bare literal for "ssh-" key types
  phoneSshKey = pkgs.writeText "id_phonetpm.pub" "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBA4qpyAJl0h2gsRP1vLiCjuo+SCXwJ24jEMviE6tMouu/pR+3lnuG+RRNqaZ3MpeiahOYnbZxDK7hsTY9VlA1Mk=";
  yubikeySshKey = config.clan.core.vars.generators.yubikey.files."id_yubikey.pub".path;
  # sign with the yubikey while a client forwards its agent (socket relay),
  # else with the phone; git and jj pass the configured key as -f
  sshKeygen = pkgs.writeShellScript "ssh-keygen-agent-key" ''
    args=("$@")
    case " $* " in
      *" -Y sign "*)
        key=${phoneSshKey}
        if ${pkgs.openssh}/bin/ssh-add -L 2>/dev/null |
          ${pkgs.gnugrep}/bin/grep -qF "$(${pkgs.coreutils}/bin/cut -d' ' -f2 ${yubikeySshKey})"; then
          key=${yubikeySshKey}
        fi
        for i in "''${!args[@]}"; do
          if [ "''${args[$i]}" = -f ]; then args[$((i + 1))]=$key; fi
        done
        ;;
    esac
    exec ${pkgs.openssh}/bin/ssh-keygen "''${args[@]}"
  '';
in
{
  imports = [
    self.modules.nixos.llm
    self.modules.nixos.tern
    self.modules.nixos.ternServer
    self.modules.nixos.workspaceHost
  ];

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
        self.modules.homeManager.herdrCore
        self.modules.homeManager.hunk
        self.modules.homeManager.jujutsu
        self.modules.homeManager.k8s
        self.modules.homeManager.llm
        self.modules.homeManager.phonetpm
        self.modules.homeManager.radicle
        self.modules.homeManager.ripgrep
        self.modules.homeManager.sand
        self.modules.homeManager.shellAliases
        self.modules.homeManager.sofka
        self.modules.homeManager.tern
        self.modules.homeManager.ssh
        self.modules.homeManager.starship
        self.modules.homeManager.workspaceHost
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

          pkgs.fluxcd
        ];
        sessionVariables = {
          SHELL = "${lib.getExe pkgs.fish}";
          EDITOR = "${lib.getExe pkgs.micro}";
        };

        stateVersion = "25.11";
      };

      # exported in shellInit, not sessionVariables: herdr panes are non-login
      # shells and never source hm-session-vars
      programs.fish.shellInit = ''
        set -gx EDITOR ${lib.getExe pkgs.micro}
        # sops: the forwarded yubikey gpg-agent first, the phone ("age" is the
        # key label in the phonetpm app) when no client is attached
        set -gx SOPS_AGE_KEY_CMD "phonetpm identity age"
        set -gx SOPS_DECRYPTION_ORDER pgp,age
      '';

      programs.git.signing.key = "${phoneSshKey}";
      programs.git.signing.signer = "${sshKeygen}";
      programs.jujutsu.settings.signing = {
        key = "${phoneSshKey}";
        backends.ssh.program = "${sshKeygen}";
      };

      systemd.user.startServices = "sd-switch";
      nix.channels = { };
    };

  programs.fish.enable = true;
  users.users.simon.shell = pkgs.fish;
  users.users.simon.linger = true;
  # keep the old workspace user's uid: /home data ownership and the hardcoded
  # /run/user/1000 gpg-agent forward path (modules/home-manager/workspace/client.nix) survive the rename
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

  clan.core.vars.generators.workspace-buzz-orouter = {
    files = {
      "agent.env" = {
        owner = "simon";
        group = "users";
      };
      pubkey.secret = false;
    };
    runtimeInputs = [
      inputs.buzz-flake.packages.${pkgs.stdenv.hostPlatform.system}.buzz-relay
      pkgs.gnused
    ];
    script = ''
      keys=$(buzz-admin generate-key)
      private=$(printf '%s\n' "$keys" | sed -n 's/^Secret key:  *//p')
      public=$(printf '%s\n' "$keys" | sed -n 's/^Public key:  *//p')
      test -n "$private"
      test -n "$public"
      printf 'BUZZ_PRIVATE_KEY=%s\n' "$private" > "$out/agent.env"
      printf '%s\n' "$public" > "$out/pubkey"
    '';
  };

  clan.core.vars.generators.workspace-openrouter = {
    files."openrouter.env" = {
      owner = "simon";
      group = "users";
    };
    prompts.api-key = {
      type = "hidden";
      persist = true;
      description = "OpenRouter API key for workspace Buzz agents";
    };
    script = ''
      printf 'OPENROUTER_API_KEY=%s\n' "$(cat "$prompts/api-key")" > "$out/openrouter.env"
    '';
  };
}
