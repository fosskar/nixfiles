{
  pkgs,
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

  programs.gpg = {
    enable = true;
    publicKeys = lib.mkIf (gpgPubkeyPath != null) [
      { source = gpgPubkeyPath; }
    ];
    scdaemonSettings = {
      disable-ccid = true;
    };
    # https://github.com/drduh/config/blob/master/gpg.conf
    settings = {
      personal-cipher-preferences = "AES256 AES192 AES";
      personal-digest-preferences = "SHA512 SHA384 SHA256";
      personal-compress-preferences = "ZLIB BZIP2 ZIP Uncompressed";
      default-preference-list = "SHA512 SHA384 SHA256 AES256 AES192 AES ZLIB BZIP2 ZIP Uncompressed";
      cert-digest-algo = "SHA512";
      s2k-digest-algo = "SHA512";
      s2k-cipher-algo = "AES256";
      charset = "utf-8";
      fixed-list-mode = true;
      no-comments = true;
      no-emit-version = true;
      no-greeting = true;
      keyid-format = "0xlong";
      list-options = "show-uid-validity";
      verify-options = "show-uid-validity";
      with-fingerprint = true;
      require-cross-certification = true;
      require-secmem = true;
      no-symkey-cache = true;
      armor = true;
      use-agent = true;
      throw-keyids = true;
      pinentry-mode = "ask";
    };
  };
  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    pinentry.package = pkgs.pinentry-qt;
    # https://github.com/drduh/config/blob/master/gpg-agent.conf
    defaultCacheTtl = 86400; # 24 hours
    maxCacheTtl = 604800; # 7 days
    defaultCacheTtlSsh = 86400; # 24 hours for ssh
    maxCacheTtlSsh = 604800; # 7 days max for ssh
    extraConfig = ''
      ttyname $GPG_TTY
      allow-loopback-pinentry
    '';
  };
}
