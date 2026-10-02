{
  inputs,
  lib,
  pkgs,
  self,
  nflib,
  ...
}:
{
  imports = [
    self.modules.nixos.llm
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
        self.modules.homeManager.herdr
        self.modules.homeManager.hunk
        self.modules.homeManager.jujutsu
        self.modules.homeManager.k8s
        self.modules.homeManager.llm
        self.modules.homeManager.radicle
        self.modules.homeManager.ripgrep
        self.modules.homeManager.shellAliases
        self.modules.homeManager.ssh
        self.modules.homeManager.starship
        self.modules.homeManager.workspaceHost
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

  programs.fish.enable = true;
  programs.mosh.enable = true;
  users.users.simon.shell = pkgs.fish;
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
