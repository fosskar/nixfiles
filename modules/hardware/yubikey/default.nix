{
  flake.modules.nixos.yubikey =
    { pkgs, config, ... }:
    {
      # smartcard support
      services.pcscd.enable = true;

      # add wheel users to pcscd group
      users.groups.pcscd.members = config.users.groups.wheel.members;

      # udev rules
      services.udev.packages = [ pkgs.yubikey-personalization ];

      environment.systemPackages = with pkgs; [
        yubikey-manager
        yubikey-personalization
        age-plugin-yubikey
      ];
    };
}
