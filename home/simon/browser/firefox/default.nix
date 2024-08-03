{
  config,
  pkgs,
  inputs,
  ...
}:
let
  ffultima = pkgs.fetchFromGitHub {
    owner = "soulhotel";
    repo = "FF-ULTIMA";
    rev = "1.8.1";
    #sha256 = pkgs.lib.fakeSha256; # used to get the latest hash
    sha256 = "a+QWOfvGBIDWxVOd7mgYNB9fdW6FWzbE5KT7KbntDZk=";
  };

  shyfox = pkgs.fetchFromGitHub {
    owner = "Naezr";
    repo = "ShyFox";
    rev = "b8687644566e10eae652227b07cb97a6d4b09d63";
    #sha256 = pkgs.lib.fakeSha256; # used to get the latest hash
    sha256 = "EkT1vf3JJdBaM3trlrurGmPNWsBu79HoH0dTWWTVD28=";
  };
in
{
  home = {
    sessionVariables.BROWSER = "firefox";
    #file.".mozilla/firefox/${config.programs.firefox.profiles.simon.path}/chrome".source = "${ffultima}/theme";
    file.".mozilla/firefox/${config.programs.firefox.profiles.simon.path}/chrome".source = "${shyfox}/chrome";
  };

  programs.firefox = {
    enable = true;
    policies = {
      AppAutoUpdate = false;
      OverrideFirstRunPage = "";
      DisableFirefoxStudies = true;
      DisablePocket = true;
      DisableTelemetry = true;
      DisableFormHistory = true;
      DisableFirefoxAccounts = true;
      DontCheckDefaultBrowser = true;
      DisableSetDesktopBackground = true;
      NoDefaultBookmarks = false; # must be false to prevent getting my own bookmarks
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
      EnableTrackingProtection = {
        Cryptomining = true;
        Fingerprinting = true;
        Locked = true;
        Value = true;
      };
      Cookies = {
        Default = true;
        Behavior = "accept";
        #AcceptThirdParty = "always";
        ExpireAtSessionEnd = false;
        RejectTracker = true;
        Locked = false;
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
      simon = {
        id = 0;
        bookmarks = import ./bookmarks.nix;
        isDefault = true;
        extensions = with inputs.firefox-addons.packages.${pkgs.system}; [
          ublock-origin
          bitwarden
          darkreader
          sidebery
          simplelogin
        ];
        search = {
          # force set ddg as default search engine
          force = true;
          default = "DuckDuckGo";
          privateDefault = "DuckDuckGo";
          engines = {
            # shortcut to search for nixos pkgs with @np
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
              definedAliases = [ "@np" ];
            };
            # shortcut to search for nixos pkgs with @no
            "Nix Options" = {
              urls = [
                {
                  template = "https://search.nixos.org/options";
                  params = [
                    {
                      name = "type";
                      value = "options";
                    }
                    {
                      name = "query";
                      value = "{searchTerms}";
                    }
                  ];
                }
              ];
              iconUpdateURL = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
              definedAliases = [ "@no" ];
            };
          };
        };
        settings = {
          #ARKENFOX
          #
          #    name: arkenfox user.js
          #    date: 7 June 2024
          # version: 126
          #    urls: https://github.com/arkenfox/user.js [repo]
          #        : https://arkenfox.github.io/gui/ [interactive]
          # license: MIT: https://github.com/arkenfox/user.js/blob/master/LICENSE.txt

          "browser.aboutConfig.showWarning" = false;

          # STARTUP
          "browser.startup.page" = 0;
          "browser.startup.homepage" = "about:blank";
          "startup.homepage_welcome_url" = "";
          "browser.newtabpage.enabled" = false;
          "browser.newtabpage.activity-stream.showSponsored" = false;
          "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
          "browser.newtabpage.activity-stream.default.sites" = "";

          # GEOLOCATION
          "geo.enabled" = false;
          "geo.provider.network.url" = "";
          "geo.provider.ms-windows-location" = false;
          "geo.provider.use_corelocation" = false;
          "geo.provider.use_gpsd" = false;
          "geo.provider.use_geoclue" = false;
          "browser.geolocation.warning.infoURL" = "";

          # QUIETER FOX
          "extensions.getAddons.showPane" = false;
          "extensions.htmlaboutaddons.recommendations.enabled" = false;
          "browser.discovery.enabled" = false;

          # TELEMETRY
          "browser.shopping.experience2023.enabled" = false;
          "datareporting.healthreport.uploadEnabled" = false;
          "toolkit.telemetry.unified" = false;
          "toolkit.telemetry.enabled" = false;
          "toolkit.telemetry.server" = "data:,";
          "toolkit.telemetry.archive.enabled" = false;
          "toolkit.telemetry.newProfilePing.enabled" = false;
          "toolkit.telemetry.shutdownPingSender.enabled" = false;
          "toolkit.telemetry.updatePing.enabled" = false;
          "toolkit.telemetry.bhrPing.enabled" = false;
          "toolkit.telemetry.firstShutdownPing.enabled" = false;
          "toolkit.telemetry.coverage.opt-out" = true;
          "toolkit.coverage.opt-out" = true;
          "toolkit.coverage.endpoint.base" = "";
          "browser.newtabpage.activity-stream.feeds.telemetry" = false;
          "browser.newtabpage.activity-stream.telemetry" = false;

          # STUDIES
          "app.shield.optoutstudies.enabled" = false;
          "app.normandy.enabled" = false;
          "app.normandy.api_url" = "";

          # CRASH REPORTS
          "breakpad.reportURL" = "";
          "browser.tabs.crashReporting.sendReport" = false;
          "browser.crashReports.unsubmittedCheck.autoSubmit2" = false;
          "captivedetect.canonicalURL" = "";
          "network.captive-portal-service.enabled" = false;
          "network.connectivity-service.enabled" = false;

          # SAFE BROWSING
          "browser.safebrowsing.malware.enabled" = true;
          "browser.safebrowsing.phishing.enabled" = true;
          "browser.safebrowsing.downloads.enabled" = true;
          "browser.safebrowsing.downloads.remote.enabled" = false;
          "browser.safebrowsing.downloads.remote.url" = "";

          # BLOCK IMPLICIT OUTBOUND
          "network.prefetch-next" = false;
          "network.dns.disablePrefetch" = true;
          "network.predictor.enabled" = false;
          "network.predictor.enabled-prefetch" = false;
          "browser.places.speculativeConnect.enabled" = false;
          "browser.send_pings" = false;

          # DNS / DoH / PROXY / SOCKS
          "network.proxy.socks_remote_dns" = true;
          "network.file.disable_unc_paths" = true;
          "network.gio.supported-protocols" = "";
          "network.trr.mode" = 2;

          # LOCATION BAR / SEARCH BAR / SUGGESTIONS / HISTORY / FORMS
          "browser.search.suggest.enabled" = false;
          "browser.urlbar.speculativeConnect.enabled" = false;
          "browser.urlbar.suggest.searches" = false;
          "browser.urlbar.suggest.engines" = false;
          "browser.urlbar.suggest.history" = false;
          "browser.urlbar.suggest.bookmark" = false;
          "browser.urlbar.suggest.openpage" = false;
          "browser.urlbar.suggest.topsites" = false;
          "browser.urlbar.trending.featureGate" = false;
          "browser.urlbar.addons.featureGate" = false;
          "browser.urlbar.pocket.featureGate" = false;
          "browser.urlbar.mdn.featureGate" = false;
          "browser.urlbar.weather.featureGate" = false;
          "browser.urlbar.yelp.featureGate" = false;
          "browser.urlbar.clipboard.featureGate" = false;
          "browser.formfill.enable" = false;
          "layout.css.visited_links_enabled" = false;
          "browser.search.separatePrivateDefault" = true;
          "browser.search.separatePrivateDefault.ui.enabled" = true;

          # PASSWORDS
          "signon.autofillForms" = false;
          "signon.formlessCapture.enabled" = false;
          "network.auth.subresource-http-auth-allow" = 1;

          # DISK AVOIDANCE
          "browser.cache.disk.enable" = false;
          "browser.privatebrowsing.forceMediaMemoryCache" = true;
          "media.memory_cache_max_size" = 65536;
          "browser.sessionstore.privacy_level" = 2;
          "browser.shell.shortcutFavicons" = false;

          # HTTPS (SSL/TLS / OCSP / CERTS / HPKP)
          "security.ssl.require_safe_negotiation" = true;
          "security.tls.enable_0rtt_data" = false;
          "security.OCSP.enabled" = 1;
          "security.OCSP.require" = true;
          "security.cert_pinning.enforcement_level" = 2;
          "security.remote_settings.crlite_filters.enabled" = true;
          "security.pki.crlite_mode" = 2;
          "dom.security.https_only_mode" = true;
          "dom.security.https_only_mode_send_http_background_request" = false;
          "security.ssl.treat_unsafe_negotiation_as_broken" = true;
          "browser.xul.error_pages.expert_bad_cert" = true;
          "security.mixed_content.block_display_content" = true;

          # REFERERS
          "network.http.referer.XOriginTrimmingPolicy" = 2;

          # CONTAINERS
          "privacy.userContext.enabled" = true;
          "privacy.userContext.ui.enabled" = true;

          # PLUGINS / MEDIA / WEBRTC
          "media.peerconnection.ice.proxy_only_if_behind_proxy" = true;
          "media.peerconnection.ice.default_address_only" = true;
          "media.gmp-provider.enabled" = false;

          # DOM (DOCUMENT OBJECT MODEL)
          "dom.disable_window_move_resize" = true;
          "dom.security.https_first" = true;
          "dom.forms.autocomplete.formautofill" = false;
          "dom.battery.enabled" = false;
          "dom.webnotifications.enabled" = false;
          "dom.push.enabled" = false;
          "dom.security.https_only_mode_ever_enabled" = true;
          "dom.event.clipboardevents.enabled" = false;
          "dom.event.contextmenu.enabled" = false;
          "dom.gamepad.enabled" = false;

          # MISCELLANEOUS
          "browser.download.start_downloads_in_tmp_dir" = true;
          "browser.helperApps.deleteTempFileOnExit" = true;
          "browser.uitour.enabled" = false;
          "browser.uitour.url" = "";
          "devtools.debugger.remote-enabled" = false;
          "permissions.manager.defaultsUrl" = "";
          "webchannel.allowObject.urlWhitelist" = "";
          "network.IDN_show_punycode" = true;
          "pdfjs.disabled" = false;
          "pdfjs.enableScripting" = false;
          "browser.tabs.searchclipboardfor.middleclick" = false;
          "browser.download.useDownloadDir" = false;
          "browser.download.alwaysOpenPanel" = false;
          "browser.download.manager.addToRecentDocs" = false;
          "browser.download.always_ask_before_handling_new_types" = true;

          # EXTENSIONS
          "extensions.postDownloadThirdPartyPrompt" = false;
          "extensions.update.enabled" = false;
          "extensions.pocket.enabled" = false;
          "extensions.getAddons.langpacks.url" = "";
          "extensions.screenshots.disabled" = true;
          "extensions.formautofill.addresses.enabled" = false;
          "extensions.formautofill.creditCards.enabled" = false;

          # ETP (ENHANCED TRACKING PROTECTION)
          "browser.contentblocking.category" = "strict";
          "browser.contentblocking.report.hide_vpn_banner" = true;
          "browser.contentblocking.report.mobile-ios.url" = "";
          "browser.contentblocking.report.mobile-android.url" = "";
          "browser.contentblocking.report.show_mobile_app" = false;
          "browser.contentblocking.report.vpn.enabled" = false;
          "browser.contentblocking.report.vpn.url" = "";
          "browser.contentblocking.report.vpn-promo.url" = "";
          "browser.contentblocking.report.vpn-android.url" = "";
          "browser.contentblocking.report.vpn-ios.url" = "";

          # SHUTDOWN & SANITIZING
          "privacy.sanitize.sanitizeOnShutdown" = true;
          "privacy.clearOnShutdown.history" = true;
          "privacy.clearOnShutdown.downloads" = true;
          "privacy.clearOnShutdown.formdata" = true;
          "privacy.clearOnShutdown.cache" = true;
          "privacy.clearOnShutdown_v2.cache" = true;
          "privacy.clearOnShutdown.cookies" = false;
          "privacy.clearOnShutdown_v2.cookiesAndStorage" = false;
          "privacy.clearOnShutdown.offlineApps" = true;
          "privacy.clearOnShutdown.openWindows" = true;
          "privacy.clearOnShutdown.sessions" = false;
          "privacy.clearOnShutdown_v2.historyFormDataAndDownloads" = true;
          "privacy.clearOnShutdown.siteSettings" = false;
          "privacy.clearOnShutdown_v2.siteSettings" = false;
          "privacy.clearSiteData.cache" = true;
          "privacy.clearSiteData.cookiesAndStorage" = false;
          "privacy.clearSiteData.historyFormDataAndDownloads" = true;
          "privacy.clearSiteData.siteSettings" = false;
          "privacy.cpd.cache" = true;
          "privacy.clearHistory.cache" = true;
          "privacy.cpd.formdata" = true;
          "privacy.cpd.history" = true;
          "privacy.clearHistory.historyFormDataAndDownloads" = true;
          "privacy.cpd.cookies" = false;
          "privacy.cpd.sessions" = true;
          "privacy.cpd.offlineApps" = false;
          "privacy.clearHistory.cookiesAndStorage" = false;
          "privacy.sanitize.timeSpan" = 0;

          # FPP (fingerprintingProtection) & RFP (resistFingerprinting)
          "privacy.resistFingerprinting" = false; # FIXME breaks sites
          #"privacy.resistFingerprinting.block_mozAddonManager" = true;
          #"privacy.resistFingerprinting.letterboxing" = true;
          #"privacy.window.maxInnerWidth" = 1600;
          #"privacy.window.maxInnerHeight" = 900;
          "privacy.spoof_english" = 1;
          "browser.display.use_system_colors" = false;
          "browser.link.open_newwindow" = 3;
          "browser.link.open_newwindow.restriction" = 0;
          "webgl.disabled" = false;

          # DON'T TOUCH
          "extensions.blocklist.enabled" = true;
          "network.http.referer.spoofSource" = false;
          "privacy.firstparty.isolate" = false;
          "extensions.webcompat-reporter.enabled" = false;

          # PERSONAL SETTINGS
          "general.smoothScroll" = true;
          "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.addons" = false;
          "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.features" = false;
          "browser.urlbar.showSearchTerms.enabled" = false;
          "browser.tabs.warnOnClose" = false;
          "browser.tabs.loadBookmarksInTabs" = true;
          "browser.privatebrowsing.vpnpromourl" = "";
          "browser.shell.checkDefaultBrowser" = false;
          "browser.aboutwelcome.enabled" = false;
          "browser.compactmode.show" = true;
          "browser.urlbar.unitConversion.enabled" = true;
          "browser.newtabpage.activity-stream.feeds.topsites" = false;
          "browser.download.open_pdf_attachments_inline" = true;
          "browser.bookmarks.openInTabClosesMenu" = false;
          "browser.menu.showViewImageInfo" = true;
          "browser.toolbars.bookmarks.visibility" = "always";
          "browser.ctrlTab.sortByRecentlyUsed" = true;
          "browser.uidensity" = 1;
          "browser.discovery.containers.enabled" = false;
          "browser.discovery.sites" = "";
          "browser.contentblocking.report.monitor.home_page_url" = "";
          "browser.safebrowsing.provider.google.updateURL" = "";
          "browser.safebrowsing.provider.google.gethashURL" = "";
          "browser.safebrowsing.provider.google4.updateURL" = "";
          "browser.safebrowsing.provider.google4.gethashURL" = "";
          "browser.safebrowsing.provider.mozilla.gethashURL" = "";
          "browser.safebrowsing.provider.mozilla.updateURL" = "";
          "browser.search.update" = false;
          "browser.sessionstore.max_resumed_crashes" = 0;
          "browser.xr.warning.infoURL" = "";

          # URLs
          "app.update.url.details" = "";
          "app.update.url.manual" = "";
          "app.support.baseURL" = "";
          "app.feedback.baseURL" = "";

          # PRIVACY
          "privacy.trackingprotection.enabled" = true;
          "privacy.trackingprotection.socialtracking.enabled" = true;
          "privacy.trackingprotection.cryptomining.enabled" = true;
          "privacy.trackingprotection.fingerprinting.enabled" = true;
          "privacy.globalprivacycontrol.enabled" = true;

          # MEDIA
          "media.ffmpeg.vaapi.enabled" = true; # Hardware video acceleration with VA_API
          "media.eme.enabled" = true;
          "media.videocontrols.picture-in-picture.enabled" = true;
          "media.autoplay.default" = 5;
          "gfx.webrender.all" = true; # set webrender composition

          # IMAGE CACHE
          "image.mem.decode_bytes_at_a_time" = 32768;

          # NETWORK
          "network.http.pacing.requests.enabled" = false;
          "network.dnsCacheExpiration" = 3600;
          "network.http.originextension" = false;
          "network.cookie.sameSite.noneRequiresSecure" = true;

          # HEADERS / REFERERS
          "network.trr.confirmation_telemetry_enabled" = false;
          "network.http.speculative-parallel-limit" = 0;
          "network.http.sendRefererHeader" = 2;

          # LAYOUT
          "layout.spellcheckDefault" = 0;
          "layout.word_select.eat_space_to_next_word" = false;
          "nglayout.initialpaint.delay" = 0;
          "nglayout.initialpaint.delay_in_oopif" = 0;
          "findbar.highlightAll" = true;
          "intl.accept_languages" = "en, de";
          "accessibility.typeaheadfind" = true;
          "identity.fxaccounts.enabled" = false;
          "identity.mobilepromo.android" = "";
          "xpinstall.signatures.required" = false;

          "font.default.x-western" = "sans-serif";
          "lightweightThemes.getMoreURL" = "";
          "beacon.enabled" = false;

          # SIGNON
          "signon.rememberSignons" = false;
          "signon.management.page.breach-alerts.enabled" = true;
          "signon.privateBrowsingCapture.enabled" = false;

          # REPORTS
          "datareporting.policy.dataSubmissionEnabled" = false;
          "datareporting.policy.dataSubmissionPolicyAcceptedVersion" = 2;

          # COOKIE BANNER HANDLING
          "cookiebanners.service.mode" = 1;
          "cookiebanners.service.mode.privateBrowsing" = 1;
          "cookiebanners.service.enableGlobalRules" = true;

          # FULLSCREEN NOTICE
          "full-screen-api.transition-duration.enter" = "0 0";
          "full-screen-api.transition-duration.leave" = "0 0";
          "full-screen-api.warning.delay" = -1;
          "full-screen-api.warning.timeout" = 0;

          # SERVICES
          "services.sync.prefs.sync.browser.startup.homepage" = false;
          "devtools.selfxss.count" = 0;
          "device.sensors.enabled" = false;
          "places.history.enabled" = false;

          # this enableds custom userChrome and userContent css files
          "toolkit.legacyUserProfileCustomizations.stylesheets" = true;

          # make here custom shyfox or ff-ultima user.js settings here
          # shyfox
        };
        ## custom theme
        # FF_ULTIMA
        #userChrome = builtins.readFile "${ffultima}/userChrome.css";
        #userContent = builtins.readFile "${ffultima}/userContent.css";
        #extraConfig = builtins.readFile "${ffultima}/user.js";

        # shyfox
        extraConfig = builtins.readFile "${shyfox}/user.js";
      };
    };
  };
}
