{ inputs, self, ... }:
let
  inherit (inputs.nixpkgs) lib;
in
{
  # nixbot only evaluates x86_64-linux, so the aarch64 machines' toplevels sit
  # under x86_64-linux checks; the derivations still build for aarch64 via binfmt
  flake.checks.x86_64-linux =
    lib.mapAttrs' (name: cfg: lib.nameValuePair "nixos-${name}" cfg.config.system.build.toplevel)
      (
        lib.filterAttrs (
          _: cfg: cfg.pkgs.stdenv.hostPlatform.system == "aarch64-linux"
        ) self.nixosConfigurations
      );
}
