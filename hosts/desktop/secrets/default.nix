{ inputs, config, ... }:
# for CI/CD puprose currently not used
let
  inCI = builtins.getEnv "CI" == "true";

  secretsPath =
    if inCI then
      "${builtins.getEnv "CI_PROJECT_DIR"}/nixsecrets/secrets/simon/secrets.yaml"
    else
      "/home/simon/code/nixsecrets/secrets/simon/secrets.yaml";
in
{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  sops = {
    validateSopsFiles = false;
    defaultSopsFile = secretsPath;
    age = {
      sshKeyPaths = [ "/home/simon/.ssh/id_ed25519" ];
      keyFile = "/home/simon/.config/sops/age/keys.txt";
      generateKey = false;
    };
    secrets = {
      c3NoLXB1Yi1rZXk = {
        path = "/home/simon/.ssh/id_ed25519.pub";
        owner = "simon";
        mode = "0600";
      };
      c3NoLXByaXZhdGUta2V5 = {
        path = "/home/simon/.ssh/id_ed25519";
        owner = "simon";
        mode = "0600";
      };
      dXNlcl9wYXNzd29yZA = {
        owner = "simon";
        mode = "0644";
      };

      u2f_keys = {
        path = "/home/simon/.yubico/authorized_yubikeys";
        owner = "simon";
        mode = "0644";
      };
    };
  };
}
