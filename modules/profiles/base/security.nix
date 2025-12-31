_: {
  security = {
    # disables hibernation as side effect
    protectKernelImage = true;

    # Breaks virtd, wireguard, iptables and many more features by
    # disallowing them from loading modules during runtime. You may
    # enable this module if you wish, but do make sure that the
    # necessary modules are loaded declaratively before doing so.
    # Failing to add those modules may result in an unbootable system!
    lockKernelModules = false;

    # User namespaces are required for sandboxing
    allowUserNamespaces = true;

    allowSimultaneousMultithreading = true;
  };
}
