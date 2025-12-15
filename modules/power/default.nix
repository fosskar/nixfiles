{
  lib,
  mylib,
  ...
}:
{
  imports = mylib.scanPaths ./. { };

  options.nixfiles.power = {
    ppd.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "enable power-profiles-daemon (for desktop/laptop)";
    };

    tuned = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "enable tuned (for servers)";
      };
      profile = lib.mkOption {
        type = lib.types.either lib.types.str (lib.types.listOf lib.types.str);
        default = "balanced";
        description = "tuned profile(s) to use (string or list, last wins conflicts)";
      };
    };
  };
}
