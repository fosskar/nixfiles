{
  pkgs,
  config,
  ...
}: {
  home.packages = with pkgs; [
    # archives
    zip
    unzip
    unrar

    # file managers
    ranger
    yazi
    joshuto
  ];
  #home.sessionVariables = systemd.user.sessionVariables;
}
