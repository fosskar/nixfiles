# preservation backend config
{
  config,
  lib,
  inputs,
  ...
}:
let
  cfg = config.nixfiles.persistence;

  # convert string or attrset to preservation directory format
  toPreservationDir =
    d:
    let
      base = if builtins.isString d then { directory = d; } else d;
      # /var/lib/private needs 0700 for DynamicUser services
      withMode =
        if base.directory == "/var/lib/private" then base // { mode = base.mode or "0700"; } else base;
    in
    { how = "bindmount"; } // withMode;

  toPreservationFile =
    f:
    if builtins.isString f then
      {
        file = f;
        how = "bindmount";
      }
    else
      { how = "bindmount"; } // f;
in
{
  imports = [ inputs.preservation.nixosModules.preservation ];

  config = lib.mkIf cfg.enable {
    # clan.core.settings.machine-id creates /etc/machine-id in the nix store,
    # causing systemd to mount a tmpfs overlay (for writability), which breaks
    # nix-optimise (EXDEV cross-device link). disable store-based file and let
    # preservation handle it via symlink. clan's kernel cmdline still works.
    environment.etc.machine-id.enable = lib.mkForce false;

    preservation = {
      enable = true;

      preserveAt.${cfg.persistPath} = {
        directories =
          map toPreservationDir (
            [
              "/var/lib/nixos"
              "/var/lib/systemd"
              "/var/log"
            ]
            ++ cfg.directories
          )
          ++ lib.optional cfg.manageSopsMount {
            directory = "/var/lib/sops-nix";
            how = "bindmount";
            inInitrd = true;
          };

        files = map toPreservationFile cfg.files ++ [
          {
            file = "/etc/machine-id";
            how = "symlink";
            inInitrd = true;
            createLinkTarget = true;
          }
        ];
      };
    };
  };
}
