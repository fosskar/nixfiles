{
  config,
  lib,
  ...
}:
with lib;

let
  cfg = config.module.terminal.shell.aliases;
in
{
  options.module.terminal.shell.aliases = {
    enable = mkEnableOption "Enable global aliases";
  };

  config = mkIf cfg.enable {
    home.shellAliases = {
      #sudo = "sudo env PATH=$PATH"; # FIXME this is insane because PATH is different when executing commands with sudo so PATH is not preserved holyhist

      # nix
      remote-test-voyager = "nixos-rebuild test --target-host oscar@nixos-server --use-remote-sudo --upgrade --flake .#voyager";
      remote-build-voyager = "nixos-rebuild switch --target-host oscar@nixos-server --use-remote-sudo --upgrade --flake .#voyager";
      test-cosmos = "sudo nixos-rebuild test --flake .#cosmos";
      build-cosmos = "sudo nixos-rebuild switch --flake .#cosmos";
      cleanup = "sudo nix-collect-garbage --delete-older-than 3d && nix-collect-garbage -d";

      # qol
      mp = "mkdir -p";
      fcd = "cd $(find -type d | fzf)";
      cls = "clear";
      ll = "ls -lah -color";
      la = "ls -A -color";
      grep = "grep --color";

      # system
      sc = "sudo systemctl";
      jc = "sudo journalctl";
      scu = "systemctl --user ";
      jcu = "journalctl --user";
      #myip = "${dig} @resolver4.opendns.com myip.opendns.com +short";

      # cli
      g = "git";
      k = "kubectl";
      h = "helm";
      d = "docker";
      p = "podman";
      z = "zed --wait";

      # kubectl
      kcs = "kubectl config use-context $(kubectl config get-contexts --output=name | fzf)";

      # nav
      ".." = "cd ..";
      "..." = "cd ../../";
      "...." = "cd ../../../";
      "....." = "cd ../../../../";
      "......" = "cd ../../../../../";
    };
  };
}
