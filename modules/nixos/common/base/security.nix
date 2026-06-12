{
  flake.modules.nixos.base =
    { lib, ... }:
    {
      security = {
        # disables hibernation as side effect
        protectKernelImage = true;

        # true breaks runtime module loading (virtd, wireguard, iptables); needs all modules declared
        lockKernelModules = false;

        # User namespaces are required for sandboxing
        allowUserNamespaces = true;

        allowSimultaneousMultithreading = true;

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
