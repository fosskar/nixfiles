_: {
  services = {
    openssh = {
      enable = true;
      openFirewall = true;
      startWhenNeeded = true;
      settings = {
        X11Forwarding = false;
        UseDns = false;
        AllowUsers = null;
      };
    };
  };
}
