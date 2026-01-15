{
  inputs,
  ...
}:
{
  imports = [
    inputs.dms.nixosModules.greeter
  ];

  programs.dank-material-shell.greeter = {
    enable = true;
    compositor.name = "niri";
    configHome = "/home/simon";
  };

  # persist greeter state (must be writable by greeter user to save memory.json)
  nixfiles.persistence.directories = [
    {
      directory = "/var/lib/dms-greeter";
      user = "greeter";
      group = "greeter";
    }
  ];
}
