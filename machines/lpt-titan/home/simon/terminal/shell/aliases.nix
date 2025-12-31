_: {
  home.shellAliases = {
    #sudo = "sudo env PATH=$PATH"; # FIXME this is insane because PATH is different when executing commands with sudo so PATH is not preserved holyhist

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
    c = "claude";
    j = "jj";
    h = "helm";
    d = "docker";
    p = "podman";
    z = "zeditor";
    zj = "zellij";
    tm = "tmux";

    # kubectl
    kcs = "kubectl config use-context $(kubectl config get-contexts --output=name | fzf)";

    # nav
    ".." = "cd ..";
    "..." = "cd ../../";
    "...." = "cd ../../../";
    "....." = "cd ../../../../";
    "......" = "cd ../../../../../";
  };
}
