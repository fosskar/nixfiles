_: {
  programs.zsh.shellAliases = {
    # make sudo use aliases
    sudo = "sudo ";

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
    diff = "diff --color=auto";
    #myip = "${dig} @resolver4.opendns.com myip.opendns.com +short";

    # cli
    g = "git";
    k = "kubectl";
    d = "docker";
    p = "podman";
    code = "codium";

    # nav
    ".." = "cd ..";
    "..." = "cd ../../";
    "...." = "cd ../../../";
    "....." = "cd ../../../../";
    "......" = "cd ../../../../../";
  };
}
