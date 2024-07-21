{ ... }:
{
  services = {
    openssh = {
      enable = true;
      openFirewall = true;
      startWhenNeeded = true;
      settings = {
        UseDns = true;
        AllowUsers = null;
      };
    };
  };
}
