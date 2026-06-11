# gpg through simon's forwarded gpg-agent socket (see workspace host block in
# users/simon/ssh.nix): sops/clan decrypt via the pgp recipient, pin/touch
# happens on simon's machine, no key material on this host.
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
