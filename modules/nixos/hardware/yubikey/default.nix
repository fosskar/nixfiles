{
  flake.modules.nixos.yubikey =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      # smartcard support
      services.pcscd.enable = true;

      # add wheel users to pcscd group
      users.groups.pcscd.members = lib.mkAfter config.users.groups.wheel.members;

      # udev rules
      services.udev.packages = [
        pkgs.yubikey-personalization
      ];

      programs.yubikey-touch-detector.enable = true;

      environment.systemPackages = [
        pkgs.yubikey-manager
        pkgs.yubikey-personalization
        pkgs.age-plugin-yubikey
      ];
    };
}
