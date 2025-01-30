_: {
  networking = {
    wireless = {
      enable = false;
      iwd = {
        enable = false;
        settings = {
          IPv6 = {
            Enabled = false;
          };
          Settings = {
            AutoConnect = false;
          };
        };
      };
    };
  };
}
