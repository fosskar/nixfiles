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
          provider = "custom";
          url = "https://search.${flake-self.domains.local}/search?q=";
          # phones have no keyboard to start quicklaunch by typing
          mobileButtonPosition = "bottom-right";
        };

        # sections come from the apply in homepage.nix; bookmark groups take
        # a tab the same way
        settings.layout = [
          # two groups per row: apps | tools, management | monitoring
          { apps.tab = "Apps"; }
          { tools.tab = "Apps"; }
          { management.tab = "Apps"; }
          { monitoring.tab = "Apps"; }
          { admin.tab = "Admin"; }
          { "arr-stack".tab = "Admin"; }
          # the beszel module's machine tiles; machines.nix renders the tab over them
          {
            machines = {
              tab = "Machines";
              style = "row";
              header = false;
            };
          }
          { "NixOS".tab = "Bookmarks"; }
          { "Home Manager".tab = "Bookmarks"; }
          { "Clan".tab = "Bookmarks"; }
          { "Code".tab = "Bookmarks"; }
          { "Community".tab = "Bookmarks"; }
          { "DNS Management".tab = "Bookmarks"; }
          { "Hosting".tab = "Bookmarks"; }
        ];

        # tiles the cross-host collector can't provide: external non-NixOS devices and local-only endpoints
        services = [
          {
            "network" = [
              {
                "OpenWrt Router" = {
                  href = "https://${flake-self.router.lan}";
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
                  href = "http://${flake-self.router.lan}:8080";
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
            ];
          }
          {
            "tools" = [
              {
                "HP Printer" = {
                  href = "http://192.168.10.153";
                  icon = "hp.svg";
                };
              }
            ];
          }
          {
            "apps" = [
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
              {
                "Clan Forge" = [
                  {
                    icon = "gitea.svg";
                    href = "https://git.clan.lol";
                  }
                ];
              }
            ];
          }
          {
            "Code" = [
              {
                "GitHub" = [
                  {
                    icon = "github.svg";
                    href = "https://github.com";
                  }
                ];
              }
              {
                "Tangled" = [
                  {
                    icon = "mdi-source-branch";
                    href = "https://tangled.org";
                  }
                ];
              }
              {
                "geninf" = [
                  {
                    icon = "gitea.svg";
                    href = "https://git.geninf.io";
                  }
                ];
              }
            ];
          }
          {
            "Community" = [
              {
                "personal.computer" = [
                  {
                    icon = "discourse.svg";
                    href = "https://personal.computer/";
                  }
                ];
              }
              {
                "Radicle Zulip" = [
                  {
                    icon = "zulip.svg";
                    href = "https://radicle.zulipchat.com/";
                  }
                ];
              }
            ];
          }
          {
            "Hosting" = [
              {
                "Hetzner" = [
                  {
                    icon = "hetzner.svg";
                    href = "https://accounts.hetzner.com";
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
              url = "https://search.${flake-self.domains.local}/search?q=";
              target = "_blank";
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
        # accent switcher: the nixlens accents (nixlens web/src/lib/prefs.ts),
        # stored per browser, behind homepage's palette icon (IoColorPalette)
        # at the end of the tab row
        customJS = ''
          (() => {
            const ACCENTS = {
              teal: ["#16a085", "#1abc9c"],
              blue: ["#3b6fd4", "#6796e6"],
              amber: ["#b7862a", "#c79a3a"],
              violet: ["#8e5bb5", "#c586c0"],
            };
            const KEY = "homepage.accent";
            let current = localStorage.getItem(KEY);
            if (!(current in ACCENTS)) current = "teal";
            const apply = () => {
              const [a, b] = ACCENTS[current];
              document.documentElement.style.setProperty("--accent", a);
              document.documentElement.style.setProperty("--accent-2", b);
            };
            apply();
            const mount = () => {
              // the search widget has no placeholder option; homepage's i18n says "Search…"
              const search = document.querySelector(".information-widget-search input");
              if (search && search.placeholder !== "Web search…") {
                search.placeholder = "Web search…";
                search.setAttribute("aria-label", "Web search");
              }
              const tabs = document.getElementById("tabs");
              if (!tabs || tabs.querySelector(".accent-menu")) return;
              const menu = document.createElement("div");
              menu.className = "accent-menu";
              const toggle = document.createElement("button");
              toggle.type = "button";
              toggle.className = "accent-toggle";
              toggle.setAttribute("aria-label", "accent colour");
              toggle.setAttribute("aria-expanded", "false");
              toggle.innerHTML = '<svg viewBox="0 0 512 512" aria-hidden="true"><path fill="currentColor" d="m441 336.2-.06-.05c-9.93-9.18-22.78-11.34-32.16-12.92l-.69-.12c-9.05-1.49-10.48-2.5-14.58-6.17-2.44-2.17-5.35-5.65-5.35-9.94s2.91-7.77 5.34-9.94l30.28-26.87c25.92-22.91 40.2-53.66 40.2-86.59s-14.25-63.68-40.2-86.6c-35.89-31.59-85-49-138.37-49C223.72 48 162 71.37 116 112.11c-43.87 38.77-68 90.71-68 146.24s24.16 107.47 68 146.23c21.75 19.24 47.49 34.18 76.52 44.42a266.2 266.2 0 0 0 86.87 15h1.81c61 0 119.09-20.57 159.39-56.4 9.7-8.56 15.15-20.83 15.34-34.56.21-14.17-5.37-27.95-14.93-36.84M112 208a32 32 0 1 1 32 32 32 32 0 0 1-32-32m40 135a32 32 0 1 1 32-32 32 32 0 0 1-32 32m40-199a32 32 0 1 1 32 32 32 32 0 0 1-32-32m64 271a48 48 0 1 1 48-48 48 48 0 0 1-48 48m72-239a32 32 0 1 1 32-32 32 32 0 0 1-32 32"/></svg>';
              const box = document.createElement("div");
              box.className = "accent-switch";
              box.setAttribute("role", "radiogroup");
              box.setAttribute("aria-label", "accent colour");
              const setOpen = (open) => toggle.setAttribute("aria-expanded", String(open));
              toggle.addEventListener("click", () =>
                setOpen(toggle.getAttribute("aria-expanded") !== "true"));
              document.addEventListener("click", (event) => {
                if (!menu.contains(event.target)) setOpen(false);
              });
              document.addEventListener("keydown", (event) => {
                if (event.key === "Escape") setOpen(false);
              });
              for (const [name, [a, b]] of Object.entries(ACCENTS)) {
                const button = document.createElement("button");
                button.type = "button";
                button.title = name;
                button.setAttribute("role", "radio");
                button.setAttribute("aria-label", name);
                button.setAttribute("aria-checked", String(name === current));
                button.style.setProperty("--a", a);
                button.style.setProperty("--b", b);
                button.addEventListener("click", () => {
                  current = name;
                  localStorage.setItem(KEY, name);
                  apply();
                  for (const other of box.children)
                    other.setAttribute("aria-checked", String(other.title === name));
                });
                box.append(button);
              }
              menu.append(toggle, box);
              tabs.append(menu);
            };
            new MutationObserver(mount).observe(document.body, { childList: true, subtree: true });
            mount();
          })();
        '';

        customCSS = ''
          :root {
            --glass-bg: rgba(255, 255, 255, 0.055);
            --glass-bg-hover: rgba(255, 255, 255, 0.10);
            --glass-border: rgba(255, 255, 255, 0.10);
            --glass-border-hover: rgba(255, 255, 255, 0.24);
            --glass-radius: 18px;
            --glass-radius-sm: 12px;
            /* the accent switcher (customJS below) overrides these per browser */
            --accent: #16a085;
            --accent-2: #1abc9c;
          }

          /* the theme's sans on machines that have it; phones fall back to
             their platform font (Roboto / SF), which is the same modern look */
          body,
          #page_wrapper {
            font-family: "${sansFont}", system-ui, -apple-system, "Segoe UI", Roboto, sans-serif;
          }

          #page_wrapper {
            background:
              radial-gradient(1200px 600px at 8% -10%, color-mix(in srgb, var(--accent) 30%, transparent), transparent 60%),
              radial-gradient(900px 500px at 100% 10%, color-mix(in srgb, var(--accent-2) 22%, transparent), transparent 60%),
              radial-gradient(800px 500px at 50% 110%, color-mix(in srgb, var(--accent) 20%, transparent), transparent 60%),
              linear-gradient(180deg, color-mix(in srgb, var(--accent) 6%, #04090b) 0%, color-mix(in srgb, var(--accent) 8%, #081013) 100%);
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
            background: var(--accent);
          }
          #page_wrapper::after {
            right: -20vw;
            bottom: -25vw;
            background: var(--accent-2);
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
          /* plates: a darker solid tile under each logo. hovering tiles is a
             tens-a-day interaction, so it stays small and fast (2px, 160ms,
             strong ease-out) and only applies where a pointer can hover */
          :is(#layout-groups, #services) .service .service-icon {
            width: 4.5rem;
            height: 4.5rem;
            border-radius: 14px;
            background: linear-gradient(180deg, color-mix(in srgb, var(--accent) 12%, rgba(10, 26, 29, 0.8)), color-mix(in srgb, var(--accent) 6%, rgba(5, 14, 16, 0.8)));
            border: 1px solid rgba(255, 255, 255, 0.08);
            backdrop-filter: blur(12px) saturate(150%);
            -webkit-backdrop-filter: blur(12px) saturate(150%);
            box-shadow:
              inset 0 1px 0 rgba(255, 255, 255, 0.08),
              0 1px 2px rgba(0, 0, 0, 0.25);
            transition:
              transform 160ms cubic-bezier(0.23, 1, 0.32, 1),
              border-color 150ms ease;
          }
          /* dark logos (vaultwarden, miniflux) keep an edge on the dark plate */
          :is(#layout-groups, #services) .service .service-icon > * {
            filter: drop-shadow(0 0 1px rgba(255, 255, 255, 0.28));
          }
          :is(#layout-groups, #services) .service .service-name {
            transition: color 150ms ease;
          }
          @media (hover: hover) and (pointer: fine) {
            :is(#layout-groups, #services) .service .service-card:hover .service-icon {
              border-color: rgba(255, 255, 255, 0.2);
              transform: translateY(-2px);
            }
            :is(#layout-groups, #services) .service .service-card:hover .service-name {
              color: #f1f5f9;
            }
          }
          :is(#layout-groups, #services) .service .service-card:active .service-icon {
            transform: scale(0.97);
            transition-duration: 100ms;
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
            font-size: 0.85rem;
            font-weight: 500;
          }
          #myTab button[aria-selected="true"] {
            background: rgba(255, 255, 255, 0.14);
          }

          /* group headings */
          :is(#layout-groups, #services) .service-group-name,
          :is(#layout-groups, #bookmarks) .bookmark-group-name {
            font-size: 0.85rem;
            font-weight: 600;
            color: rgba(226, 232, 240, 0.65);
            margin-bottom: 0.35rem;
          }
          /* group keys are lowercase (apps, arr-stack); ::first-letter needs
             a block box, the heading ships as flex */
          :is(#layout-groups, #services) .service-group-name,
          :is(#layout-groups, #bookmarks) .bookmark-group-name {
            display: block;
          }
          :is(#layout-groups, #services) .service-group-name::first-letter,
          :is(#layout-groups, #bookmarks) .bookmark-group-name::first-letter {
            text-transform: uppercase;
          }
          /* the plate is 4.5rem centred in a 6rem card, so the first icon
             starts 0.75rem in; indent the header to that edge plus the 0.25rem
             card padding */
          :is(#layout-groups, #services) .services-group > button {
            padding-left: 1rem;
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
            transition: border-color 150ms ease, background-color 150ms ease;
          }
          @media (hover: hover) and (pointer: fine) {
            :is(#layout-groups, #bookmarks) .bookmark:hover {
              background: var(--glass-bg-hover);
              border-color: var(--glass-border-hover);
            }
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
            flex: 0 1 56%;
            max-width: 56%;
          }
          /* the widget hardcodes h-8 on the box around the input */
          #page_wrapper .information-widget-search .h-8 {
            height: 2.75rem;
          }

          #page_wrapper .information-widget-form input {
            border-radius: 999px;
            border: 1px solid var(--glass-border);
            background: var(--glass-bg);
            backdrop-filter: blur(10px);
            -webkit-backdrop-filter: blur(10px);
            padding-left: 1.25rem;
            font-size: 0.95rem;
          }
          #page_wrapper .information-widget-form input:focus {
            border-color: var(--glass-border-hover);
            box-shadow: 0 0 0 4px color-mix(in srgb, var(--accent) 28%, transparent);
          }
          #page_wrapper .information-widget-form button {
            border-radius: 999px;
            right: 4px;
            bottom: 4px;
            height: calc(2.75rem - 8px);
            display: flex;
            align-items: center;
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
          /* clock: match the 2.75rem search input instead of the widget's own
             text-lg line box plus padding */
          #page_wrapper .information-widget-datetime {
            position: absolute;
            right: 0;
            top: 50%;
            transform: translateY(-50%);
            height: 2.75rem;
            padding: 0 1rem;
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

          /* bookmark groups: homepage gives them a sixth of the row from xl, so
             a seventh group wrapped alone; a quarter that grows fills the rows */
          @media (min-width: 768px) {
            #layout-groups > .bookmark-group {
              flex: 1 1 25%;
            }
          }

          /* footer: homepage's revalidate button rebuilds from the config files,
             which nix deploys restart homepage for; the accent switcher sits in
             the tab row */
          #style {
            display: none;
          }
          #tabs {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 0.75rem;
          }
          #tabs .accent-menu {
            position: relative;
          }
          #tabs .accent-toggle {
            display: grid;
            place-items: center;
            width: 2.5rem;
            height: 2.5rem;
            border-radius: 999px;
            border: 1px solid var(--glass-border);
            background: var(--glass-bg);
            backdrop-filter: blur(10px);
            -webkit-backdrop-filter: blur(10px);
            color: rgba(226, 232, 240, 0.75);
            cursor: pointer;
            transition:
              transform 160ms cubic-bezier(0.23, 1, 0.32, 1),
              border-color 150ms ease,
              color 150ms ease;
          }
          #tabs .accent-toggle svg {
            width: 1.15rem;
            height: 1.15rem;
          }
          @media (hover: hover) and (pointer: fine) {
            #tabs .accent-toggle:hover {
              border-color: var(--glass-border-hover);
              color: #f1f5f9;
            }
          }
          #tabs .accent-toggle[aria-expanded="true"] {
            border-color: var(--glass-border-hover);
            color: #f1f5f9;
          }
          #tabs .accent-toggle:active {
            transform: scale(0.97);
          }
          #tabs .accent-toggle:focus-visible {
            outline: 2px solid rgba(255, 255, 255, 0.6);
            outline-offset: 3px;
          }
          #tabs .accent-switch {
            position: absolute;
            z-index: 30;
            top: calc(100% + 0.5rem);
            right: 0;
            display: flex;
            gap: 10px;
            padding: 9px 11px;
            border-radius: 999px;
            border: 1px solid var(--glass-border);
            background: color-mix(in srgb, var(--accent) 10%, rgba(6, 16, 18, 0.85));
            backdrop-filter: blur(16px);
            -webkit-backdrop-filter: blur(16px);
            box-shadow: 0 16px 40px -16px rgba(0, 0, 0, 0.7);
            transform-origin: top right;
            opacity: 0;
            transform: scale(0.96) translateY(-4px);
            visibility: hidden;
            transition:
              opacity 150ms ease-out,
              transform 180ms cubic-bezier(0.23, 1, 0.32, 1),
              visibility 0s linear 180ms;
          }
          #tabs .accent-toggle[aria-expanded="true"] + .accent-switch {
            opacity: 1;
            transform: none;
            visibility: visible;
            transition:
              opacity 150ms ease-out,
              transform 180ms cubic-bezier(0.23, 1, 0.32, 1);
          }
          #tabs .accent-switch button {
            width: 18px;
            height: 18px;
            padding: 0;
            border: 0;
            border-radius: 50%;
            background: linear-gradient(135deg, var(--a), var(--b));
            cursor: pointer;
            transition: transform 160ms cubic-bezier(0.23, 1, 0.32, 1);
          }
          #tabs .accent-switch button[aria-checked="true"] {
            box-shadow:
              0 0 0 2px rgba(6, 16, 18, 0.9),
              0 0 0 3.5px rgba(255, 255, 255, 0.75);
          }
          #tabs .accent-switch button:active {
            transform: scale(0.9);
          }
          #tabs .accent-switch button:focus-visible {
            outline: 2px solid rgba(255, 255, 255, 0.6);
            outline-offset: 3px;
          }

          /* desktop: more air between header, hairline, tabs and content;
             phones stay dense */
          @media (min-width: 1024px) {
            #information-widgets {
              margin-top: 4rem;
            }
            #page_wrapper div#tabs {
              margin-top: 2.25rem;
              padding-top: 2.25rem;
            }
            #layout-groups {
              margin-top: 2.25rem;
            }
          }

          /* phones: the absolutely placed clock would overlap the search bar,
             and the phone shows the time itself */
          @media (max-width: 640px) {
            #page_wrapper .information-widget-datetime {
              display: none;
            }
            #page_wrapper .information-widget-search {
              flex-basis: 100%;
              max-width: 100%;
            }
            /* four tabs and the palette button share the search bar's width */
            #page_wrapper div#tabs {
              margin-left: 1.25rem;
              margin-right: 1.25rem;
              gap: 0.5rem;
            }
            #myTab button {
              padding: 0.35rem 0.65rem;
              font-size: 0.8rem;
            }
            #tabs .accent-toggle {
              width: 2.25rem;
              height: 2.25rem;
            }
          }

          /* quicklaunch: the overlay homepage opens on typing. its markup has no
             ids, so it is matched by role and element; tailwind sits in a
             layer, so these plain rules win without !important */
          div[role="dialog"][aria-modal="true"] > .fixed.inset-0:first-child {
            background: rgba(3, 12, 14, 0.55);
            opacity: 1;
            backdrop-filter: blur(6px);
            -webkit-backdrop-filter: blur(6px);
          }
          div[role="dialog"][aria-modal="true"] dialog {
            overflow: hidden;
            border-radius: var(--glass-radius);
            border: 1px solid var(--glass-border);
            background: color-mix(in srgb, var(--accent) 10%, rgba(6, 16, 18, 0.8));
            backdrop-filter: blur(20px) saturate(150%);
            -webkit-backdrop-filter: blur(20px) saturate(150%);
            box-shadow:
              inset 0 1px 0 rgba(255, 255, 255, 0.08),
              0 24px 60px -20px rgba(0, 0, 0, 0.7);
            color: #e2e8f0;
          }
          div[role="dialog"][aria-modal="true"] dialog input {
            background: transparent;
            border-color: var(--glass-border);
            color: #f1f5f9;
          }
          div[role="dialog"][aria-modal="true"] dialog input::placeholder {
            color: rgba(226, 232, 240, 0.45);
          }
          div[role="dialog"][aria-modal="true"] dialog li > button {
            border-radius: var(--glass-radius-sm);
            color: #e2e8f0;
          }
          /* the highlighted result: keyboard selection and pointer hover share it */
          div[role="dialog"][aria-modal="true"] dialog li > button[class*="bg-theme-700"] {
            background: rgba(255, 255, 255, 0.08);
            box-shadow: inset 0 0 0 1px var(--glass-border);
          }
          /* descriptions are search keywords, matched but not shown */
          div[role="dialog"][aria-modal="true"] dialog li > button span.text-xs {
            display: none;
          }
          /* the mobile quicklaunch button (mobileButtonPosition) */
          button.fixed.rounded-full.sm\:hidden {
            padding: 0.85rem;
            border: 1px solid var(--glass-border);
            background: color-mix(in srgb, var(--accent) 10%, rgba(6, 16, 18, 0.8));
            backdrop-filter: blur(16px) saturate(150%);
            -webkit-backdrop-filter: blur(16px) saturate(150%);
            box-shadow: 0 10px 30px -10px rgba(0, 0, 0, 0.6);
            color: #e2e8f0;
          }
          div[role="dialog"][aria-modal="true"] dialog li > button .font-bold {
            font-weight: 500;
            color: rgba(226, 232, 240, 0.45);
          }

          @media (prefers-reduced-motion: reduce) {
            #page_wrapper::before,
            #page_wrapper::after {
              animation: none;
            }
            :is(#layout-groups, #services) .service .service-card:hover .service-icon,
            :is(#layout-groups, #services) .service .service-card:active .service-icon {
              transform: none;
            }
            #tabs .accent-switch {
              transform: none;
            }
          }
        '';
      };
    };
}
