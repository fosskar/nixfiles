# openwrt device module options — evaluated via lib.evalModules
{ pkgs, lib, ... }:
{
  options = {
    host = lib.mkOption {
      type = lib.types.str;
      description = "IP or hostname of the device (SSH target)";
    };

    reload = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "extra services to reload after applying. top-level UCI config names (network, wireless, etc.) are reloaded automatically.";
    };

    packages = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "packages to ensure installed via apk";
    };

    disableServices = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "services to disable and stop via init.d";
    };

    removePackages = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "packages to remove if installed. runs before package installation.";
    };

    files = lib.mkOption {
      type = lib.types.attrsOf lib.types.path;
      default = { };
      description = "files to push to the device. keys are remote paths, values are local file paths.";
    };

    authorizedKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "SSH public keys to install in /etc/dropbear/authorized_keys";
    };

    uci = {
      settings = lib.mkOption {
        default = { };
        inherit (pkgs.formats.json { }) type;
        description = "UCI configuration as nix attrsets. named sections are attrsets with _type, anonymous sections are lists of attrsets with _type.";
      };

      secrets.sops.files = lib.mkOption {
        default = [ ];
        type = lib.types.listOf lib.types.path;
        description = "sops-encrypted files to decrypt and use for @placeholder@ substitution. all keys across files are merged.";
      };
    };
  };
}
