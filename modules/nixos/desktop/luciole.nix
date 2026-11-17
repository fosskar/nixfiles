{ inputs, ... }:
{
  flake.modules.nixos.luciole =
    { pkgs, ... }:
    {
      # installs luciole and registers its file chooser portal and FileManager1 dbus service
      xdg.portal.extraPortals = [ inputs.luciole.packages.${pkgs.stdenv.hostPlatform.system}.default ];

      # nixfiles sets xdg.portal.config.umbriel, which replaces the FileChooser line of umbriel's packaged portals.conf
      xdg.portal.config.umbriel."org.freedesktop.impl.portal.FileChooser" = "luciole;gtk";
    };
}
