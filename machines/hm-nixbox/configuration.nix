{ mylib, ... }:
{
  imports = [
    ../../modules/zfs
    ../../modules/gpu
    ../../modules/cpu
    ../../modules/power
  ]
  ++ (mylib.scanPaths ./. {
    exclude = [
      "dashboards"
      "radicle.nix"
      "matrix-synapse.nix"
      "lldap.nix"
      "authelia.nix"
      "kanidm.nix"
    ];
  });

  nixpkgs.hostPlatform = "x86_64-linux";

  clan.core.settings.machine-id.enable = true;

  nixfiles = {
    gpu.intel.enable = true;
    cpu.amd.enable = true;
    power.tuned = {
      enable = true;
      profile = "server-powersave";
    };
  };

  # systemd-boot doesn't support mirroredBoots yet (nixpkgs#152155)
  boot = {
    kernelModules = [ "nct6775" ];
    loader = {
      systemd-boot.enable = false;
      grub = {
        enable = true;
        device = "nodev";
        mirroredBoots = [
          {
            devices = [ "nodev" ];
            path = "/boot";
          }
          {
            devices = [ "nodev" ];
            path = "/boot-fallback";
          }
        ];
      };
    };
    zfs.extraPools = [ "tank" ];
  };
}
