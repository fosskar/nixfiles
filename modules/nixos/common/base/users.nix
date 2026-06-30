{
  flake.modules.nixos.base = _: {
    # preservation module forces this true on its hosts (mutableUsers=false
    # deadlocks userborn under the shared /var/lib/nixos bind-mount).
    users = {
      mutableUsers = false;
    };
  };
}
