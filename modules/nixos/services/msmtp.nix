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
      sendmail = pkgs.writeShellScript "sendmail-msmtp" ''
        exec ${pkgs.msmtp}/bin/msmtp \
          --host=${smtpHost} \
          --port=${toString smtpPort} \
          --auth=on \
          --tls=on \
          --tls-starttls=on \
          --user="$(${pkgs.coreutils}/bin/cat ${varsPath.files.username.path})" \
          --passwordeval="${pkgs.coreutils}/bin/cat ${varsPath.files.password.path}" \
          --from=${smtpFrom} \
          "$@"
      '';
    in
    {
      config = {
        environment.systemPackages = [ pkgs.msmtp ];

        services.mail.sendmailSetuidWrapper = {
          program = "sendmail";
          source = sendmail;
          setuid = false;
          setgid = false;
          owner = "root";
          group = "root";
        };
      };
    };
}
