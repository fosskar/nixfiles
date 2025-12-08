{ config, lib, ... }:
{
  boot = {
    initrd.systemd.enable = lib.mkDefault (!config.boot.swraid.enable && !config.boot.isContainer);

    tmp.cleanOnBoot = lib.mkDefault true;
  };
}
