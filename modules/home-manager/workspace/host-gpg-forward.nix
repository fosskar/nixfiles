# gpg via the client's forwarded gpg-agent socket (client.nix); no key material here
_: {
  flake.modules.homeManager.workspaceHost =
    { osConfig, ... }:
    {
      programs.gpg = {
        enable = true;
        mutableTrust = false;
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
    };
}
