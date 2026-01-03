# impermanence backend config
{
  config,
  lib,
  inputs,
  ...
}:
let
  cfg = config.nixfiles.persistence;

  # all directories including base ones
  allDirectories = [
    "/var/lib/nixos"
    "/var/lib/systemd"
  ]
  ++ lib.optional cfg.manageSopsMount "/var/lib/sops-nix"
  ++ cfg.directories;

  # check if /var/lib/private is persisted (needs 0700 for DynamicUser)
  getDirPath = d: if builtins.isString d then d else d.directory or "";
  needsPrivateFix = builtins.any (d: getDirPath d == "/var/lib/private") cfg.directories;

  # generate tmpfiles rules to fix home directory ownership (impermanence bug workaround)
  mkHomeOwnershipRules =
    username:
    let
      home = config.users.users.${username}.home or "/home/${username}";
      group = config.users.users.${username}.group or "users";
    in
    [
      "d ${home} 0755 ${username} ${group} -"
      "d ${home}/.cache 0755 ${username} ${group} -"
      "d ${home}/.config 0755 ${username} ${group} -"
      "d ${home}/.local 0755 ${username} ${group} -"
      "d ${home}/.local/share 0755 ${username} ${group} -"
      "Z ${home} - ${username} ${group} -"
    ];
in
{
  imports = [ inputs.impermanence.nixosModules.impermanence ];

  config = lib.mkIf (cfg.enable && cfg.backend == "impermanence") {
    environment.persistence.${cfg.persistPath} = {
      hideMounts = lib.mkDefault true;
      directories = allDirectories;
      inherit (cfg) files;
    };

    fileSystems = lib.optionalAttrs cfg.manageSopsMount {
      "/var/lib/sops-nix".neededForBoot = true;
    };

    # fix home directory ownership (impermanence bug workaround)
    # fix /var/lib/private permissions (DynamicUser requires 0700)
    systemd.tmpfiles.rules =
      lib.flatten (map mkHomeOwnershipRules cfg.homeOwnershipFix)
      ++ lib.optional needsPrivateFix "d ${cfg.persistPath}/var/lib/private 0700 root root -";
  };
}
