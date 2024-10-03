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
      sshKeyPaths = [ "${config.users.users.simon.home}/.ssh/id_ed25519" ];

      # i use ssh key ed25519 so i can generate age key directly from it. so i neither need to reference an age key nor do i need to backup my age key.
      # this is very convinient
      #keyFile = "${config.users.users.simon.home}/.config/sops/age/keys.txt";
      generateKey = true;
    };

    # disable importing host ssh keys
    gnupg.sshKeyPaths = [ ];

    # secrets
    secrets = {
      "ssh/id_ed25519.pub" = {
        path = "${config.users.users.simon.home}/.ssh/id_ed25519.pub";
        owner = "simon";
        mode = "0600";
      };
      "ssh/id_ed25519" = {
        path = "${config.users.users.simon.home}/.ssh/id_ed25519";
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
        path = "${config.users.users.simon.home}/.yubico/authorized_yubikeys";
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
