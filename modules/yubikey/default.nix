{ lib, mylib, ... }:
{
  imports = mylib.scanPaths ./. { };

  options.nixfiles.yubikey = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "yubikey support";
    };

    lockOnRemove = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "lock screen when yubikey is unplugged";
    };

    gpgSsh = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "gpg-agent with ssh support via yubikey";
      };
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
