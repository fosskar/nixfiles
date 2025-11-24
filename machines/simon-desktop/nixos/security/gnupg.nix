_: {
  programs = {
    gnupg = {
      agent = {
        enable = true;
        enableSSHSupport = true;
      };
    };
  };
  hardware.gpgSmartcards.enable = true;
}
