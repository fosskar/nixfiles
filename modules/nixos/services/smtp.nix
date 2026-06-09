{
  flake.modules.nixos.smtp =
    _:
    let
      smtpHost = "smtp.mailbox.org";
      smtpPort = 587;
      smtpFrom = "noreply@nx3.eu";
    in
    {
      config = {
        clan.core.vars.generators.smtp = {
          prompts.username.description = "mailbox smtp username";
          prompts.username.type = "line";
          prompts.password.description = "mailbox smtp email-app-password";
          prompts.password.type = "hidden";
          files.username.secret = true;
          files.password.secret = true;
          files."smtp-env".secret = true;
          script = ''
            USERNAME=$(cat "$prompts/username")
            PASSWORD=$(cat "$prompts/password")
            echo -n "$USERNAME" > "$out/username"
            echo -n "$PASSWORD" > "$out/password"
            cat > "$out/smtp-env" <<EOF
            SMTP_HOST=${smtpHost}
            SMTP_PORT=${toString smtpPort}
            SMTP_USER=$USERNAME
            SMTP_USERNAME=$USERNAME
            SMTP_FROM=${smtpFrom}
            SMTP_PASSWORD=$PASSWORD
            SMTP_SECURITY=starttls
            EOF
          '';
        };
      };
    };
}
