{ inputs, ... }:
{
  imports = [
    ../../modules/secrets
  ];

  age.secrets."fileserver-passwords" = {
    rekeyFile = "${inputs.nixsecrets}/agenix/nixinfra/fileserver/user_passwords.age";
    mode = "400";
  };
}
