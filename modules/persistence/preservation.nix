# preservation backend config
{
  config,
  lib,
  inputs,
  ...
}:
let
  cfg = config.nixfiles.persistence;

  # convert to preservation format
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

  config = lib.mkIf (cfg.enable && cfg.backend == "preservation") {
    preservation.enable = true;

    # prevent systemd from creating tmpfs overlay on /nix/store/*-etc-machine-id
    # which breaks nix-optimise (EXDEV: cross-device link)
    # see: https://github.com/nix-community/impermanence/blob/master/nixos.nix
    boot.initrd.systemd.suppressedUnits = [ "systemd-machine-id-commit.service" ];
    systemd.services.systemd-machine-id-commit.unitConfig.ConditionFirstBoot = true;
    preservation.preserveAt.${cfg.persistPath} = {
      directories =
        map toPreservationDir (
          [
            "/var/lib/nixos"
            "/var/lib/systemd"
          ]
          ++ cfg.directories
        )
        ++ lib.optional cfg.manageSopsMount {
          directory = "/var/lib/sops-nix";
          how = "bindmount";
          inInitrd = true;
        };
      files = map toPreservationFile cfg.files;
    };
  };
}
