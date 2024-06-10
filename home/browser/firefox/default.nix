{
  pkgs,
  inputs,
  ...
}: let
  ffTheme = pkgs.fetchFromGitHub {
    owner = "soulhotel";
    repo = "FF-ULTIMA";
    rev = "main";
    #sha256 = pkgs.lib.fakeSha256; # used to get the latest hash
    hash = "sha256-xaHugFRlUgVZd3wXsbF63gX/X/iSmm4N/ZsalG4s6Lk=";
  };
in {
  home = {
    sessionVariables.BROWSER = "firefox";
    file.".mozilla/firefox/default/chrome/theme".source = "${ffTheme}/theme";
  };

  programs.firefox = {
    enable = true;
    package = pkgs.firefox;
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
      #ExtensionSettings = with builtins; let
      #  extension = shortId: uuid: {
      #    name = uuid;
      #    value = {
      #      install_url = "https://addons.mozilla.org/en-US/firefox/downloads/latest/${shortId}/latest.xpi";
      #      installation_mode = "force_installed";
      #    };
      #  };
      #in
      #  listToAttrs [
      #    (extension "ublock-origin" "uBlock0@raymondhill.net")
      #    (extension "bitwarden-password-manager" "{446900e4-71c2-419f-a6a7-df9c091e268b}")
      #  ];
      #"*".installation_mode = "blocked";
    };
    profiles = {
      default = {
        id = 0;
        bookmarks = import ./bookmarks.nix;
        isDefault = true;
        ## #FIXME until home-manager can overwrite files or overwrite .backup files
        #containers = {
        #  "Personal" = {
        #    id = 1;
        #    color = "green"; # one of “blue”, “turquoise”, “green”, “yellow”, “orange”, “red”, “pink”, “purple”, “toolbar”
        #    icon = "fingerprint"; # one of “briefcase”, “cart”, “circle”, “dollar”, “fence”, “fingerprint”, “gift”, “vacation”, “food”, “fruit”, “pet”, “tree”, “chill”
        #  };
        #  "Shopping" = {
        #    id = 2;
        #    color = "yellow";
        #    icon = "cart";
        #  };
        #  "SocialMedia" = {
        #    id = 3;
        #    color = "orange";
        #    icon = "tree";
        #  };
        #  "Google" = {
        #    id = 4;
        #    color = "red";
        #    icon = "fence";
        #  };
        #  "Streaming" = {
        #    id = 5;
        #    color = "purple";
        #    icon = "chill";
        #  };
        #};
        extensions = with inputs.firefox-addons.packages.${pkgs.system}; [
          ublock-origin
          bitwarden
          darkreader
          side-view
          #multi-account-containers #FIXME
        ];
        search = {
          force = true;
          default = "DuckDuckGo";
          privateDefault = "DuckDuckGo";
          engines = {
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
              definedAliases = ["@no"];
            };
          };
        };
        settings = {
          # GENERAL
          "general.smoothScroll" = true;
          # APP
          "app.releaseNotesURL" = "http://127.0.0.1/";
          "app.vendorURL" = "http://127.0.0.1/";
          "app.privacyURL" = "http://127.0.0.1/";
          "app.update.url" = "http://127.0.0.1/";
          "app.support.baseURL" = "http://127.0.0.1/";
          "app.support.inputURL" = "http://127.0.0.1/";
          "app.feedback.baseURL" = "http://127.0.0.1/";
          "app.shield.optoutstudies.enabled" = false;
          "app.normandy.enabled" = false;
          "app.normandy.api_url" = "";
          "app.faqURL" = "http://127.0.0.1/";
          # KEYBINDINGS
          "ui.key.textcontrol.prefer_native_key_bindings_over_builtin_shortcut_key_definitions" = true;
          "ui.key.accelKey" = 17;
          "ui.key.menuAccessKey" = 18;
          "ui.key.menuAccessKeyFocuses" = true;
          # PRIVACY
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
          "privacy.query_stripping.strip_list" = "__hsfp __hssc __hstc __s _hsenc _openstat dclid fbclid gbraid gclid hsCtaTracking igshid mc_eid ml_subscriber ml_subscriber_hash msclkid oft_c oft_ck oft_d oft_id oft_ids oft_k oft_lk oft_sk oly_anon_id oly_enc_id rb_clickid s_cid twclid vero_conv vero_id wbraid wickedid yclid";
          "privacy.trackingprotection.enabled" = true;
          "privacy.trackingprotection.socialtracking.enabled" = true;
          "privacy.userContext.enabled" = true;
          "privacy.firstparty.isolate" = true;
          "privacy.history.custom" = true;
          "privacy.globalprivacycontrol.enabled" = true;
          "privacy.globalprivacycontrol.functionality.enabled" = true;
          "privacy.announcements.enabled" = false;
          "privacy.resistFingerprinting" = false;
          "privacy.trackingprotection.cryptomining.enabled" = true;
          "privacy.partition.always_partition_third_party_non_cookie_storage" = true;
          "privacy.partition.always_partition_third_party_non_cookie_storage.exempt_sessionstorage" = false;
          "privacy.resistFingerprinting.block_mozAddonManager" = true;
          "privacy.userContext.ui.enabled" = true;
          "privacy.trackingprotection.fingerprinting.enabled" = true;
          # BROWSER
          "browser.uitour.enabled" = false;
          "browser.uitour.url" = "http://127.0.0.1/";
          "browser.uitour.themeOrigin" = "http://127.0.0.1/";
          "browser.customizemode.tip0.learnMoreUrl" = "http://127.0.0.1/";
          "browser.region.network.scan" = false;
          "browser.region.network.url" = "";
          "browser.region.update.enabled" = false;
          "browser.privatebrowsing.promoEnabled" = false;
          "browser.newtabpage.activity-stream.asrouter.useruser_prefs.cfr" = false;
          "browser.onboarding.newtour" = "performance,private,addons,customize,default";
          "browser.onboarding.updatetour" = "performance,library,singlesearch,customize";
          "browser.onboarding.enabled" = false;
          "browser.newtabpage.activity-stream.showTopSites" = false;
          "browser.newtabpage.activity-stream.feeds.snippets" = false;
          "browser.newtabpage.activity-stream.disableSnippets" = true;
          "browser.newtabpage.activity-stream.tippyTop.service.endpoint" = "";
          "browser.privatebrowsing.autostart" = false;
          "browser.cache.jsbc_compression_level" = 3;
          "browser.cache.disk.enable" = false;
          "browser.helperApps.deleteTempFileOnExit" = true;
          "browser.shell.shortcutFavicons" = false;
          "browser.startup.preXulSkeletonUI" = false;
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
          "browser.privatebrowsing.forceMediaMemoryCache" = true;
          "browser.sessionstore.interval" = 60000;
          "browser.sessionstore.privacy_level" = 2;
          "browser.download.start_downloads_in_tmp_dir" = true;
          "browser.xul.error_pages.expert_bad_cert" = true;
          "browser.search.separatePrivateDefault.ui.enabled" = true;
          "browser.urlbar.update2.engineAliasRefresh" = true;
          "browser.search.suggest.enabled" = false;
          "browser.tabs.searchclipboardfor.middleclick" = false;
          "browser.urlbar.suggest.quicksuggest.sponsored" = false;
          "browser.urlbar.suggest.quicksuggest.nonsponsored" = false;
          "browser.formfill.enable" = false;
          "browser.safebrowsing.enabled" = false;
          "browser.safebrowsing.downloads.remote.enabled" = false;
          "browser.tabs.crashReporting.sendReport" = false;
          "browser.crashReports.unsubmittedCheck.autoSubmit2" = false;
          "browser.ping-centre.telemetry" = false;
          "browser.newtabpage.activity-stream.feeds.telemetry" = false;
          "browser.newtabpage.activity-stream.telemetry" = false;
          "browser.tabs.warnOnClose" = true;
          "browser.tabs.loadBookmarksInTabs" = true;
          "browser.tabs.tabmanager.enabled" = true;
          "browser.privatebrowsing.vpnpromourl" = "";
          "browser.discovery.enabled" = false;
          "browser.shell.checkDefaultBrowser" = false;
          "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.addons" = false;
          "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.features" = false;
          "browser.preferences.moreFromMozilla" = false;
          "browser.aboutConfig.showWarning" = false;
          "browser.aboutwelcome.enabled" = false;
          "browser.compactmode.show" = true;
          "browser.display.focus_ring_on_anything" = true;
          "browser.display.focus_ring_style" = 0;
          "browser.display.focus_ring_width" = 0;
          "browser.urlbar.suggest.calculator" = true;
          "browser.urlbar.unitConversion.enabled" = true;
          "browser.urlbar.trending.featureGate" = false;
          "browser.search.suggest.enabled.private" = false;
          "browser.privateWindowSeparation.enabled" = false; # WINDOWS
          "browser.newtabpage.activity-stream.feeds.topsites" = false;
          "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
          "browser.newtabpage.activity-stream.feeds.section.highlights" = false;
          "browser.download.useDownloadDir" = true;
          "browser.download.always_ask_before_handling_new_types" = true;
          "browser.download.manager.addToRecentDocs" = false;
          "browser.download.open_pdf_attachments_inline" = true;
          "browser.bookmarks.openInTabClosesMenu" = false;
          "browser.menu.showViewImageInfo" = true;
          "browser.toolbars.bookmarks.visibility" = "always";
          "browser.tabs.loadInBackground" = true;
          "browser.bookmarks.restore_default_bookmarks" = false;
          "browser.ctrlTab.recentlyUsedOrder" = true;
          "browser.urlbar.placeholderName" = "Startpage";
          "browser.search.defaultenginename" = "Startpage";
          #"browser.startup.homepage" = ""; # sets homepage for new tabs or windows. default is "Firefox Home"
          "browser.ctrlTab.sortByRecentlyUsed" = true;
          "browser.link.open_newwindow" = 3;
          "browser.urlbar.suggest.history" = false;
          "browser.urlbar.suggest.bookmark" = true;
          "browser.urlbar.suggest.openpage" = true;
          "browser.urlbar.suggest.topsites" = false;
          "browser.urlbar.suggest.searches" = false;
          # Privacy & Freedom Issues
          # https:webdevelopmentaid.wordpress.com/2013/10/21/customize-privacy-settings-in-mozilla-firefox-part-1-aboutconfig/
          # https:panopticlick.eff.org
          # http:ip-check.info
          # http:browserspy.dk
          # https:wiki.mozilla.org/Fingerprinting
          # http:www.browserleaks.com
          # http:fingerprint.pet-portal.eu
          "browser.translation.engine" = "";
          "browser.uidensity" = 1;
          "browser.EULA.override" = true;
          "browser.startup.homepage_override.mstone" = "ignore";
          "browser.newtabpage.activity-stream.showSponsored" = false;
          "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
          "browser.urlbar.suggest.engines" = false;
          "browser.urlbar.mdn.featureGate" = false;
          "browser.urlbar.weather.featureGate" = false;
          "browser.shopping.experience2023.enabled" = false;
          "browser.discovery.containers.enabled" = false;
          "browser.discovery.sites" = "http://127.0.0.1/";
          "browser.contentblocking.report.monitor.home_page_url" = "http://127.0.0.1/";
          "browser.safebrowsing.malware.enabled" = false;
          "browser.safebrowsing.provider.google.updateURL" = "";
          "browser.safebrowsing.provider.google.gethashURL" = "";
          "browser.safebrowsing.provider.google4.updateURL" = "";
          "browser.safebrowsing.provider.google4.gethashURL" = "";
          "browser.safebrowsing.provider.mozilla.gethashURL" = "";
          "browser.safebrowsing.provider.mozilla.updateURL" = "";
          "browser.slowStartup.notificationDisabled" = true;
          "browser.send_pings" = false;
          "browser.search.update" = false;
          "browser.urlbar.speculativeConnect.enabled" = false;
          "browser.urlbar.userMadeSearchSuggestionsChoice" = true;
          "browser.sessionstore.max_resumed_crashes" = 0;
          "browser.selfsupport.url" = "";
          "browser.newtabpage.directory.source" = "";
          "browser.newtabpage.directory.ping" = "";
          "browser.newtabpage.introShown" = true;
          "browser.search.geoip.url" = "";
          "browser.search.geoSpecificDefaults" = false;
          "browser.search.geoSpecificDefaults.url" = "";
          "browser.search.modernConfig" = false;
          "browser.display.use_system_colors" = false;
          "browser.geolocation.warning.infoURL" = "";
          "browser.xr.warning.infoURL" = "";
          "browser.contentHandlers.types.0.title" = "";
          "browser.contentHandlers.types.0.uri" = "";
          "browser.contentHandlers.types.1.title" = "";
          "browser.contentHandlers.types.1.uri" = "";
          "browser.snippets.enabled" = false;
          "browser.snippets.syncPromo.enabled" = false;
          "browser.snippets.geoUrl" = "http://127.0.0.1/";
          "browser.snippets.updateUrl" = "http://127.0.0.1/";
          "browser.snippets.statsUrl" = "http://127.0.0.1/";
          "browser.webapps.checkForUpdates" = 0;
          "browser.webapps.updateCheckUrl" = "http://127.0.0.1/";
          "browser.apps.URL" = "";
          "browser.user_preferences.inContent" = false;
          "browser.aboutHomeSnippets.updateUrl" = "data:text/html";
          "browser.user_preferences.moreFromMozilla" = false;
          "browser.casting.enabled" = false;
          "browser.pocket.enabled" = false;
          # PLUGINS
          "plugins.enumerable_names" = "";
          "plugins.update.url" = "http://127.0.0.1/";
          "plugin.state.flash" = 0;
          # GFX
          "gfx.canvas.accelerated.cache-items" = 4096;
          "gfx.canvas.accelerated.cache-size" = 512;
          "gfx.content.skia-font-cache-size" = 20;
          "gfx.webrender.all" = true;
          "gfx.webrender.enabled" = true;
          "gfx.xrender.enabled" = true;
          # MEDIA
          "media.memory_cache_max_size" = 65536;
          "media.cache_readahead_limit" = 7200;
          "media.cache_resume_treshold" = 3600;
          "media.gmp-provider.enabled" = false;
          "media.ffmpeg.vaapi.enable" = true;
          "media.ffvpx.enabled" = false;
          "media.videocontrols.picture-in-picture.allow-multiple" = true;
          "media.eme.enabled" = true;
          "media.videocontrols.picture-in-picture.enabled" = true;
          "media.autoplay.default" = 5;
          "media.peerconnection.ice.proxy_only_if_behind_proxy" = true;
          "media.peerconnection.ice.default_address_only" = true;
          # IMAGE CACHE
          "image.mem.decode_bytes_at_a_time" = 32768;
          # NETWORK
          "network.buffer.cache.size" = 262144;
          "network.buffer.cache.count" = 128;
          "network.http.max-connections" = 1800;
          "network.http.max-persistent-connections-per-server" = 10;
          "network.http.max-urgent-start-excessive-connections-per-host" = 5;
          "network.http.pacing.requests.enabled" = false;
          "network.http.pipelining" = true;
          "network.http.proxy.pipelining" = true;
          "network.http.pipelining.maxrequests" = 10;
          "network.dnsCacheExpiration" = 3600;
          "network.dns.max_high_priority_threads" = 8;
          "network.ssl_tokens_cache_capacity" = 10240;
          "network.dns.disablePrefetch" = true;
          "network.prefetch-next" = false;
          "network.predictor.enabled" = false;
          "network.http.originextension" = false;
          "network.user_prefetch-next" = false;
          "network.cookie.sameSite.noneRequiresSecure" = true;
          "network.IDN_show_punycode" = true;
          "network.auth.subresource-http-auth-allow" = 1;
          # HEADERS / REFERERS
          "network.http.referer.XOriginTrimmingPolicy" = 2;
          "network.captive-portal-service.enabled" = false;
          "network.connectivity-service.enabled" = false;
          "network.trr.confirmation_telemetry_enabled" = false;
          "network.http.speculative-parallel-limit" = 0;
          "network.gio.supported-protocols" = ""; # disable gio as it could bypass proxy
          "network.file.disable_unc_paths" = true; # hidden, disable using uniform naming convention to prevent proxy bypass
          "network.proxy.socks_remote_dns" = true; # forces dns query through the proxy when using one
          "network.http.sendSecureXSiteReferrer" = false;
          "network.http.sendRefererHeader" = 2;
          "network.http.referer.spoofSource" = true;
          # LAYOUT
          "layout.spellcheckDefault" = 0;
          "layout.word_select.eat_space_to_next_word" = false;
          "layout.css.moz-document.content.enabled" = true;
          "nglayout.initialpaint.delay" = 0;
          "nglayout.initialpaint.delay_in_oopif" = 0;
          # IDK
          "content.notify.interval" = 100000;
          "urlclassifier.trackingSkipURLs" = "*.reddit.com, *.twitter.com, *.tiktok.com";
          "urlclassifier.features.socialtracking.skipURLs" = "*.instagram.com, *.twitter.com";
          "editor.truncate_user_pastes" = false;
          "pdfjs.enableScripting" = false;
          "breakpad.reportURL" = "";
          "findbar.highlightAll" = true;
          "intl.accept_languages" = "en, de";
          "widget.use-xdg-desktop-portal" = true;
          "accessibility.typeaheadfind" = true;
          "identity.fxaccounts.enabled" = false;
          "identity.mobilepromo.android" = "http://127.0.0.1/";
          "xpinstall.signatures.required" = false;
          "startup.homepage_welcome_url" = "";
          "font.default.x-western" = "sans-serif";
          "handlerService.schemes.mailto.1.uriTemplate" = "";
          "loop.enabled" = false; # Disable Firefox Hello
          "lightweightThemes.getMoreURL" = "http://127.0.0.1/";
          "beacon.enabled" = false;
          "webchannel.allowObject.urlWhitelist" = "";
          "experiments.manifest.uri" = "";
          # OCSP / TLS / SSL / CERTS
          "security.OCSP.enabled" = 0;
          "security.OCSP.require" = false;
          "security.remote_settings.crlite_filters.enabled" = true;
          "security.pki.crlite_mode" = 2;
          "security.insecure_connection_text.enabled" = true;
          "security.insecure_connection_text.pbmode.enabled" = true;
          "security.mixed_content.block_display_content" = true;
          "security.mixed_content.upgrade_display_content" = true;
          "security.mixed_content.upgrade_display_content.image" = true;
          "security.ssl.treat_unsafe_negotiation_as_broken" = true;
          "security.ssl.errorReporting.enabled" = false;
          "security.ssl.require_safe_negotiation" = false;
          "security.tls.unrestricted_rc4_fallback" = false;
          "security.tls.enable_0rtt_data" = false;
          "security.tls.insecure_fallback_hosts.use_static_list" = false;
          "security.tls.version.enable-deprecated" = false;
          "security.tls.version.min" = 1;
          "security.cert_pinning.enforcement_level" = 2;
          "security.certerrors.mitm.priming.enabled" = false;
          "security.certerrors.recordEventTelemetry" = false;
          "security.ssl3.dhe_rsa_aes_128_sha" = false;
          "security.ssl3.dhe_rsa_aes_256_sha" = false;
          "security.ssl3.dhe_dss_aes_128_sha" = false;
          "security.ssl3.dhe_rsa_des_ede3_sha" = false;
          "security.ssl3.rsa_des_ede3_sha" = false;
          "security.ssl3.rsa_seed_sha" = true;
          # EXTENSIONS
          "extensions.postDownloadThirdPartyPrompt" = false;
          "extensions.getAddons.showPane" = false;
          "extensions.htmlaboutaddons.recommendations.enabled" = false;
          "extensions.update.enabled" = false;
          "extensions.pocket.enabled" = false;
          "extensions.autoDisableScopes" = 3;
          "extensions.blocklist.enabled" = false;
          "extensions.shield-recipe-client.enabled" = false;
          "extensions.getAddons.langpacks.url" = "http://127.0.0.1/";
          "extensions.allowPrivateBrowsingByDefault" = true;
          "extensions.screenshots.disabled" = true;
          "extensions.htmlaboutaddons.discover.enabled" = false;
          "extensions.formautofill.addresses.enabled" = false;
          "extensions.formautofill.creditCards.enabled" = false;
          # DOM
          "dom.security.https_first" = true;
          "dom.forms.autocomplete.formautofill" = false;
          "dom.ipc.plugins.flash.subprocess.crashreporter.enabled" = false;
          "dom.security.https_only_mode" = true;
          "dom.battery.enabled" = false;
          "dom.webnotifications.enabled" = false; # Disable push notifications
          "dom.webnotifications.serviceworker.enabled" = false;
          "dom.push.enabled" = false;
          "dom.security.https_only_mode_ever_enabled" = true;
          "dom.event.clipboardevents.enabled" = false; # Prevent sites from taking over copy/paste
          "dom.event.contextmenu.enabled" = false; # Prevent sites from taking over right click
          "dom.gamepad.enabled" = false;
          # TOOLKIT
          "toolkit.telemetry.unified" = false;
          "toolkit.telemetry.enabled" = false;
          "toolkit.telemetry.server" = "";
          "toolkit.telemetry.archive.enabled" = false;
          "toolkit.telemetry.newProfilePing.enabled" = false;
          "toolkit.telemetry.shutdownPingSender.enabled" = false;
          "toolkit.telemetry.updatePing.enabled" = false;
          "toolkit.telemetry.bhrPing.enabled" = false;
          "toolkit.telemetry.firstShutdownPing.enabled" = false;
          "toolkit.telemetry.coverage.opt-out" = true;
          "toolkit.coverage.opt-out" = true;
          "toolkit.coverage.endpoint.base" = "";
          "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
          "toolkit.zoomManager.zoomValues" = ".8,.90,.95,1,1.1,1.2";
          # SIGNON
          "signon.rememberSignons" = false;
          "signon.autofillForms" = false;
          "signon.management.page.breach-alerts.enabled" = true;
          "signon.formlessCapture.enabled" = false;
          "signon.privateBrowsingCapture.enabled" = false;
          # REPORTS
          "healthreport.uploadEnabled" = false;
          "datareporting.policy.dataSubmissionEnabled" = false;
          "datareporting.healthreport.uploadEnabled" = false;
          "datareporting.policy.dataSubmissionEnable" = false;
          "datareporting.policy.dataSubmissionPolicyAcceptedVersion" = 2;
          "datareporting.policy.firstRunTime" = 0;
          "datareporting.policy.dataSubmissionPolicyVersion" = 2;
          "datareporting.healthreport.about.reportUrl" = "http://127.0.0.1/";
          "datareporting.healthreport.service.enabled" = false;
          "datareporting.healthreport.documentServerURI" = "http://127.0.0.1/";
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
          "services.sync.privacyURL" = "http://127.0.0.1/";
          "services.settings.server" = "";
          # SOCIAL
          "social.enabled" = false;
          "social.remote-install.enabled" = false;
          "social.toast-notifications.enabled" = false;
          "social.directories" = "";
          # DEVTOOLS
          "devtools.debugger.remote-enabled" = false;
          "devtools.selfxss.count" = 0;
          # DEVICES
          "device.sensors.enabled" = false;
          "camera.control.face_detection.enabled" = false;
          "camera.control.autofocus_moving_callback.enabled" = false;
          # GEOLOCATION
          "geo.enabled" = false;
          "geo.wifi.uri" = "";
          "places.history.enabled" = false;
          # GECKO
          "gecko.handlerService.schemes.mailto.0.name" = "";
          "gecko.handlerService.schemes.mailto.1.name" = "";
          "gecko.handlerService.schemes.mailto.0.uriTemplate" = "";
          "gecko.handlerService.schemes.webcal.0.name" = "";
          "gecko.handlerService.schemes.webcal.0.uriTemplate" = "";
          "gecko.handlerService.schemes.irc.0.name" = "";
          "gecko.handlerService.schemes.irc.0.uriTemplate" = "";
          # PFS
          "pfs.datasource.url" = "http://127.0.0.1/";
          "pfs.filehint.url" = "http://127.0.0.1/";
          # PERMISSIONS
          "permissions.delegation.enabled" = true;
          "permissions.manager.defaultsUrl" = "";
        };
        # custom theme
        userChrome = builtins.readFile "${ffTheme}/userChrome.css";
        userContent = builtins.readFile "${ffTheme}/userContent.css";
        extraConfig = builtins.readFile ./user.js;
      };
    };
  };
}
