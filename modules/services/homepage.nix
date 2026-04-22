{
  flake.modules.nixos.homepage =
    { config, lib, ... }:
    let
      cfg = config.nixfiles.homepage;

      entryModule = lib.types.submodule {
        options = {
          name = lib.mkOption {
            type = lib.types.str;
            description = "display name for the service";
          };
          category = lib.mkOption {
            type = lib.types.str;
            description = "dashboard category";
          };
          icon = lib.mkOption {
            type = lib.types.str;
            description = "icon name or URL";
          };
          href = lib.mkOption {
            type = lib.types.str;
            description = "public URL for the service";
          };
          siteMonitor = lib.mkOption {
            type = lib.types.str;
            description = "internal URL for health monitoring";
          };
          description = lib.mkOption {
            type = lib.types.str;
            default = "";
            description = "optional description";
          };
        };
      };

      groupedEntries = lib.foldl' (
        acc: entry:
        acc
        // {
          ${entry.category} = (acc.${entry.category} or [ ]) ++ [
            {
              ${entry.name} = {
                inherit (entry) href icon siteMonitor;
              }
              // lib.optionalAttrs (entry.description != "") { inherit (entry) description; };
            }
          ];
        }
      ) { } cfg.entries;

      manualGrouped = lib.foldl' (
        acc: item:
        lib.foldl' (
          acc2: category: acc2 // { ${category} = (acc2.${category} or [ ]) ++ item.${category}; }
        ) acc (lib.attrNames item)
      ) { } cfg.manualServices;

      mergedGroups = lib.foldl' (
        acc: category: acc // { ${category} = (acc.${category} or [ ]) ++ manualGrouped.${category}; }
      ) groupedEntries (lib.attrNames manualGrouped);

      allServices = lib.mapAttrsToList (category: entries: { ${category} = entries; }) mergedGroups;
    in
    {
      options.nixfiles.homepage = {
        entries = lib.mkOption {
          type = lib.types.listOf entryModule;
          default = [ ];
          description = "auto-registered homepage dashboard entries from service modules";
        };

        manualServices = lib.mkOption {
          type = lib.types.listOf lib.types.attrs;
          default = [ ];
          description = "manually defined homepage services";
        };

        layout = lib.mkOption {
          type = lib.types.listOf lib.types.attrs;
          default = [ ];
          description = "homepage dashboard layout configuration";
        };

        bookmarks = lib.mkOption {
          type = lib.types.listOf lib.types.attrs;
          default = [ ];
          description = "homepage dashboard bookmarks";
        };

        widgets = lib.mkOption {
          type = lib.types.listOf lib.types.attrs;
          default = [ ];
          description = "homepage dashboard widgets";
        };

        customCSS = lib.mkOption {
          type = lib.types.lines;
          default = "";
          description = "custom CSS for homepage dashboard";
        };
      };

      config = {
        services.homepage-dashboard = {
          enable = true;
          listenPort = 8082;
          openFirewall = false;
          allowedHosts = "home.${config.nixfiles.caddy.domain}";

          settings = {
            title = "home-lab dashboard";
            headerStyle = "underlined";
            useEqualheights = true;
            hideVersion = true;
            disableUpdateCheck = true;
            disableIndexing = true;
            statusStyle = "dot";
            cardBlur = "xl";
            inherit (cfg) layout;
          };

          services = allServices;
          inherit (cfg) bookmarks widgets;
          inherit (cfg) customCSS;
          customJS = "";
        };

        nixfiles.caddy.vhosts.home.port = config.services.homepage-dashboard.listenPort;
      };
    };
}
