{
  config,
  inputs,
  ...
}: let
  userhome = "/home/simon";
in {
  sops = {
    validateSopsFiles = false;
    defaultSopsFile = "${userhome}/nixsecrets/secrets/simon/secrets.yaml";
    age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";
    secrets = {
      c3NoLXB1Yi1rZXk = {
        mode = "0600";
        path = "${userhome}/.ssh/id_ed25519.pub";
      };
      c3NoLXByaXZhdGUta2V5 = {
        mode = "0600";
        path = "${userhome}/.ssh/id_ed25519";
      };
    };
  };
}
