{
  config,
  lib,
  ...
}:
let
  isLaptop = config.nixfiles.machineType == "laptop";
in
lib.mkIf isLaptop {
  services.way-displays = {
    enable = true;
    settings = {
      ARRANGE = "ROW";
      ALIGN = "MIDDLE";
      ORDER = [ "eDP-1" ];
    };
  };
}
