_: {
  # yubikey card extras for gpg; import alongside `gpg` (the general aspect).
  flake.modules.homeManager.yubikeyGpg =
    {
      lib,
      osConfig ? null,
      ...
    }:
    let
      gpgPubkeyPath =
        if osConfig != null then
          osConfig.clan.core.vars.generators.yubikey.files."gpg-pubkey.asc".path or null
        else
          null;
      sshPubkeyPath =
        if osConfig != null then
          osConfig.clan.core.vars.generators.yubikey.files."id_yubikey.pub".path or null
        else
          null;
    in
    {
      # place ssh public key in ~/.ssh/
      home.file.".ssh/id_yubikey.pub" = lib.mkIf (sshPubkeyPath != null) {
        source = sshPubkeyPath;
      };

      # import the card's public key into the keyring
      programs.gpg.publicKeys = lib.mkIf (gpgPubkeyPath != null) [
        { source = gpgPubkeyPath; }
      ];

      # force scdaemon through pcscd instead of its internal CCID driver
      programs.gpg.scdaemonSettings.disable-ccid = true;

      # gpg-agent provides the ssh key from the card's authentication slot
      services.gpg-agent = {
        enableSshSupport = true;
        defaultCacheTtlSsh = 14400; # 4h
        maxCacheTtlSsh = 86400; # 24h
      };
    };
}
