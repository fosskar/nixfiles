# CVE-2026-111497: out-of-bounds write in the brotli 1.0.3 to 1.2.0 decoder.
# the fix (brotli 1.2.1) sits in staging, see
# https://redirect.github.com/NixOS/nixpkgs/pull/577208; patching pkgs.brotli
# would rebuild nearly everything, so the patched lib is grafted into the closure
{
  flake.modules.nixos.securityFixes =
    { lib, pkgs, ... }:
    let
      fixCommit = "0ed4268a4401abcb4472096340477cf4af7d1a2b";
      fixed =
        lib.versionAtLeast pkgs.brotli.version "1.2.1"
        || lib.any (p: lib.hasInfix fixCommit (toString p)) pkgs.brotli.patches;
      patched = pkgs.brotli.overrideAttrs (old: {
        patches = old.patches ++ [
          (pkgs.fetchurl {
            url = "https://github.com/google/brotli/commit/${fixCommit}.patch?full_index=1";
            hash = "sha256-1vliUJAAIj3vcGKVgim9CEV+XgMuftDR2U+3kLBUsfw=";
          })
        ];
      });
    in
    {
      warnings = lib.optional fixed "brotli ${pkgs.brotli.version} includes the CVE-2026-111497 fix, modules/nixos/security-fixes/brotli.nix can be removed";

      system.replaceDependencies.replacements = lib.optional (!fixed) {
        oldDependency = pkgs.brotli.lib;
        newDependency = patched.lib;
      };
    };
}
