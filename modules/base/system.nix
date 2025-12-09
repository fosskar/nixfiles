_: {
  disabledModules = [
    "profiles/all-hardware.nix"
    "profiles/base.nix"
  ];

  services.journald.extraConfig = ''
    SystemMaxUse=100M
    RuntimeMaxUse=50M
  '';

  environment = {
    variables.EDITOR = "nvim --clean";
    ldso32 = null;
  };
}
