{ inputs, ... }:
{
  flake.modules.homeManager.noctalia-v5 =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.programs.noctalia-v5;
      toml = pkgs.formats.toml { };
    in
    {
      options.programs.noctalia-v5 = {
        enable = lib.mkEnableOption "Noctalia v5";

        package = lib.mkOption {
          type = lib.types.package;
          default = inputs.noctalia-v5.packages.${pkgs.stdenv.hostPlatform.system}.default;
          defaultText = lib.literalExpression "inputs.noctalia-v5.packages.${pkgs.stdenv.hostPlatform.system}.default";
          description = "Noctalia v5 package.";
        };

        settings = lib.mkOption {
          inherit (toml) type;
          default = { };
          description = "Noctalia v5 TOML settings written to ~/.config/noctalia/config.toml.";
        };
      };

      config = lib.mkIf cfg.enable {
        xdg.configFile."noctalia/00-nix.toml".source = toml.generate "noctalia-v5-config.toml" cfg.settings;

        systemd.user.services.noctalia-v5 = {
          Unit = {
            Description = "Noctalia v5 Wayland shell";
            Documentation = "https://docs.noctalia.dev/v5/";
            PartOf = [ config.wayland.systemd.target ];
            After = [ config.wayland.systemd.target ];
            X-Restart-Triggers = [ config.xdg.configFile."noctalia/00-nix.toml".source ];
          };
          Service = {
            ExecStart = lib.getExe cfg.package;
            Restart = "on-failure";
          };
          Install.WantedBy = [ config.wayland.systemd.target ];
        };
      };
    };
}
