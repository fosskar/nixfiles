{
  flake.modules.nixos.yubikey =
    {
      pkgs,
      ...
    }:
    {
      # smartcard support
      services.pcscd.enable = true;

      # redundant: card access is polkit-mediated via the pcsclite-with-polkit
      # socket, and the daemon reaches the device through its own pcscd group.
      # users.groups.pcscd.members = lib.mkAfter config.users.groups.wheel.members;

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
