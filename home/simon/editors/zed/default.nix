{
  mylib,
  pkgs,
  ...
}:
{
  imports = mylib.scanPaths ./. { };

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
}
