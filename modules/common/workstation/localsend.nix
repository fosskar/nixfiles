{
  flake.modules.nixos.workstation = _: {
    programs.localsend = {
      enable = true;
      openFirewall = true;
    };
  };
}
