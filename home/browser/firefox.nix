{
  pkgs,
  inputs,
  ...
}: {
  home = {
    sessionVariables.BROWSER = "firefox";
  };

  programs.firefox = {
    enable = true;
    package = pkgs.firefox;
    policies = {
      AppAutoUpdate = false;
      DisableFirefoxStudies = true;
      DisablePocket = true;
      DisableTelemetry = true;
      DisableFirefoxAccounts = true;
      DontCheckDefaultBrowser = true;
      #NoDefaultBookmarks = false; # This policy must be removed or set to false, otherwise bookmarks cannot be added or removed by Nix
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
        bookmarks = import ./bookmarks.nix;
        isDefault = true;
        #containers = {
        #  "Personal" = {
        #    id = 1;
        #    color = "green";  # one of “blue”, “turquoise”, “green”, “yellow”, “orange”, “red”, “pink”, “purple”, “toolbar”
        #    icon = "fingerprint"; # one of “briefcase”, “cart”, “circle”, “dollar”, “fence”, “fingerprint”, “gift”, “vacation”, “food”, “fruit”, “pet”, “tree”, “chill”
        #  };
        #  "Shopping" = {
        #    id = 2;
        #    color = "yellow";
        #    icon = "circle";
        #  };
        #};
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
          # GFX
          "gfx.canvas.accelerated.cache-items" = 4096;
          "gfx.canvas.accelerated.cache-size" = 512;
          "gfx.content.skia-font-cache-size" = 20;
          "gfx.webrender.all" = true;
          "gfx.webrender.enabled" = true;
          # DISK CACHE
          "browser.cache.jsbc_compression_level" = 3;
          # MEDIA CACHE
          "media.memory_cache_max_size" = 65536;
          "media.cache_readahead_limit" = 7200;
          "media.cache_resume_treshold" = 3600;
          # IMAGE CACHE
          "image.mem.decode_bytes_at_a_time" = 32768;
          # NETWORK
          "network.buffer.cache.size" = 262144;
          "network.buffer.cache.count" = 128;
          "network.http.max-connections" = 1800;
          "network.http.max-persistent-connections-per-server" = 10;
          "network.http.max-urgent-start-excessive-connections-per-host" = 5;
          "network.http.pacing.requests.enabled" = false;
          "network.dnsCacheExpiration" = 3600;
          "network.dns.max_high_priority_threads" = 8;
          "network.ssl_tokens_cache_capacity" = 10240;
          # SPECULATIVE LOADING
          "network.dns.disablePrefetch" = true;
          "network.prefetch-next" = false;
          "network.predictor.enabled" = false;
          # TRACKING PROTECTION
          "browser.contentblocking.category" = "strict";
          "urlclassifier.trackingSkipURLs" = "*.reddit.com, *.twitter.com, *.tiktok.com";
          "urlclassifier.features.socialtracking.skipURLs" = "*.instagram.com, *.twitter.com";
          "network.cookie.sameSite.noneRequiresSecure" = true;
          "browser.download.start_downloads_in_tmp_dir" = false;
          "browser.helperApps.deleteTempFileOnExit" = true;
          "browser.uitour.enabled" = false;
          "privacy.globalprivacycontrol.enabled" = true;
          "privacy.globalprivacycontrol.functionality.enabled" = true;
          # OCSP & CERTS / HPKP
          "security.OCSP.enabled" = 0;
          "security.remote_settings.crlite_filters.enabled" = true;
          "security.pki.crlite_mode" = 2;
          # SSL / TLS
          "security.ssl.treat_unsafe_negotiation_as_broken" = true;
          "browser.xul.error_pages.expert_bad_cert" = true;
          "security.tls.enable_0rtt_data" = false;
          # DISK AVOIDANCE
          "browser.privatebrowsing.forceMediaMemoryCache" = true;
          "browser.sessionstore.interval" = 60000;
          # SHUTDOWN & SANITIZING
          "privacy.history.custom" = true;
          # SEARCH / URL BAR
          "browser.search.separatePrivateDefault.ui.enabled" = true;
          "browser.urlbar.update2.engineAliasRefresh" = true;
          "browser.search.suggest.enabled" = false;
          "browser.urlbar.suggest.quicksuggest.sponsored" = false;
          "browser.urlbar.suggest.quicksuggest.nonsponsored" = false;
          "browser.formfill.enable" = false;
          "security.insecure_connection_text.enabled" = true;
          "security.insecure_connection_text.pbmode.enabled" = true;
          "network.IDN_show_punycode" = true;
          # HTTPS-FIRST POLICY
          "dom.security.https_first" = true;
          # PASSWORDS
          "signon.rememberSignons" = false;
          "signon.autofillForms" = false;
          "signon.management.page.breach-alerts.enabled" = true;
          "signon.formlessCapture.enabled" = false;
          "signon.privateBrowsingCapture.enabled" = false;
          "network.auth.subresource-http-auth-allow" = 1;
          "editor.truncate_user_pastes" = false;
          # ADDRESS + CREDIT CARD MANAGER
          "dom.forms.autocomplete.formautofill" = false;
          "extensions.formautofill.addresses.enabled" = false;
          "extensions.formautofill.creditCards.enabled" = false;
          # MIXED CONTENT + CROSS-SITE
          "security.mixed_content.block_display_content" = true;
          "security.mixed_content.upgrade_display_content" = true;
          "security.mixed_content.upgrade_display_content.image" = true;
          "pdfjs.enableScripting" = false;
          "extensions.postDownloadThirdPartyPrompt" = false;
          # HEADERS / REFERERS
          "network.http.referer.XOriginTrimmingPolicy" = 2;
          # CONTAINERS
          "privacy.userContext.ui.enabled" = true;
          # WEBRTC
          "media.peerconnection.ice.proxy_only_if_behind_proxy" = true;
          "media.peerconnection.ice.default_address_only" = true;
          # SAFE BROWSING
          "browser.safebrowsing.downloads.remote.enabled" = false;
          # TELEMETRY
          "datareporting.policy.dataSubmissionEnabled" = false;
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
          "browser.ping-centre.telemetry" = false;
          "browser.newtabpage.activity-stream.feeds.telemetry" = false;
          "browser.newtabpage.activity-stream.telemetry" = false;
          # EXPERIMENTS
          "app.shield.optoutstudies.enabled" = false;
          "app.normandy.enabled" = false;
          "app.normandy.api_url" = "";
          # CRASH REPORTS
          "breakpad.reportURL" = "";
          "browser.tabs.crashReporting.sendReport" = false;
          "browser.crashReports.unsubmittedCheck.autoSubmit2" = false;
          # DETECTION
          "captivedetect.canonicalURL" = "";
          "network.captive-portal-service.enabled" = false;
          "network.connectivity-service.enabled" = false;
          # MOZILLA UI
          "browser.tabs.warnOnClose" = true;
          "browser.privatebrowsing.vpnpromourl" = "";
          "extensions.getAddons.showPane" = false;
          "extensions.htmlaboutaddons.recommendations.enabled" = false;
          "browser.discovery.enabled" = false;
          "browser.shell.checkDefaultBrowser" = false;
          "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.addons" = false;
          "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.features" = false;
          "browser.preferences.moreFromMozilla" = false;
          "browser.tabs.tabmanager.enabled" = true;
          "browser.aboutConfig.showWarning" = false;
          "browser.aboutwelcome.enabled" = false;
          # THEME ADJUSTMENTS
          "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
          "browser.compactmode.show" = true;
          "browser.display.focus_ring_on_anything" = true;
          "browser.display.focus_ring_style" = 0;
          "browser.display.focus_ring_width" = 0;
          "layout.css.prefers-color-scheme.content-override" = 2;
          "browser.privateWindowSeparation.enabled" = false; # WINDOWS
          # COOKIE BANNER HANDLING
          "cookiebanners.service.mode" = 1;
          "cookiebanners.service.mode.privateBrowsing" = 1;
          "cookiebanners.service.enableGlobalRules" = true;
          # FULLSCREEN NOTICE
          "full-screen-api.transition-duration.enter" = "0 0";
          "full-screen-api.transition-duration.leave" = "0 0";
          "full-screen-api.warning.delay" = -1;
          "full-screen-api.warning.timeout" = 0;
          # URL BAR
          "browser.urlbar.suggest.calculator" = true;
          "browser.urlbar.unitConversion.enabled" = true;
          "browser.urlbar.trending.featureGate" = false;
          "browser.search.suggest.enabled.private" = false;
          # NEW TAB PAGE
          "browser.newtabpage.activity-stream.feeds.topsites" = false;
          "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
          "browser.newtabpage.activity-stream.feeds.section.highlights" = false;
          # POCKET
          "extensions.pocket.enabled" = false;
          # DOWNLOADS
          "browser.download.useDownloadDir" = true;
          "browser.download.always_ask_before_handling_new_types" = true;
          "browser.download.manager.addToRecentDocs" = false;
          # PDF
          "browser.download.open_pdf_attachments_inline" = true;
          # TAB BEHAVIOR
          "browser.bookmarks.openInTabClosesMenu" = false;
          "browser.menu.showViewImageInfo" = true;
          "findbar.highlightAll" = true;
          "layout.word_select.eat_space_to_next_word" = false;
          "intl.accept_languages" = "en, de";
          # MEDIA
          "media.ffmpeg.vaapi.enable" = true;
          "media.ffvpx.enabled" = false;
          "media.videocontrols.picture-in-picture.allow-multiple" = true;
          "media.eme.enabled" = true;
          "media.videocontrols.picture-in-picture.enabled" = true;
          "widget.use-xdg-desktop-portal" = true;
          "browser.toolbars.bookmarks.visibility" = "always";
          "browser.tabs.loadInBackground" = true;
          "network.trr.confirmation_telemetry_enabled" = false;
          "browser.bookmarks.restore_default_bookmarks" = false;
          "browser.ctrlTab.recentlyUsedOrder" = true;
          "datareporting.policy.dataSubmissionEnable" = false;
          "datareporting.policy.dataSubmissionPolicyAcceptedVersion" = 2;
          "dom.security.https_only_mode" = true;
          "dom.security.https_only_mode_ever_enabled" = true;
          "identity.fxaccounts.enabled" = false;
          "privacy.trackingprotection.enabled" = true;
          "privacy.trackingprotection.socialtracking.enabled" = true;
          "browser.urlbar.placeholderName" = "Startpage";
          "browser.search.defaultenginename" = "Startpage";
          #"browser.startup.homepage" = ""; # sets homepage for new tabs or windows. default is "Firefox Home"

          # CYCLE TABS with CTRL+TAB
          "browser.ctrlTab.sortByRecentlyUsed" = true;

          # OPEN NEW WINDOW
          "browser.link.open_newwindow" = 3;

          # CONTAINER TABS
          "privacy.userContext.enabled" = true;

          # DISABLE SPELLCHECK
          "layout.spellcheckDefault" = 0;

          "accessibility.typeaheadfind" = true;

          # HISTORY
          "browser.privatebrowsing.autostart" = false;
          "places.history.enabled" = false;
          "privacy.sanitize.sanitizeOnShutdown" = true;
          "privacy.clearOnShutdown.history" = true;
          "privacy.clearOnShutdown.downloads" = true;
          "privacy.clearOnShutdown.formdata" = true;
          "privacy.clearOnShutdown.cache" = false;
          "privacy.clearOnShutdown.cookies" = false;
          "privacy.clearOnShutdown.offlineApps" = false;
          "privacy.clearOnShutdown.openWindows" = true;
          "privacy.clearOnShutdown.sessions" = false;
          "privacy.clearOnShutdown.siteSettings" = false;

          # ADDRESS BAR
          "browser.urlbar.suggest.history" = false;
          "browser.urlbar.suggest.bookmark" = true;
          "browser.urlbar.suggest.openpage" = true;
          "browser.urlbar.suggest.topsites" = false;
          "browser.urlbar.suggest.searches" = false;
        };
        # custom theme
        userChrome = builtins.readFile ./themes/ffultimate/userChrome.css;
        userContent = builtins.readFile ./themes/ffultimate/userContent.css;
      };
    };
  };
}
