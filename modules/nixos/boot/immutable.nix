{
  # /etc as an overlay of an erofs image, with userborn and nixpkgs' perlless
  # profile for perl-free activation. still mutable: runtime writes go to
  # /.rw-etc/upper. set mutable = false once the remaining /etc writers are
  # handled (credstore, .updated, /etc/nixos, .pwd.lock, tuned state).
  # the profile's forbidden-dependency check stays off: grub installs through
  # install-grub.pl, and packages still pull perl in (xdg-utils, git, exiftool)
  flake.modules.nixos.immutable =
    { lib, modulesPath, ... }:
    {
      imports = [ "${modulesPath}/profiles/perlless.nix" ];

      system.forbiddenDependenciesRegexes = lib.mkForce [ ];

      system.etc.overlay = {
        enable = true;
        mutable = true;
      };
    };
}
