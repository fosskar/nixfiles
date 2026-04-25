{ config, ... }:
{
  flake.modules.nixos.yubikeyGpgSsh = {
    imports = [ config.flake.modules.nixos.yubikey ];

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
  };
}
