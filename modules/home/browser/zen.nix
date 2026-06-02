{ inputs, ... }:
{
  flake.modules.homeManager.zen =
    { ... }:
    {
      imports = [
        inputs.zen-browser.homeModules.beta
        #inputs.zen-browser.homeModules.twilight
      ];

      programs.niri.settings.binds."Mod+W".action.spawn = "zen-beta";

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
    };
}
