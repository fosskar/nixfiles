_: {
  flake.modules.homeManager.brave =
    {
      lib,
      options,
      pkgs,
      ...
    }:
    {
      config = lib.mkMerge [
        { home.packages = [ pkgs.brave-origin ]; }
        (lib.optionalAttrs (options.services.psd ? extraBrowsers) {
          services.psd.extraBrowsers.brave = ''
            DIRArr[0]="$XDG_CONFIG_HOME/BraveSoftware/Brave-Browser"
            PSNAME="brave"
          '';
        })
      ];
    };
}
