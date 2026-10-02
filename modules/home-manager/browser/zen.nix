{ inputs, ... }:
{
  flake.modules.homeManager.zen =
    { lib, options, ... }:
    {
      imports = [
        inputs.zen-browser.homeModules.beta
        #inputs.zen-browser.homeModules.twilight
      ];

      config = lib.mkMerge [
        {
          wayland.windowManager.niri.settings.binds."Mod+W".spawn = [
            "focus-or-spawn"
            "zen-beta"
            "zen-beta"
          ];

          programs.zen-browser = {
            enable = true;
            policies = {
              AutofillAddressesEnabled = false;
              AutoFillCreditCardEnabled = false;
              DisableAppUpdate = true;
              DisableFeedbackCommands = true;
              DisableFirefoxStudies = true;
              DisablePocket = true;
              DisableTelemetry = true;
              DisableProfileImport = true;
              DisableSetDesktopBackground = true;
              DontCheckDefaultBrowser = true;
              NoDefaultBookmarks = true;
              NewTabPage = true;
              OfferToSaveLogins = false;
              EnableTrackingProtection = {
                Value = true;
                Locked = false;
                Cryptomining = true;
                Fingerprinting = true;
              };
            };
          };
        }
        (lib.optionalAttrs (options.services.psd ? extraBrowsers) {
          services.psd.extraBrowsers.zen = ''
            DIRArr[0]="$XDG_CONFIG_HOME/zen"
            PSNAME="zen"
            check_suffix=1
          '';
        })
      ];
    };
}
