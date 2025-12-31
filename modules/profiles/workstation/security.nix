_: {
  security = {
    # Force-enable the Page Table Isolation (PTI) Linux kernel feature
    # helps mitigate Meltdown and prevent some KASLR bypasses.
    # Disabled on desktop for better performance.
    forcePageTableIsolation = false;

    # Required by podman to run containers in rootless mode.
    unprivilegedUsernsClone = true;
  };
}
