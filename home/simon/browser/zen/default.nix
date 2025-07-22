{
  lib,
  config,
  inputs,
  pkgs,
  ...
}:
with lib;

let
  cfg = config.module.browser.zen-browser;
in
{
  options = {
    module.browser.zen-browser.enable = mkEnableOption "Enables zen-browser";
  };

  imports = [
    inputs.zen-browser.homeModules.beta
  ];

  config = mkIf cfg.enable {
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
          Locked = true;
          Cryptomining = true;
          Fingerprinting = true;
        };
      };
    };
  };
}
