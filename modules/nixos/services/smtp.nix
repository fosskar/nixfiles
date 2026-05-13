{
  flake.modules.nixos.smtp =
    _:
    let
      smtpHost = "smtp.protonmail.ch";
      smtpPort = 587;
      smtpUser = "noreply@nx3.eu";
      smtpFrom = "noreply@nx3.eu";
    in
    {
      config = {
        clan.core.vars.generators.smtp = {
          prompts.password.description = "smtp password for ${smtpUser}";
          prompts.password.type = "hidden";
          files.password.secret = true;
          files."smtp-env".secret = true;
          script = ''
            PASSWORD=$(cat "$prompts/password")
            echo -n "$PASSWORD" > "$out/password"
            cat > "$out/smtp-env" <<EOF
            SMTP_HOST=${smtpHost}
            SMTP_PORT=${toString smtpPort}
            SMTP_USER=${smtpUser}
            SMTP_FROM=${smtpFrom}
            SMTP_PASSWORD=$PASSWORD
            EOF
          '';
        };
      };
    };
}
