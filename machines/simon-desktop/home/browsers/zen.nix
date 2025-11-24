{
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    #inputs.zen-browser.homeModules.beta
    inputs.zen-browser.homeModules.twilight
  ];

  programs.zen-browser = {
    enable = true;
    nativeMessagingHosts = [ pkgs.firefoxpwa ];
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
