{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.nixfiles.yubikey;
in
{
  config = lib.mkIf cfg.enable {
    # GPG agent with SSH support (overrides base gpg.nix)
    programs.gnupg.agent.enableSSHSupport = true;

    # disable ssh-agent (GPG handles SSH)
    programs.ssh.startAgent = false;

    # smartcard support
    hardware.gpgSmartcards.enable = true;

    # pcscd for smartcard
    services.pcscd.enable = true;

    # add wheel users to pcscd group
    users.groups.pcscd.members = config.users.groups.wheel.members;

    # udev rules
    services.udev.packages = [ pkgs.yubikey-personalization ];

    # packages
    environment.systemPackages = with pkgs; [
      yubikey-manager
      yubikey-personalization
      age-plugin-yubikey
    ];
  };
}
