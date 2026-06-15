{
  config,
  lib,
  inputs,
  ...
}:
let
  projects = lib.removePrefix "${config.home.homeDirectory}/" config.xdg.userDirs.projects;
in
{
  imports = [ inputs.home-git-clone.homeManagerModules.default ];

  home.jjClone = {
    "${projects}/nixfiles".url = "git@codeberg.org:fosskar/nixfiles.git";
    "${projects}/wiki".url = "git@codeberg.org:fosskar/wiki.git";
  };

  home.gitClone = {
    "${projects}/nixwork".url = "git@codeberg.org:fosskar/nixwork.git";
    "${projects}/clan-core".url = "git@git.clan.lol:clan/clan-core.git";
  };
}
