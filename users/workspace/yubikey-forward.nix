# gpg via simon's forwarded gpg-agent socket (users/simon/ssh.nix); no key material here
{ osConfig, ... }:
{
  programs.gpg = {
    enable = true;
    # never spawn a local gpg-agent; the socket arrives via ssh RemoteForward
    settings.no-autostart = true;
    publicKeys = [
      {
        # simon's yubikey gpg pubkey, published as non-secret shared clan var
        source = osConfig.clan.core.vars.generators.yubikey.files."gpg-pubkey.asc".path;
        trust = "ultimate";
      }
    ];
  };

  # no-autostart also blocks keyboxd; force keyboxd off (gpg falls back to
  # pubring.kbx) instead of the gpg-generated common.conf with use-keyboxd
  home.file.".gnupg/common.conf".text = "";
}
