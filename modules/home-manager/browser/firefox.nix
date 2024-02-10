{
  pkgs,
  inputs,
  ...
}: {
  programs.firefox = {
    enable = true;
    package = pkgs.firefox-wayland;
    policies = {
      AppAutoUpdate = false;
      DisableFirefoxStudies = true;
      DisablePocket = true;
      DisableTelemetry = true;
      DisableFirefoxAccounts = true;
      DontCheckDefaultBrowser = true;
      NoDefaultBookmarks = true;
      OfferToSaveLogins = false;
      OfferToSaveLoginsDefault = false;
      PasswordManagerEnabled = false;
      FirefoxHome = {
        Search = true;
        Pocket = false;
        Snippets = false;
        TopSites = false;
        Highlights = false;
      };
      Cookies = {
        Default = true;
        AcceptThirdParty = "always";
        ExpireAtSessionEnd = false;
        RejectTracker = true;
      };
      UserMessaging = {
        ExtensionRecommendations = false;
        SkipOnboarding = true;
        WhatsNew = false;
        FeatureRecomendations = false;
        UrlbarInterventions = false;
        MoreFromMozilla = false;
      };
    };
    profiles = {
      default = {
        id = 0;
        name = "default";
        bookmarks = import ./bookmarks.nix;
        isDefault = true;
        extensions = with inputs.firefox-addons.packages.${pkgs.system}; [
          ublock-origin
          bitwarden
          startpage-private-search
          darkreader
        ];
        #https://sourcegraph.com/search?q=context:global+lang:nix&patternType=standard&sm=1
        search = {
          force = true;
          default = "Startpage";
          engines = {
            "Startpage" = {
              urls = [
                {
                  template = "https://www.startpage.com/do/dsearch?query={searchTerms}";
                }
              ];
              icon = "https://www.startpage.com/sp/cdn/favicons/favicon--default.ico";
              definedAliases = ["@sp"];
            };
            "Nix Packages" = {
              urls = [
                {
                  template = "https://search.nixos.org/packages";
                  params = [
                    {
                      name = "type";
                      value = "packages";
                    }
                    {
                      name = "query";
                      value = "{searchTerms}";
                    }
                  ];
                }
              ];
              icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
              definedAliases = ["@np"];
            };
            "NixOS Wiki" = {
              urls = [{template = "https://nixos.wiki/index.php?search={searchTerms}";}];
              iconUpdateURL = "https://nixos.wiki/favicon.png";
              updateInterval = 24 * 60 * 60 * 1000;
              definedAliases = ["@nw"];
            };
          };
        };
        settings = {
          "general.smoothScroll" = true;

          # performance settings
          "gfx.webrender.all" = true;
          "gfx.webrender.enabled" = true;
          "media.ffmpeg.vaapi.enable" = true;
          "media.ffvpx.enabled" = false;

          # Enable multi-pip
          "media.videocontrols.picture-in-picture.allow-multiple" = true;

          #misc
          "browser.aboutConfig.showWarning" = false;
          "browser.tabs.warnOnClose" = true;
          "widget.use-xdg-desktop-portal" = true;
          "browser.toolbars.bookmarks.visibility" = "always";

          # privacy
          "browser.contentblocking.category" = "strict";
          "network.trr.confirmation_telemetry_enabled" = false;

          "app.shield.optoutstudies.enabled" = false;
          "browser.bookmarks.restore_default_bookmarks" = false;
          "browser.ctrlTab.recentlyUsedOrder" = true;
          "browser.urlbar.suggest.openpage" = false;
          "datareporting.policy.dataSubmissionEnable" = false;
          "datareporting.policy.dataSubmissionPolicyAcceptedVersion" = 2;
          "dom.security.https_only_mode" = true;
          "dom.security.https_only_mode_ever_enabled" = true;
          "extensions.getAddons.showPane" = false;
          "extensions.htmlaboutaddons.recommendations.enabled" = false;
          "extensions.pocket.enabled" = false;
          "identity.fxaccounts.enabled" = false;
          "privacy.trackingprotection.enabled" = true;
          "privacy.trackingprotection.socialtracking.enabled" = true;
          "browser.urlbar.placeholderName" = "Startpage";
          "browser.search.defaultenginename" = "Startpage";
          "browser.startup.homepage" = "https://eu.startpage.com/do/mypage.pl?prfe=1dac62e5595f79947b1cdc2849cc6d26cfc1a64b90d30585411c13b94f8146794ff6196ff1e291fbb48d7ab671ac2e225ba50989b1ef28f0d912c5761bc71423602707ffff1759e9f158126847";
        };
      };
    };
  };
}
