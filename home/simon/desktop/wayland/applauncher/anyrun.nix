{
  pkgs,
  inputs,
  ...
}:
{
  programs.anyrun = {
    enable = true;

    config = {
      plugins = with inputs.anyrun.packages.${pkgs.system}; [
        applications
        rink
        shell
        #symbols
        websearch
      ];

      width.fraction = 0.18;
      y.fraction = 0.25;
      x.fraction = 0.5;
      hidePluginInfo = true;
      closeOnClick = true;
      hideIcons = false;
    };

    #extraCss = builtins.readFile (./. + "/style.css");
    extraCss = ''
      * {
        all: unset;
        font-size: 1.2rem;
        font-family: Inter;
      }

      #window,
      #match,
      #entry,
      #plugin,
      #main {
        background: transparent;
      }

      #match.activatable {
        border-radius: 6px;
        margin: 4px 0;
        padding: 4px;
      }
      #match.activatable:first-child {
        margin-top: 12px;
      }
      #match.activatable:last-child {
        margin-bottom: 0;
      }

      #match:hover {
        background: #282828;
      }
      #match:selected {
        background: #33d17a;
      }

      #entry {
        background: #1e1e1e;
        color: #eeeeee;
        border: 1px solid #33d17a;
        border-radius: 6px;
        padding: 4px 8px;
      }

      box#main {
        background: #171717;
        border-radius: 6px;
        padding: 12px;
      }
    '';

    extraConfigFiles = {
      "applications.ron".text = ''
        Config(
          desktop_actions: false,
          max_entries: 5,
          terminal: Some("ghostty"),
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
          engines: [StartPage]
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
}
