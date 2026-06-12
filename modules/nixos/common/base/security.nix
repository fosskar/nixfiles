{
  flake.modules.nixos.base =
    { lib, ... }:
    {
      security = {
        # disables hibernation as side effect
        protectKernelImage = true;

        # upstream defaults kept: lockKernelModules=false (runtime module
        # loading needed), allowUserNamespaces=true (sandboxing), smt=true

        lsm = lib.mkForce [
          "landlock"
          "lockdown"
          "yama"
          "integrity"
          "apparmor"
          "bpf"
          "tomoyo"
          "selinux"
        ];
      };
    };
}
