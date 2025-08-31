{
  lib,
  config,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.module.editors.zed-editor;
in
{
  imports = [
    ./settings.nix
  ];

  options = {
    module.editors.zed-editor.enable = mkEnableOption "Enables zed-editor";
  };

  config = mkIf cfg.enable {

    programs.zed-editor = {
      enable = true;
      #package = pkgs.zed-editor_git;
      installRemoteServer = true;
      extraPackages = with pkgs; [
        ansible-language-server
        nil
        nixd
        nixfmt-rfc-style
        package-version-server
        shellcheck
        shfmt
        jsonnet-language-server
        yaml-language-server
        go
        gopls
        terraform-ls
        helm-ls
        taplo
      ];
    };
  };
}
