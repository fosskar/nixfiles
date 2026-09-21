{
  flake.modules.nixos.homepage =
    { flake-self, ... }:
    let
      sansFont = flake-self.themes.${flake-self.theme}.fonts.sans;
    in
    {
      services.homepage-dashboard = {
        settings.quicklaunch = {
          searchDescriptions = true;
          hideInternetSearch = false;
          showSearchSuggestions = true;
          hideVisitURL = false;
          provider = "custom";
          url = "https://search.nx3.eu/search?q=";
        };

        # sections come from the apply in homepage.nix; bookmarks carry no tab
        # and therefore show on both
        settings.layout = [
          # two groups per row: apps | tools, management | monitoring
          { apps.tab = "Apps"; }
          { tools.tab = "Apps"; }
          { management.tab = "Apps"; }
          { monitoring.tab = "Apps"; }
          { admin.tab = "Admin"; }
          { "arr-stack".tab = "Admin"; }
        ];

        # tiles the cross-host collector can't provide: external non-NixOS devices and local-only endpoints
        services = [
          {
            "network" = [
              {
                "OpenWrt Router" = {
                  href = "https://192.168.10.1";
                  icon = "openwrt.svg";
                };
              }
              {
                "OpenWrt AP" = {
                  href = "https://192.168.10.2";
                  icon = "openwrt.svg";
                };
              }
              {
                "AdGuard Home" = {
                  href = "http://192.168.10.1:8080";
                  icon = "adguard-home.svg";
                };
              }
            ];
          }
          {
            "infrastructure" = [
              {
                "JetKVM HA" = {
                  href = "http://jetkvm-ha.lan";
                  icon = "sh-jetkvm";
                  siteMonitor = "http://192.168.10.30";
                };
              }
              {
                "JetKVM nixworker" = {
                  href = "http://192.168.20.211";
                  icon = "sh-jetkvm";
                  siteMonitor = "http://192.168.20.211";
                };
              }
              {
                # no siteMonitor: this is nixbox's own BMC on the shared NIC, and
                # the host cannot reach it (no ping, no tcp) although the LAN can
                "Nixbox BMC" = {
                  href = "https://192.168.20.205";
                  icon = "mdi-server-network";
                };
              }
              {
                "HP Printer" = {
                  href = "http://192.168.10.153";
                  icon = "mdi-printer";
                };
              }
            ];
          }
          {
            "code" = [
              {
                "Home Assistant" = {
                  href = "http://homeassistant.lan:8123";
                  icon = "home-assistant.svg";
                  siteMonitor = "http://homeassistant.lan:8123";
                };
              }
            ];
          }
        ];

        bookmarks = [
          {
            "NixOS" = [
              {
                "NixOS Search" = [
                  {
                    icon = "nixos.svg";
                    href = "https://search.nixos.org";
                  }
                ];
              }
              {
                "Nixpkgs Repo" = [
                  {
                    icon = "github.svg";
                    href = "https://github.com/NixOS/nixpkgs";
                  }
                ];
              }
            ];
          }
          {
            "Home Manager" = [
              {
                "Home Manager Search" = [
                  {
                    icon = "nixos.svg";
                    href = "https://home-manager-options.extranix.com";
                  }
                ];
              }
              {
                "Home Manager Repo" = [
                  {
                    icon = "github.svg";
                    href = "https://github.com/nix-community/home-manager";
                  }
                ];
              }
            ];
          }
          {
            "DNS Management" = [
              {
                "deSEC" = [
                  {
                    icon = "mdi-dns";
                    href = "https://desec.io/domains";
                  }
                ];
              }
              {
                "inwx" = [
                  {
                    icon = "mdi-domain";
                    href = "https://www.inwx.de/en/";
                  }
                ];
              }
            ];
          }
          {
            "Clan" = [
              {
                "Clan Docs" = [
                  {
                    icon = "mdi-book-open-variant";
                    href = "https://docs.clan.lol/";
                  }
                ];
              }
              {
                "Clan Search" = [
                  {
                    icon = "mdi-magnify";
                    href = "https://docs.clan.lol/option-search/";
                  }
                ];
              }
              {
                "Clan Repo" = [
                  {
                    icon = "gitea.svg";
                    href = "https://git.clan.lol/clan/clan-core/";
                  }
                ];
              }
            ];
          }
        ];

        widgets = [
          {
            search = {
              provider = "custom";
              url = "https://search.nx3.eu/search?q=";
              target = "_blank";
              showSearchSuggestions = true;
            };
          }
          {
            datetime = {
              locale = "de";
              format = {
                dateStyle = "short";
                timeStyle = "short";
                hour12 = false;
              };
            };
          }
        ];

        # glass look: tailwind's dark: variants have two-class specificity, so
        # every override is anchored on an id to win without !important. groups
        # listed in settings.layout render under #layout-groups, the rest under
        # #services / #bookmarks
        customCSS = ''
          :root {
            --glass-bg: rgba(255, 255, 255, 0.055);
            --glass-bg-hover: rgba(255, 255, 255, 0.10);
            --glass-border: rgba(255, 255, 255, 0.10);
            --glass-border-hover: rgba(255, 255, 255, 0.24);
            --glass-radius: 18px;
            --glass-radius-sm: 12px;
          }

          /* the theme's sans on machines that have it; phones fall back to
             their platform font (Roboto / SF), which is the same modern look */
          body,
          #page_wrapper {
            font-family: "${sansFont}", system-ui, -apple-system, "Segoe UI", Roboto, sans-serif;
          }

          #page_wrapper {
            background:
              radial-gradient(1200px 600px at 8% -10%, rgba(20, 184, 166, 0.30), transparent 60%),
              radial-gradient(900px 500px at 100% 10%, rgba(6, 182, 212, 0.22), transparent 60%),
              radial-gradient(800px 500px at 50% 110%, rgba(16, 185, 129, 0.20), transparent 60%),
              linear-gradient(180deg, #06171a 0%, #0b1f24 100%);
          }

          /* drifting blobs behind the cards so backdrop-blur has something to blur */
          #page_wrapper::before,
          #page_wrapper::after {
            content: "";
            position: fixed;
            z-index: 0;
            width: 55vw;
            height: 55vw;
            border-radius: 50%;
            filter: blur(110px);
            opacity: 0.35;
            pointer-events: none;
            animation: glass-drift 28s ease-in-out infinite alternate;
          }
          #page_wrapper::before {
            top: -20vw;
            left: -15vw;
            background: #14b8a6;
          }
          #page_wrapper::after {
            right: -20vw;
            bottom: -25vw;
            background: #10b981;
            animation-delay: -14s;
          }
          @keyframes glass-drift {
            from { transform: translate3d(0, 0, 0) scale(1); }
            to   { transform: translate3d(8vw, 6vw, 0) scale(1.15); }
          }
          #inner_wrapper { position: relative; z-index: 1; }

          /* cards */
          :is(#layout-groups, #services) .service-card {
            border-radius: var(--glass-radius);
            border: 1px solid var(--glass-border);
            background: var(--glass-bg);
            backdrop-filter: blur(12px) saturate(150%);
            -webkit-backdrop-filter: blur(12px) saturate(150%);
            box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.07);
            padding: 0.4rem;
            margin-bottom: 0.6rem;
            transition: transform 180ms ease, border-color 180ms ease, background 180ms ease, box-shadow 180ms ease;
          }
          :is(#layout-groups, #services) .service-card:hover {
            background: var(--glass-bg-hover);
            border-color: var(--glass-border-hover);
            transform: translateY(-2px);
            box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.10);
          }
          :is(#layout-groups, #services) .service-title-text,
          :is(#layout-groups, #services) .service-icon {
            border-radius: var(--glass-radius-sm);
          }

          /* app icons: the icon plate is the button, name below, status dot on
             the plate's corner. widget values (gatus) become badges on the
             plate, see below */
          #inner_wrapper > .container {
            max-width: 1100px;
          }
          /* two groups per row from md up; homepage's own basis-1/3 / 1/4 kick
             in at lg / xl and maxGroupColumns only acts at 3xl */
          @media (min-width: 768px) {
            :is(#layout-groups, #services) .services-group.md\:basis-1\/2 {
              flex-basis: 50%;
              max-width: 50%;
            }
          }
          :is(#layout-groups, #services) .services-group {
            padding: 0;
            margin-bottom: 0.6rem;
          }
          /* homepage's disableCollapse is global only. groups carry no name in
             the DOM, so the two that stay collapsible (admin, arr-stack) are
             hooked via a member; every other header is a plain label */
          :is(#layout-groups, #services)
            .services-group:not(:has(li[data-name="Nixbox BMC"], li[data-name="Sonarr"]))
            > button {
            pointer-events: none;
          }
          :is(#layout-groups, #services)
            .services-group:not(:has(li[data-name="Nixbox BMC"], li[data-name="Sonarr"]))
            > button
            > svg {
            display: none;
          }
          /* the collapsible panel is overflow-hidden for its height animation;
             once open that clips plates lifting on hover */
          :is(#layout-groups, #services) .services-group [data-headlessui-state="open"] {
            overflow: visible;
          }
          :is(#layout-groups, #services) .services-list {
            display: flex;
            flex-direction: row;
            flex-wrap: wrap;
            gap: 0.5rem 0.9rem;
            margin: 0 0 0.9rem;
          }
          :is(#layout-groups, #services) .service {
            flex: 0 0 auto;
          }
          :is(#layout-groups, #services) .service .service-card {
            width: 6rem;
            margin: 0;
            padding: 0.25rem 0 0;
            background: transparent;
            border: 0;
            box-shadow: none;
            backdrop-filter: none;
            -webkit-backdrop-filter: none;
            display: flex;
            overflow: visible;
          }
          :is(#layout-groups, #services) .service .service-card:hover {
            background: transparent;
            transform: none;
          }
          :is(#layout-groups, #services) .service .service-title {
            flex-direction: column;
            align-items: center;
            width: 100%;
          }
          :is(#layout-groups, #services) .service .service-icon {
            width: 4.5rem;
            height: 4.5rem;
            border-radius: 14px;
            background: var(--glass-bg);
            border: 1px solid var(--glass-border);
            backdrop-filter: blur(12px) saturate(150%);
            -webkit-backdrop-filter: blur(12px) saturate(150%);
            box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.10);
            transition:
              transform 420ms cubic-bezier(0.22, 1, 0.36, 1),
              border-color 320ms ease,
              background 320ms ease,
              box-shadow 420ms ease;
          }
          :is(#layout-groups, #services) .service .service-card:hover .service-icon {
            background: var(--glass-bg-hover);
            border-color: var(--glass-border-hover);
            transform: translateY(-4px) scale(1.06);
            box-shadow:
              inset 0 1px 0 rgba(255, 255, 255, 0.14),
              0 14px 28px -14px rgba(0, 0, 0, 0.55);
          }
          :is(#layout-groups, #services) .service .service-card:active .service-icon {
            transform: translateY(-1px) scale(0.97);
            transition-duration: 90ms;
          }
          :is(#layout-groups, #services) .service .service-icon > * {
            transition: transform 420ms cubic-bezier(0.22, 1, 0.36, 1);
          }
          :is(#layout-groups, #services) .service .service-card:hover .service-icon > * {
            transform: scale(1.06);
          }
          /* name follows the plate: lifts and brightens on the same curve */
          :is(#layout-groups, #services) .service .service-name {
            transition:
              transform 420ms cubic-bezier(0.22, 1, 0.36, 1),
              color 320ms ease;
          }
          :is(#layout-groups, #services) .service .service-card:hover .service-name {
            transform: translateY(-3px);
            color: #f1f5f9;
          }
          /* the icon component sets width/height inline (32px), and mdi/si
             icons are a masked div rather than an img, hence child + !important */
          :is(#layout-groups, #services) .service .service-icon > * {
            width: 3.2rem !important;
            height: 3.2rem !important;
          }
          :is(#layout-groups, #services) .service .service-title-text {
            flex: 0 0 auto;
            width: 100%;
          }
          :is(#layout-groups, #services) .service .service-name {
            text-align: center;
            padding: 0.45rem 0 0;
            font-size: 0.78rem;
            line-height: 1.15;
            height: calc(0.45rem + 2.3em);
            display: -webkit-box;
            -webkit-line-clamp: 2;
            -webkit-box-orient: vertical;
            overflow: hidden;
          }
          :is(#layout-groups, #services) .service .service-description {
            display: none;
          }
          /* dot mode wraps the 12px dot in p-4; strip it and place the dot inside
             the plate's top-right corner (4.5rem plate centered in the 6rem card:
             0.75rem inset from the card edge, 0.25rem card top padding) */
          :is(#layout-groups, #services) .service .service-tags {
            top: 0.6rem;
            right: 1.1rem;
            margin: 0;
          }
          :is(#layout-groups, #services) .service .service-tag > div {
            padding: 0;
          }
          :is(#layout-groups, #services) .service .service-tag .rounded-full {
            width: 0.5rem;
            height: 0.5rem;
          }

          /* widget values as plate badges: gatus renders one .service-block per
             field in fields order (up, down). pin them to the plate's left
             corners, drop the labels; the highlight level from the widget
             config colors "down". plate: 4.5rem tall, 0.25rem card top
             padding, 0.75rem in from the card's left edge */
          :is(#layout-groups, #services) .service .service-container {
            position: absolute;
            inset: 0;
            pointer-events: none;
            z-index: 11;
          }
          :is(#layout-groups, #services) .service .service-container > .absolute {
            display: none;
          }
          :is(#layout-groups, #services) .service .service-block {
            position: absolute;
            left: 1.05rem;
            margin: 0;
            padding: 0 0.3rem;
            min-width: 1.05rem;
            height: 1.05rem;
            border-radius: 999px;
            font-size: 0.62rem;
            line-height: 1.05rem;
            color: #f1f5f9;
            background: rgba(100, 116, 139, 0.75);
            box-shadow: 0 0 0 2px rgba(9, 28, 32, 0.9);
          }
          :is(#layout-groups, #services) .service .service-block:nth-child(1) {
            top: 0.55rem;
            background: rgba(16, 185, 129, 0.85);
          }
          :is(#layout-groups, #services) .service .service-block:nth-child(2) {
            top: 3.4rem;
          }
          :is(#layout-groups, #services) .service .service-block[data-highlight-level="danger"] {
            background: rgba(244, 63, 94, 0.9);
          }
          :is(#layout-groups, #services) .service .service-block .font-thin {
            font-weight: 600;
            font-size: inherit;
          }
          :is(#layout-groups, #services) .service .service-block .font-bold {
            display: none;
          }

          /* bookmarks sit at the page bottom when the tab leaves room. #footer
             already carries mt-auto; two auto margins split the free space,
             so the footer's has to go */
          #bookmarks {
            margin-top: auto;
            padding-top: 1rem;
          }
          #footer {
            margin-top: 0;
            padding-top: 0;
          }

          /* tab bar as a glass pill switch */
          #myTab {
            display: inline-flex;
            border-radius: 999px;
            border: 1px solid var(--glass-border);
            background: var(--glass-bg);
            backdrop-filter: blur(10px);
            -webkit-backdrop-filter: blur(10px);
            padding: 0.2rem;
          }
          #myTab li {
            height: auto;
            width: auto;
          }
          #myTab button {
            border-radius: 999px;
            margin: 0;
            padding: 0.35rem 1.1rem;
            font-size: 0.8rem;
            letter-spacing: 0.06em;
            text-transform: uppercase;
          }
          #myTab button[aria-selected="true"] {
            background: rgba(255, 255, 255, 0.14);
          }

          /* group headings */
          :is(#layout-groups, #services) .service-group-name,
          :is(#layout-groups, #bookmarks) .bookmark-group-name {
            font-size: 0.78rem;
            font-weight: 600;
            letter-spacing: 0.12em;
            text-transform: uppercase;
            color: rgba(226, 232, 240, 0.65);
            margin-bottom: 0.35rem;
          }
          /* the plate is 4.5rem centred in a 6rem card, so the first icon
             starts 0.75rem in; indent the header to that edge */
          :is(#layout-groups, #services) .services-group > button {
            padding-left: 0.75rem;
          }

          /* bookmarks */
          :is(#layout-groups, #bookmarks) {
            justify-content: center;
          }
          /* hairlines: drawn as pseudo-elements 1rem wider than the content
             box on each side, so they overhang the groups and bookmarks */
          #bookmarks,
          #page_wrapper div:has(> #myTab) {
            position: relative;
            padding-top: 1rem;
          }
          #bookmarks::before,
          #page_wrapper div:has(> #myTab)::before {
            content: "";
            position: absolute;
            top: 0;
            left: -1rem;
            right: -1rem;
            border-top: 1px solid var(--glass-border);
          }
          #page_wrapper div:has(> #myTab) {
            margin: 0.25rem 2rem 0;
          }
          :is(#layout-groups, #bookmarks) .bookmark {
            border-radius: var(--glass-radius-sm);
            border: 1px solid var(--glass-border);
            background: var(--glass-bg);
            backdrop-filter: blur(10px);
            -webkit-backdrop-filter: blur(10px);
            overflow: hidden;
            margin-bottom: 0.35rem;
            transition: border-color 180ms ease, background 180ms ease, transform 180ms ease;
          }
          :is(#layout-groups, #bookmarks) .bookmark:hover {
            background: var(--glass-bg-hover);
            border-color: var(--glass-border-hover);
            transform: translateY(-1px);
          }
          :is(#layout-groups, #bookmarks) .bookmark > a {
            margin-bottom: 0;
          }
          :is(#layout-groups, #bookmarks) .bookmark-icon {
            width: 2.1rem;
            background: rgba(255, 255, 255, 0.05);
            border-radius: 0;
          }
          :is(#layout-groups, #bookmarks) .bookmark-icon > * {
            width: 1.05rem !important;
            height: 1.05rem !important;
          }
          :is(#layout-groups, #bookmarks) .bookmark-name {
            padding: 0.45rem 0 0.45rem 0.6rem;
            font-size: 0.75rem;
            color: rgba(226, 232, 240, 0.62);
            transition: color 200ms ease;
          }
          :is(#layout-groups, #bookmarks) .bookmark:hover .bookmark-name {
            color: #f1f5f9;
          }
          :is(#layout-groups, #bookmarks) .bookmark-description {
            display: none;
          }

          /* header widgets: search centered at half width, clock pinned right */
          #information-widgets-right {
            position: relative;
            justify-content: center;
          }
          #page_wrapper .information-widget-search {
            flex: 0 1 50%;
            max-width: 50%;
          }

          #page_wrapper .information-widget-form input {
            border-radius: 999px;
            border: 1px solid var(--glass-border);
            background: var(--glass-bg);
            backdrop-filter: blur(10px);
            -webkit-backdrop-filter: blur(10px);
            padding-left: 1.1rem;
          }
          #page_wrapper .information-widget-form input:focus {
            border-color: var(--glass-border-hover);
            box-shadow: 0 0 0 4px rgba(20, 184, 166, 0.28);
          }
          #page_wrapper .information-widget-form button {
            border-radius: 999px;
            right: 4px;
            background: rgba(255, 255, 255, 0.10);
          }
          #page_wrapper .widget-container {
            border-radius: 999px;
            border: 1px solid var(--glass-border);
            background: var(--glass-bg);
            backdrop-filter: blur(10px);
            -webkit-backdrop-filter: blur(10px);
            padding: 0.15rem 0.9rem;
          }
          /* clock: match the 2rem search input instead of the widget's own
             text-lg line box plus padding */
          #page_wrapper .information-widget-datetime {
            position: absolute;
            right: 0;
            top: 50%;
            transform: translateY(-50%);
            height: 2.4rem;
            padding: 0 0.9rem;
            justify-content: center;
          }
          #page_wrapper .information-widget-datetime span {
            font-size: 1.05rem;
            line-height: 1;
          }
          #page_wrapper .widget-container:has(.information-widget-form) {
            border: 0;
            background: transparent;
            backdrop-filter: none;
            -webkit-backdrop-filter: none;
            padding: 0;
          }
        '';
      };
    };
}
