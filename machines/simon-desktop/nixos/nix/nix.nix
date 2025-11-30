{
  config,
  lib,
  pkgs,
  ...
}:
{
  nix = {
    #package = pkgs.nixVersions.latest; # nixVersions.latest, lix
    #package = pkgs.lix;
    nixPath = [ "nixpkgs=flake:nixpkgs" ];

    channel.enable = false;

    daemonCPUSchedPolicy = "idle";
    daemonIOSchedClass = "idle";
    daemonIOSchedPriority = 7;

    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ]
      ++ lib.optional (lib.versionOlder (lib.versions.majorMinor config.nix.package.version) "2.22") "repl-flake";
      # Whether to accept nix configuration from a flake
      # without displaying a Y/N prompt. For those obtuse
      # enough to keep this true, I wish the best of luck.
      accept-flake-config = false;
      # increase buffer size for large remote deployments to prevent transfer failures
      download-buffer-size = 256 * 1024 * 1024; # 256 MB
      auto-optimise-store = true;
      builders-use-substitutes = true;
      allowed-users = [
        "root"
        "@wheel"
      ];
      trusted-users = [
        "root"
        "@wheel"
      ];
      system-features = [
        "kvm"
        "big-parallel"
      ];
      flake-registry = "/etc/nix/registry.json";
      log-lines = 25;
      # Continue building derivations even if one fails
      keep-going = true;
      # for direnv garbage-collection roots
      keep-derivations = true;
      keep-outputs = true;
      fallback = true;
      # Don't warn me that my git tree is dirty, I know.
      warn-dirty = false;
    };
    gc = {
      automatic = false; # because i am using nh.clean
      #dates = "weekly";
      #options = "--delete-older-than 1w";
    };
    optimise = {
      automatic = true;
    };
    extraOptions = ''
      !include ${config.sops.secrets."nix-access-tokens".path}
    '';
  };
  # Make builds to be more likely killed than important services.
  # 100 is the default for user slices and 500 is systemd-coredumpd@
  # We rather want a build to be killed than our precious user sessions as builds can be easily restarted.
  systemd.services.nix-daemon.serviceConfig.OOMScoreAdjust = lib.mkDefault 250;
}
