{ lib, mylib, ... }:
{
  imports = mylib.scanPaths ./. { };

  options.nixfiles.yubikey = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "yubikey support";
    };

    u2f = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "enable U2F PAM authentication";
      };
      authfile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "path to u2f_keys file with registered yubikey credentials";
      };
    };
  };
}
