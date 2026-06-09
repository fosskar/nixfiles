_: {
  flake.modules.nixos.msmtp =
    {
      config,
      pkgs,
      ...
    }:
    let
      smtpHost = "smtp.mailbox.org";
      smtpPort = 587;
      smtpFrom = "noreply@nx3.eu";
      varsPath = config.clan.core.vars.generators.smtp;
    in
    {
      config = {
        programs.msmtp = {
          enable = true;
          setSendmail = true;
          accounts.default = {
            auth = true;
            tls = true;
            tls_starttls = true;
            host = smtpHost;
            port = smtpPort;
            from = smtpFrom;
            # read the username from a runtime secret via msmtp's `eval`
            # directive so it stays out of the nix store and the repo.
            eval = ''echo user "$(${pkgs.coreutils}/bin/cat ${varsPath.files.username.path})"'';
            passwordeval = "${pkgs.coreutils}/bin/cat ${varsPath.files.password.path}";
          };
        };
      };
    };
}
