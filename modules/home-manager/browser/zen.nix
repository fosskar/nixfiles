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
              ExtensionSettings =
                lib.mapAttrs
                  (_: slug: {
                    install_url = "https://addons.mozilla.org/firefox/downloads/latest/${slug}/latest.xpi";
                    installation_mode = "force_installed";
                  })
                  {
                    "uBlock0@raymondhill.net" = "ublock-origin";
                    "{446900e4-71c2-419f-a6a7-df9c091e268b}" = "bitwarden-password-manager";
                    "addon@simplelogin" = "simplelogin";
                    "search@kagi.com" = "kagi-search-for-firefox";
                  };
            };
            # path must match the existing profile directory, or zen opens an
            # empty profile
            profiles.default = {
              id = 0;
              name = "Default Profile";
              path = "9f4pb3uq.Default Profile";
              isDefault = true;
              presets.betterfox.enable = true;
              settings = {
                "network.trr.mode" = 5;
                "privacy.sanitize.sanitizeOnShutdown" = true;
                "privacy.clearOnShutdown_v2.cache" = true;
                "privacy.clearOnShutdown_v2.formdata" = true;
                "privacy.clearOnShutdown_v2.downloads" = true;
                "privacy.clearOnShutdown_v2.cookiesAndStorage" = false;
                "privacy.clearOnShutdown_v2.browsingHistoryAndDownloads" = false;
                "privacy.clearOnShutdown_v2.historyFormDataAndDownloads" = false;
                "privacy.clearOnShutdown_v2.siteSettings" = false;
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
