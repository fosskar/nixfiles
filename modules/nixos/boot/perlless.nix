{
  # nixpkgs' perlless profile: perl-free activation (etc overlay, userborn) and
  # no perl in the default package set. its forbidden-dependency check stays
  # off: grub installs through install-grub.pl, and packages still pull perl in
  # (xdg-utils, git, exiftool), so the check would fail the build
  flake.modules.nixos.perlless =
    { lib, modulesPath, ... }:
    {
      imports = [ "${modulesPath}/profiles/perlless.nix" ];
      system.forbiddenDependenciesRegexes = lib.mkForce [ ];
    };
}
