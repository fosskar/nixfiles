{ inputs, ... }:
{
  imports = [
    ../../modules/secrets
  ];

  age.secrets = {
    nextcloud-admin-pw = {
      rekeyFile = "${inputs.nixsecrets}/agenix/nixinfra/nextcloud/admin-pw.age";
    };
  };
}
