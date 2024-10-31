{
  lib,
  config,
  pkgs,
  inputs,
  ...
}:
with lib;

let
  cfg = config.module.desktop.wayland.applauncher;
in
{
  imports = [
    inputs.anyrun.homeManagerModules.default
  ];
  config = mkIf (cfg == "anyrun") {
    programs.anyrun = {
      enable = true;

      config = {
        plugins = with inputs.anyrun.packages.${pkgs.system}; [
          applications
          rink
          shell
          symbols
          websearch

          #inputs.anyrun-nixos-options.packages.${pkgs.system}.default
        ];

        width.fraction = 0.18;
        y.fraction = 0.25;
        x.fraction = 0.5;
        hidePluginInfo = true;
        closeOnClick = true;
        hideIcons = false;
      };

      extraCss = builtins.readFile (./. + "/style.css");

      extraConfigFiles = {
        "applications.ron".text = ''
          Config(
            desktop_actions: false,
            max_entries: 5,
            terminal: Some("wezterm"),
          )
        '';

        "shell.ron".text = ''
          Config(
            prefix: ":sh"
          )
        '';

        "symbols.ron".text = ''
          Config(
            prefix: ":icon",
            max_entries: 3,
          )
        '';

        "websearch.ron".text = ''
          Config(
            prefix: "?",
            engines: [DuckDuckGo]
          )
        '';

        #"nixos-options.ron".text =
        #  let
        #    nixos-options = osConfig.system.build.manual.optionsJSON + "/share/doc/nixos/options.json";
        #    hm-options =
        #      inputs.home-manager.packages.${pkgs.system}.docs-json + "/share/doc/home-manager/options.json";
        #    options = builtins.toJSON {
        #      ":nix" = [ nixos-options ];
        #      ":hm" = [ hm-options ];
        #    };
        #  in
        #  ''
        #    Config(
        #      options: ${options},
        #      min_score: 5,
        #      max_entries: Some(3),
        #    )
        #  '';
      };
    };
  };
}
