{ inputs, ... }:
{
  imports = [
    ../../../../modules/secrets
  ];

  age.secrets = {
    # minimal - no owner/group (for systemd credentials)
    jwt-secret.rekeyFile = "${inputs.nixsecrets}/agenix/nixinfra/authelia/jwt_secret.age";
    session-secret.rekeyFile = "${inputs.nixsecrets}/agenix/nixinfra/authelia/session_secret.age";
    storage-encryption-key.rekeyFile = "${inputs.nixsecrets}/agenix/nixinfra/authelia/storage_encryption_key.age";

    # with owner/group (for direct file approach) - commented out
    #jwt-secret = {
    #  rekeyFile = "${inputs.nixsecrets}/agenix/nixinfra/authelia/jwt_secret.age";
    #  owner = "authelia-main";
    #  group = "authelia-main";
    #};
    #session-secret = {
    #  rekeyFile = "${inputs.nixsecrets}/agenix/nixinfra/authelia/session_secret.age";
    #  owner = "authelia-main";
    #  group = "authelia-main";
    #};
    #storage-encryption-key = {
    #  rekeyFile = "${inputs.nixsecrets}/agenix/nixinfra/authelia/storage_encryption_key.age";
    #  owner = "authelia-main";
    #  group = "authelia-main";
    #};
  };

  # create group if using direct file approach
  #users.groups.authelia-main = {};
}
