{config, ...}: let
  inCI = builtins.getEnv "CI" == "true";
  secretsPath =
    if inCI
    then "${builtins.getEnv "CI_PROJECT_DIR"}/nixsecrets/secrets/simon/secrets.yaml"
    else "${config.home.homeDirectory}/nixsecrets/secrets/simon/secrets.yaml";
in {
  sops = {
    validateSopsFiles = false;
    defaultSopsFile = secretsPath;
    age = {
      sshKeyPaths = ["${config.home.homeDirectory}/.ssh/id_ed25519"];
      keyFile = "${config.xdg.configHome}/sops/age/keys.txt";
      generateKey = false;
    };
    secrets = {
      c3NoLXB1Yi1rZXk = {
        path = "${config.home.homeDirectory}/.ssh/id_ed25519.pub";
        mode = "0600";
      };
      c3NoLXByaXZhdGUta2V5 = {
        path = "${config.home.homeDirectory}/.ssh/id_ed25519";
        mode = "0600";
      };
      dXNlcl9wYXNzd29yZA = {};
    };
  };
}
