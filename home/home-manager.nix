{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:
{
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  home-manager = {
    # Tell home-manager to be as verbose as possible
    verbose = true;

    # Use the system configuration’s pkgs argument
    # this ensures parity between nixos' pkgs and hm's pkgs
    useGlobalPkgs = true;

    # Enable the usage user packages through
    # the users.users.<name>.packages option
    useUserPackages = true;

    # Move existing files to the backuü-timestamp suffix rather than failing
    # with a very long error message about it.
    # with this hm should never be failing because of a already backuped file
    backupFileExtension =
      "backup-"
      + pkgs.lib.readFile "${pkgs.runCommand "timestamp" { } "echo -n `date '+%Y%m%d%H%M%S'` > $out"}";

    # Per-user Home Manager configurations.
    # The function below generates an attribute sett of users
    # where users come from a list in my module system. Each
    # user in this list is mapped to an attribute set to generate
    # the format Home-Manager expects, i.e., { "username" = path;}
    # The system expects user directories to be found in the present
    # directory, or will exit with directory not found errors
    #users = lib.attrsets.genAttrs config.modules.system.users (name: ./${name} + /home.nix);
    users.simon.imports = [ ./simon/home.nix ];

    extraSpecialArgs = {
      inherit inputs;
    };

    sharedModules = [
      {
        # Ensure that HM uses t he same Nix package as NixOS.
        nix.package = lib.mkForce config.nix.package;

        # Allow HM to manage itself when in standalone mode.
        # This makes the home-manager command available to users.
        programs.home-manager.enable = true;

        # Try to save some space by not installing variants of the home-manager
        # manual, which I don't use at all. Unlike what the name implies, this
        # section is for home-manager related manpages only, and does not affect
        # whether or not manpages of actual packages will be installed.
        manual = {
          manpages.enable = false;
          html.enable = false;
          json.enable = false;
        };
        programs = {
          man.enable = false;
          man.package = null;
        };
      }
    ];
  };
}
