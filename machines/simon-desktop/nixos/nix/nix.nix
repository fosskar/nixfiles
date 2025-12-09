{
  config,
  ...
}:
{
  nix = {
    settings = {
      accept-flake-config = false;

      allowed-users = [
        "root"
        "@wheel"
      ];
      system-features = [
        "kvm"
        "big-parallel"
      ];
      flake-registry = "/etc/nix/registry.json";
    };

    gc.automatic = false; # using nh.clean instead

    extraOptions = ''
      !include ${config.sops.secrets."nix-access-tokens".path}
    '';
  };
}
