{
  config,
  pkgs,
  inputs,
  ...
}: let
  userhome = config.users.users.oscar.home;
  username = config.users.users.oscar.name;
in {
  imports = [inputs.sops-nix.nixosModules.sops];

  services = {
    openssh = {
      enable = true;
      settings = {
        #PasswordAuthentication = true;
        #KbdInteractiveAuthentication = false;
        challengeResponseAuthentication = false;
        X11Forwarding = false;
        KexAlgorithms = [
          "curve25519-sha256"
          "curve25519-sha256@libssh.org"
          "diffie-hellman-group16-sha512"
          "diffie-hellman-group18-sha512"
          "sntrup761x25519-sha512@openssh.com"
        ];
      };
      extraConfig = ''
        StreamLocalBindUnlink yes
        AllowTcpForwarding yes
        AllowAgentForwarding no
        AllowStreamLocalForwarding no
      '';
    };
  };
  sops = {
    validateSopsFiles = false;
    defaultSopsFile = "${userhome}/nixsecrets/secrets/oscar/secrets.yaml";
    age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
    secrets = {
      c3NoLXB1Yi1rZXk = {
        mode = "0600";
        owner = "${username}";
        path = "${userhome}/.ssh/authorized_keys";
      };
      c3NoLXByaXZhdGUta2V5 = {
        mode = "0600";
        owner = "${username}";
        path = "${userhome}/.ssh/id_ed25519";
      };
      V0lGSQ = {
        path = "/etc/wpa_supplicant.conf";
      };
    };
  };
}
