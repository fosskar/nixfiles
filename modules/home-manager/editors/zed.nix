{
  flake.modules.homeManager.zed =
    { pkgs, ... }:
    {
      programs.zed-editor = {
        enable = true;
        #package = inputs.zed.packages.${pkgs.stdenv.hostPlatform.system}.default;
        installRemoteServer = true;
        extraPackages = [
          pkgs.nil
          pkgs.nixd
          pkgs.nixfmt
        ];
        extensions = [
          "basher"
          "log"
          "material-icon-theme"
          "nix"
          "toml"
          "vscode-dark-modern"
        ];

        userSettings = {
          theme = "VSCode Dark Modern";
          icon_theme = "Material Icon Theme";
        };
      };
      wayland.windowManager.niri.settings.binds."Mod+Z".spawn = "zeditor";
    };
}
