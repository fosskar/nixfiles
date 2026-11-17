{ inputs, ... }:
{
  flake.modules.nixos.luciole =
    { lib, pkgs, ... }:
    {
      # installs luciole and registers its file chooser portal and FileManager1 dbus service
      xdg.portal.extraPortals = [ inputs.luciole.packages.${pkgs.stdenv.hostPlatform.system}.default ];

      # nixfiles sets xdg.portal.config.umbriel, which replaces the FileChooser line of umbriel's packaged portals.conf
      xdg.portal.config.umbriel."org.freedesktop.impl.portal.FileChooser" = "luciole;gtk";
      # nixpkgs' niri module sets "gtk" when programs.niri.useNautilus is false
      xdg.portal.config.niri."org.freedesktop.impl.portal.FileChooser" = lib.mkForce "luciole;gtk";
    };
}
