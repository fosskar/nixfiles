_: {
  flake.modules.homeManager.web-apps =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.programs.web-apps;
    in
    {
      options.programs.web-apps.apps = lib.mkOption {
        type = lib.types.attrsOf (
          lib.types.submodule (
            { name, ... }:
            {
              options = {
                name = lib.mkOption {
                  type = lib.types.str;
                  default = name;
                  description = "display name of the desktop entry";
                };
                url = lib.mkOption {
                  type = lib.types.str;
                  description = "url opened as a dedicated browser app window";
                };
                icon = lib.mkOption {
                  type = lib.types.nullOr (lib.types.either lib.types.path lib.types.str);
                  default = null;
                  description = "icon file or theme icon name";
                };
                categories = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  default = [ "Network" ];
                  description = "desktop entry categories";
                };
              };
            }
          )
        );
        default = { };
        example = lib.literalExpression ''
          {
            netflix = {
              name = "Netflix";
              url = "https://www.netflix.com";
              icon = pkgs.fetchurl {
                url = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/netflix.png";
                hash = lib.fakeHash;
              };
            };
          }
        '';
        description = "web apps installed as desktop entries running in brave app windows";
      };

      config.xdg.desktopEntries = lib.mapAttrs (
        _: app:
        {
          inherit (app) name categories;
          exec = "${lib.getExe pkgs.brave-origin} --app=${app.url}";
          terminal = false;
        }
        // lib.optionalAttrs (app.icon != null) { inherit (app) icon; }
      ) cfg.apps;
    };
}
