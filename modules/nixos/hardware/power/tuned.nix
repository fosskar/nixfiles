{
  # base tuned aspect; profile selection lives in the tuned* variants
  flake.modules.nixos.tuned =
    { lib, pkgs, ... }:
    {
      services.tuned = {
        enable = true;
        ppdSupport = lib.mkDefault false;

        # tuned without the tuna gui and its gtk closure
        package = pkgs.tuned.overrideAttrs (old: {
          propagatedBuildInputs = builtins.filter (
            drv: (drv.pname or drv.name or "") != "tuna"
          ) old.propagatedBuildInputs;

          dontWrapGApps = true;
          makeWrapperArgs = builtins.filter (arg: arg != "\${gappsWrapperArgs[@]}") old.makeWrapperArgs;

          postInstall = (old.postInstall or "") + ''
            rm -f $out/share/applications/tuned-gui.desktop
            rm -rf $out/share/icons
          '';

          # make installs tuned-gui into $out/sbin; the move-sbin fixup hook
          # relocates it to bin after postInstall, so remove it in postFixup
          postFixup = (old.postFixup or "") + ''
            rm -f $out/bin/tuned-gui $out/bin/.tuned-gui-wrapped
          '';
        });
      };

      # nixos-hardware may enable tlp; tuned conflicts with it
      services.tlp.enable = lib.mkForce false;
    };
}
