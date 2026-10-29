# dirty frag (CVE-2026-43284 esp, CVE-2026-43500 rxrpc) and fragnesia
# (CVE-2026-46300): page-cache writes via in-place decrypt in esp4/esp6/rxrpc.
# fixed versions from the kernel.org records on https://www.cve.org
{
  flake.modules.nixos.securityFixes =
    { config, lib, ... }:
    let
      version = config.boot.kernelPackages.kernel.version;
      branch = lib.versions.majorMinor version;
      fixedIn = {
        "6.6" = "6.6.141";
        "6.12" = "6.12.91";
        "6.18" = "6.18.33";
        "7.0" = "7.0.10";
      };
      mainline = lib.versionAtLeast version "7.1";
      known = mainline || fixedIn ? ${branch};
      fixed = mainline || (known && lib.versionAtLeast version fixedIn.${branch});
      file = "modules/nixos/security-fixes/dirty-frag.nix";
    in
    {
      warnings =
        lib.optional fixed "dirty frag: kernel ${version} includes the upstream fixes, ${file} can be removed"
        ++
          lib.optional (!known)
            "dirty frag: no upstream fix known for kernel ${branch} yet, the mitigation in ${file} stays active";

      boot.blacklistedKernelModules = [
        "esp4"
        "esp6"
        "rxrpc"
      ];
    };
}
