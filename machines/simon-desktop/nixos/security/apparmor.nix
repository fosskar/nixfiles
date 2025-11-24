{ config, pkgs, ... }:
{
  services.dbus.apparmor = "enabled";

  environment.systemPackages = with pkgs; [
    apparmor-bin-utils
    apparmor-pam
    apparmor-parser
    apparmor-profiles
    apparmor-utils
    libapparmor
    which
  ];

  # apparmor configuration
  security.apparmor = {
    enable = false; # Temporarily disabled to test D-Bus issue

    # whether to enable the AppArmor cache
    # in /var/cache/apparmore
    enableCache = true;

    # whether to kill processes which have an AppArmor profile enabled
    # but are not confined (AppArmor can only confine new processes)
    killUnconfinedConfinables = true;

    # packages to be added to AppArmor’s include path
    packages = with pkgs; [
      apparmor-profiles
      apparmor-utils
    ];

    # apparmor policies
    policies = {
      "default_deny" = {
        state = "disable";
        profile = ''
          profile default_deny /** { }
        '';
      };

      "sudo" = {
        state = "disable";
        profile = ''
          ${pkgs.sudo}/bin/sudo {
            file /** rwlkUx,
          }
        '';
      };

      "nix" = {
        state = "disable";
        profile = ''
          ${config.nix.package}/bin/nix {
            unconfined,
          }
        '';
      };
    };
  };
}
