{
  config,
  pkgs,
  mylib,
  ...
}:
let
  email = "214-simon.siedl@users.noreply.gitlab.mecom.de";
  name = "Simon Siedl";
in
{

  imports = mylib.scanPaths ./. { };

  programs.git = {
    enable = true;
    package = pkgs.git;
    lfs.enable = true;

    settings = {
      user.email = email;
      #user.email = config.sops.templates."workmail".content;
      user.name = name;

      color.ui = true;
      core.editor = "nvim";
      push.autoSetupRemote = true;
      diff.colorMoved = "default";
      gpg = {
        ssh.allowedSignersFile = "${config.xdg.configHome}/git/allowed_signers";
      };
      pull.rebase = true;
      init.defaultBranch = "main";
      auto.fetch = true;
      #core.sshCommand = "ssh -i ${config.home.homeDirectory}/.ssh/id_rsa";
    };

    signing = {
      key = "${config.home.homeDirectory}/.ssh/id_rsa";
      format = "ssh";
      signByDefault = true;
    };
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options.dark = true;
  };
}
