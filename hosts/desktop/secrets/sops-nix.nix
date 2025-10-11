{
  inputs,
  config,
  ...
}:
let
  secretsFile = "${inputs.nixsecrets}/sops-nix/simon/secrets.yaml";
in
{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  sops = {
    validateSopsFiles = true;
    defaultSopsFile = secretsFile;

    # age
    age = {
      sshKeyPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];
      #
      #  # i use ssh key ed25519 so i can generate age key directly from it. so i neither need to reference an age key nor do i need to backup my age key.
      #  # this is very convinient
      #  #keyFile = "${config.users.users.simon.home}/.config/sops/age/keys.txt";
      #  #generateKey = false;
    };

    # disable importing host ssh keys
    gnupg.sshKeyPaths = [ ];

    # secrets
    secrets = {
      "yubikey/id_yubikey.pub" = {
        path = "${config.users.users.simon.home}/.ssh/id_yubikey.pub";
        owner = "simon";
        mode = "0600";
      };
      "yubikey/u2f_keys" = { };

      "samba" = { };

      "nix/access-tokens/github" = {
        mode = "0444";
      };
      "api/openrouter" = {
        owner = "simon";
        mode = "0600";
      };
    };
  };
}
