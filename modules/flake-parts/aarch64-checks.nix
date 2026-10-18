{ inputs, self, ... }:
let
  inherit (inputs.nixpkgs) lib;
in
{
  # the flake only has x86_64-linux systems; add the aarch64 machines' toplevels
  # as checks so nixbot builds them, without building every package for aarch64
  flake.checks.aarch64-linux =
    lib.mapAttrs' (name: cfg: lib.nameValuePair "nixos-${name}" cfg.config.system.build.toplevel)
      (
        lib.filterAttrs (
          _: cfg: cfg.pkgs.stdenv.hostPlatform.system == "aarch64-linux"
        ) self.nixosConfigurations
      );
}
