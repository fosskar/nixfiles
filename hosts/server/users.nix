{
  config,
  pkgs,
  ...
}: {
  sops.secrets.dXNlcl9wYXNzd29yZA.neededForUsers = true;
  users = {
    mutableUsers = false; # disable useradd + passwd

    users = {
      #root = {
      #  hashedPassword = "*"; # set a invalid hashed password "disables" root
      #};
      oscar = {
        group = "nixos";
        home = "/home/oscar";
        hashedPasswordFile = config.sops.secrets.dXNlcl9wYXNzd29yZA.path;
        isNormalUser = true;
        extraGroups = [
          "wheel"
          "kubernetes"
        ];
        shell = pkgs.zsh;
      };
      libvirtd = {
        group = "libvirtd";
        home = "/var/lib/libvirtd";
        createHome = true;
        isSystemUser = true;
      };
    };
    groups = {
      nixos = {};
      libvirtd = {};
    };
  };
}
