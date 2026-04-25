{
  flake.modules.nixos.workstation =
    {
      lib,
      config,
      ...
    }:
    {
      # srvos.desktop sets: daemonCPUSchedPolicy = "idle"

      assertions = [
        {
          assertion = config.programs.nh.enable -> config.programs.nh.flake != null;
          message = "programs.nh.flake must be set when nh is enabled";
        }
      ];

      clan.core.vars.generators.nix-access-tokens = {
        files.tokens.secret = true;
        prompts.tokens = {
          description = "nix access-tokens line (e.g. access-tokens = github.com=ghp_...)";
          type = "multiline";
          persist = true;
        };
        script = "cat $prompts/tokens > $out/tokens";
      };

      nix.extraOptions = ''
        !include ${config.clan.core.vars.generators.nix-access-tokens.files.tokens.path}
      '';

      # cross-build for aarch64 (e.g. nix-on-droid)
      boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

      # allow running unpatched binaries (editor LSPs, AppImages, etc.)
      programs.nix-ld.enable = true;

      # envfs — fuse mount on /usr/bin that resolves shebangs dynamically
      # makes #!/usr/bin/python3, #!/usr/bin/env bash, etc. work for unpatched scripts
      services.envfs.enable = lib.mkDefault true;

      # nh - nix helper for desktop users
      programs.nh = {
        enable = lib.mkDefault true;
        flake = lib.mkDefault "${config.users.users.simon.home}/code/nixfiles";
        clean = {
          enable = lib.mkDefault true;
          extraArgs = lib.mkDefault "--keep 5 --keep-since 3d";
        };
      };
    };
}
