{ inputs, ... }:
let
  secretsFile = "${inputs.nixsecrets}/sops-nix/server/secrets.yaml";
in
{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  sops = {
    validateSopsFiles = true;
    defaultSopsFile = secretsFile;
    age = {
      sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      generateKey = true;
    };
    secrets = {
      "ssh/authorized_keys" = {
        path = "etc/nixos/ssh/authorized_keys";
      };

      "user/root/hashed_password" = { };
    };
  };
}
