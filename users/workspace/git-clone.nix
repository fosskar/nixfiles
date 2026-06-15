{
  inputs,
  ...
}:
{
  imports = [ inputs.home-git-clone.homeManagerModules.default ];

  home.jjClone = {
    "Projects/nixfiles".url = "git@codeberg.org:fosskar/nixfiles.git";
    "Projects/wiki".url = "git@codeberg.org:fosskar/wiki.git";
  };

  home.gitClone = {
    "Projects/nixwork".url = "git@codeberg.org:fosskar/nixwork.git";
    "Projects/clan-core".url = "git@git.clan.lol:clan/clan-core.git";
  };
}
