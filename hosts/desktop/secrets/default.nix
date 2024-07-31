{ inputs, config, ... }:
let
  secretsDirectory = builtins.toString inputs.nixsecrets;
  secretsFile = "${secretsDirectory}/secrets/simon/secrets.yaml";
in
{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  sops = {
    validateSopsFiles = true;
    defaultSopsFile = secretsFile;

    # age
    age = {
      sshKeyPaths = [ "/home/simon/.ssh/id_ed25519" ];

      # i use ssh key
      keyFile = "/home/simon/.config/sops/age/keys.txt";
      generateKey = false;
    };

    # disable importing host ssh keys
    gnupg.sshKeyPaths = [ ];

    # secrets
    secrets = {
      "ssh/id_ed25519.pub" = {
        path = "/home/simon/.ssh/id_ed25519.pub";
        owner = "simon";
        mode = "0600";
      };
      "ssh/id_ed25519" = {
        path = "/home/simon/.ssh/id_ed25519";
        owner = "simon";
        mode = "0600";
      };
      "user/password" = {
        neededForUsers = true;
      };
      "user/pin" = {
        neededForUsers = true;
      };

      "yubikey/u2f_keys" = {
        path = "/home/simon/.yubico/authorized_yubikeys";
        owner = "simon";
        mode = "0644";
      };
      "git/github/github-pat" = { };
      "git/github/fg-github-pat" = { };

      "git/gitlab/gitlab-pat" = { };
    };
    templates = {
      "nix-access-tokens".content = ''access-tokens = github.com=${
        config.sops.placeholder."git/github/github-pat"
      }'';
    };
  };
}
