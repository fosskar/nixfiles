_: {
  flake.modules.nixos.msmtp =
    {
      config,
      pkgs,
      ...
    }:
    let
      smtpHost = "smtp.protonmail.ch";
      smtpPort = 587;
      smtpUser = "noreply@nx3.eu";
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
            user = smtpUser;
            from = smtpFrom;
            passwordeval = "${pkgs.coreutils}/bin/cat ${varsPath.files.password.path}";
          };
        };
      };
    };
}
