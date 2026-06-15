_:
# tuned without GUI deps (tuna, gtk, gobject-introspection)
_final: prev: {
  tuned = prev.tuned.overrideAttrs (old: {
    nativeBuildInputs = builtins.filter (
      drv:
      !(builtins.elem (drv.pname or drv.name or "") [
        "gobject-introspection"
        "wrapGAppsHook3"
      ])
    ) old.nativeBuildInputs;

    propagatedBuildInputs = builtins.filter (
      drv:
      !(builtins.elem (drv.pname or drv.name or "") [
        "pygobject3"
        "tuna"
      ])
    ) old.propagatedBuildInputs;

    dontWrapGApps = true;
    makeWrapperArgs = builtins.filter (arg: arg != "\${gappsWrapperArgs[@]}") old.makeWrapperArgs;

    postInstall = (old.postInstall or "") + ''
      rm -f $out/bin/tuned-gui
      rm -f $out/share/applications/tuned-gui.desktop
      rm -rf $out/share/icons
    '';
  });
}
