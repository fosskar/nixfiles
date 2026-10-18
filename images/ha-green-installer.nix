{
  config,
  modulesPath,
  pkgs,
  ...
}:
let
  authorizedKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID3AsDe157avF+iFa1TavZHwjDpugyePDqJ6gaRNzGIA openpgp:0xDA6712BE"
    "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBG7nahd/01skftk7ujmj2F2T8vzqUH/UWqQViSz7XEVaQbPIEYTwR6V/TpFx54wKlzJA75BDV+fHIBJsmhNzd3U="
  ];
in
{
  imports = [
    # sets VARIANT_ID=installer, so nixos-anywhere (clan machines install) skips kexec
    "${modulesPath}/profiles/installation-device.nix"
    "${modulesPath}/installer/sd-card/sd-image.nix"
  ];

  sdImage = {
    # keep the first 16 MiB clear like haos does; the green's u-boot spl probes sd at 8 MiB
    firmwarePartitionOffset = 16;
    # booted from usb, the stick doubles as haos's CONFIG stick: haos imports
    # authorized_keys from it and opens root ssh on port 22222
    firmwarePartitionName = "CONFIG";
    populateFirmwareCommands = ''
      cp ${
        pkgs.writeText "authorized_keys" (builtins.concatStringsSep "\n" authorizedKeys + "\n")
      } firmware/authorized_keys
    '';
    populateRootCommands = ''
      mkdir -p ./files/boot
      ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d ./files/boot
    '';
  };

  users.users.root.openssh.authorizedKeys.keys = authorizedKeys;

  # clan machines init-hardware-config --backend nixos-facter runs it on the target
  environment.systemPackages = [ pkgs.nixos-facter ];

  networking.hostName = "ha-green-installer";

  system.stateVersion = "26.05";
}
