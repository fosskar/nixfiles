_: {
  home.shellAliases = {
    # nix
    cleanup = "sudo nix-collect-garbage --delete-older-than 3d && nix-collect-garbage -d";

    # qol
    mp = "mkdir -p";
    fcd = "cd $(find -type d | fzf)";
    cls = "clear";
    ll = "ls -lah -color";
    la = "ls -A -color";
    grep = "grep --color";
    gpg = "gpg --pinentry-mode loopback";

    # system
    sc = "sudo systemctl";
    jc = "sudo journalctl";
    scu = "systemctl --user ";
    jcu = "journalctl --user";
    #myip = "${dig} @resolver4.opendns.com myip.opendns.com +short";

    # cli
    cc = "claude --dangerously-skip-permissions";
    codex-yolo = "codex --dangerously-bypass-approvals-and-sandbox";
    g = "git";
    h = "helm";
    d = "docker";
    p = "podman";
    z = "zeditor";

    # nav
    ".." = "cd ..";
    "..." = "cd ../../";
    "...." = "cd ../../../";
    "....." = "cd ../../../../";
    "......" = "cd ../../../../../";
  };
}
