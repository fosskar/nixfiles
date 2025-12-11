{ self, ... }:
{
  nixpkgs = {
    overlays = [ self.overlays.default ];

    config = {
      # allow broken packages to be built. setting this to false means packages
      # will refuse to evaluate sometimes, but only if they have been marked as
      # broken for a specific reason. at that point we can either try to solve
      # the breakage, or get rid of the package entirely.
      allowBroken = false;
      allowUnsupportedSystem = true;
      # really a pain in the ass to deal with when disabled. true means
      # we are able to build unfree packages without explicitly allowing
      # each unfree package.
      allowUnfree = true;
      # default to none, add more as necessary. this is usually where
      # electron packages go when they reach EOL.
      permittedInsecurePackages = [ ];
      # nixpkgs sets internal package aliases to ease migration from other
      # distributions easier, or for convenience's sake. even though the manual
      # and the description for this option recommends this to be true, i prefer
      # explicit naming conventions, i.e., no aliases.
      allowAliases = true;
      # enable parallel building by default. this, in theory, should speed up building
      # derivations, especially rust ones. however setting this to true causes a mass rebuild
      # of the *entire* system closure, so it must be handled with proper care.
      enableParallelBuildingByDefault = false;
      # list of derivation warnings to display while rebuilding.
      #  see: <https://github.com/NixOS/nixpkgs/blob/master/pkgs/stdenv/generic/check-meta.nix>
      # note: "maintainerless" can be added to emit warnings
      # about packages without maintainers but it seems to me
      # like there are more packages without maintainers than
      # with maintainers, so it's disabled for the time being.
      showDerivationWarnings = [ ];
    };
  };
}
