{
  # /etc as an overlay of an erofs image, with userborn and nixpkgs' perlless
  # profile for perl-free activation. mutable by default: runtime writes go to
  # /.rw-etc/upper. a machine sets mutable = false once its remaining /etc
  # writers are handled (.updated, .pwd.lock, tuned state); ha-green does.
  # the profile's forbidden-dependency check stays off: grub installs through
  # install-grub.pl, and packages still pull perl in (xdg-utils, git, exiftool)
  flake.modules.nixos.immutable =
    {
      config,
      lib,
      modulesPath,
      pkgs,
      ...
    }:
    {
      imports = [ "${modulesPath}/profiles/perlless.nix" ];

      system.forbiddenDependenciesRegexes = lib.mkForce [ ];

      system.etc.overlay = {
        enable = true;
        mutable = lib.mkDefault true;
      };

      # hide the etc-metadata erofs loop device from udisks, so udiskie stops
      # trying to mount it and triggering a polkit prompt
      services.udev.extraRules = ''
        SUBSYSTEM=="block", KERNEL=="loop[0-9]*", ATTR{loop/backing_file}=="*-etc-metadata.erofs", ENV{UDISKS_IGNORE}="1"
      '';

      environment.etc = lib.mkIf (!config.system.etc.overlay.mutable) {
        # stage-2-init creates /etc/nixos unless it is a symlink
        "nixos".source = pkgs.emptyDirectory;
        # replaces systemd's credstore.conf, whose /etc dirs cannot be created on a read-only /etc
        "tmpfiles.d/credstore.conf".text = ''
          z /run/credstore 0700 root root
          z /run/credstore.encrypted 0700 root root
        '';
      };
    };
}
