_: {
  services.openssh = {
    startWhenNeeded = true;
    # use /persist paths directly to avoid impermanence bind-mount timing issues
    # see: https://github.com/nix-community/impermanence/issues/192
    ## not needed when using clan
    #hostKeys = [
    #  {
    #    path = "/persist/etc/ssh/ssh_host_ed25519_key";
    #    type = "ed25519";
    #  }
    #  {
    #    path = "/persist/etc/ssh/ssh_host_rsa_key";
    #    type = "rsa";
    #    bits = 4096;
    #  }
    #];
  };
}
