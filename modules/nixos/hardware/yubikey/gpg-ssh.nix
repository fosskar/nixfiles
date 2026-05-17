{
  flake.modules.nixos.yubikeyGpgSsh =
    { pkgs, ... }:
    {
      # public keys published via clan vars (generator does nothing; values persist)
      clan.core.vars.generators.yubikey = {
        share = true;
        files = {
          "gpg-pubkey.asc".secret = false;
          "id_yubikey.pub".secret = false;
        };
        script = "true";
      };

      programs.gnupg.agent.enableSSHSupport = true;

      # disable ssh-agent (GPG handles SSH)
      programs.ssh.startAgent = false;

      hardware.gpgSmartcards.enable = true;

      # systemd uaccess can leave the owning group ACL as --- after YubiKey
      # re-enumeration, which prevents pcscd from opening the CCID interface.
      services.udev.extraRules = ''
        SUBSYSTEM=="usb", ATTR{idVendor}=="1050", ENV{ID_USB_INTERFACES}=="*:0b0000:*", GROUP="pcscd", MODE="0660", RUN+="${pkgs.acl}/bin/setfacl -m g::rw $env{DEVNAME}"
      '';
    };
}
