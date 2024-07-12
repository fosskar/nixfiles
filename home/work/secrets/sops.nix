{ config, inputs, ... }:
{
  sops = {
    validateSopsFiles = false;
    defaultSopsFile = "${config.home.homeDirectory}/code/nixsecrets/secrets/work/secrets.yaml";
    age = {
      #sshKeyPaths = [ "${config.home.homeDirectory}/.ssh/id_rsa" ]; # only working with ed25519
      keyFile = "${config.xdg.configHome}/sops/age/keys.txt";
      generateKey = false;
    };
    secrets = {
      aWRfcnNhLnB1Yg = {
        path = "${config.home.homeDirectory}/.ssh/id_rsa.pub";
        mode = "0600";
      };
      aWRfcnNh = {
        path = "${config.home.homeDirectory}/.ssh/id_rsa";
        mode = "0600";
      };
      ZW1haWw = { };

      dXNlcnBhc3N3b3Jk = { };
    };
  };
}
