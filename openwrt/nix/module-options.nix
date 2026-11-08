# openwrt device module options, evaluated via lib.evalModules
{
  pkgs,
  lib,
  config,
  ...
}:
let
  fileType = lib.types.submodule (
    { config, ... }:
    {
      options = {
        source = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          description = "local file whose content is pushed. @placeholder@ secrets are substituted at deploy.";
        };
        text = lib.mkOption {
          type = lib.types.nullOr lib.types.lines;
          default = null;
          description = "file content. @placeholder@ secrets are substituted at deploy.";
        };
        secret = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "sops key whose value becomes the whole file content";
        };
        mode = lib.mkOption {
          type = lib.types.strMatching "[0-7]{3,4}";
          default =
            if
              config.secret != null || builtins.length (builtins.split "@[A-Za-z0-9_]+@" config.content) > 1
            then
              "0600"
            else
              "0644";
          defaultText = lib.literalMD "`0600` if the file contains secrets, else `0644`";
        };
        restart = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "init scripts to restart when this file changed";
        };
        content = lib.mkOption {
          type = lib.types.str;
          internal = true;
          readOnly = true;
        };
      };
      config.content =
        let
          set = builtins.filter (x: x != null) [
            config.source
            config.text
            config.secret
          ];
        in
        if builtins.length set != 1 then
          throw "openwrt file: set exactly one of source, text, secret"
        else if config.secret != null then
          "@${config.secret}@"
        else if config.text != null then
          config.text
        else
          builtins.readFile config.source;
    }
  );
in
{
  options = {
    host = lib.mkOption {
      type = lib.types.str;
      description = "IP or hostname of the device (SSH target)";
    };

    packages = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "packages to ensure installed via apk";
    };

    externalPackages = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            name = lib.mkOption {
              type = lib.types.str;
              description = "package name used for idempotency checks";
            };
            checkCommand = lib.mkOption {
              type = lib.types.str;
              default = "";
              description = "remote shell command that succeeds when the package is installed and needs no update";
            };
            installCommand = lib.mkOption {
              type = lib.types.str;
              description = "remote shell command that installs the package";
            };
          };
        }
      );
      default = [ ];
      description = "packages to ensure installed outside official OpenWrt feeds";
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
      type = lib.types.attrsOf (
        lib.types.coercedTo lib.types.path (source: { inherit source; }) fileType
      );
      default = { };
      description = "files to push to the device, keyed by remote path. a plain path is short for { source = path; }.";
    };

    authorizedKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "SSH public keys to install in /etc/dropbear/authorized_keys";
    };

    rootPasswordSecret = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "sops key holding the plaintext root password, written to /etc/shadow as a sha-crypt hash";
    };

    uci = {
      settings = lib.mkOption {
        default = { };
        inherit (pkgs.formats.json { }) type;
        description = "UCI configuration as nix attrsets. named sections are attrsets with _type, anonymous sections are lists of attrsets whose _type equals the list name.";
      };

      delete = lib.mkOption {
        default = [ ];
        type = lib.types.listOf lib.types.str;
        description = "UCI sections or options to delete, e.g. \"firewall.old_rule\". replace semantics never remove undeclared sections, so list stale ones here.";
      };

      exclusive = lib.mkOption {
        default = [ ];
        type = lib.types.listOf lib.types.str;
        description = "configs fully owned by uci.settings: sections not declared there are deleted";
      };

      secrets.sops.files = lib.mkOption {
        default = [ ];
        type = lib.types.listOf lib.types.path;
        description = "sops-encrypted files to decrypt and use for @placeholder@ substitution. all keys across files are merged.";
      };
    };
  };

  config.files = lib.mkIf (config.authorizedKeys != [ ]) {
    "/etc/dropbear/authorized_keys" = {
      text = lib.concatStringsSep "\n" config.authorizedKeys + "\n";
      mode = "0600";
    };
  };
}
