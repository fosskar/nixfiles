{
  config,
  pkgs,
  ...
}: let
  nixsecrets = builtins.fetchGit {
    url = "git+ssh://git@gitlab.com/simonoscr/nixsecrets";
    ref = "main";
    rev = "92606f086784c55203a971b756a59c44512447fe";
  };
in {
  sops = {
    validateSopsFiles = true;
    defaultSopsFile = "${nixsecrets}/secrets/simon/secrets.yaml";
    age = {
      sshKeyPaths = ["${config.home.homeDirectory}/.ssh/id_ed25519"];
      keyFile = "${config.xdg.configHome}/sops/age/keys.txt";
      generateKey = false;
    };
    secrets = {
      c3NoLXB1Yi1rZXk = {
        path = "${config.home.homeDirectory}/.ssh/id_ed25519.pub";
      };
      c3NoLXByaXZhdGUta2V5 = {
        path = "${config.home.homeDirectory}/.ssh/id_ed25519";
      };
      dXNlcl9wYXNzd29yZA = {};
    };
  };
  systemd.user.services.mbsync.Unit.After = ["sops-nix.service"];
}
