{
  mylib,
  ...
}:
let
  # default identity (used when no conditional match)
  defaultEmail = "osscar.unheard025@passmail.net";
  defaultName = "osscar";

  # forge-specific identities
  github = {
    name = "fosskar";
    email = "117449098+fosskar@users.noreply.github.com";
  };
  codeberg = {
    name = "osscar";
    email = "osscar@noreply.codeberg.org";
  };
  tangled = {
    name = "osscar";
    email = "osscar.unheard025@passmail.net";
  };
in
{
  imports = mylib.scanPaths ./. { };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options.dark = true;
  };

  programs.git = {
    enable = true;
    lfs.enable = true;
    #riff.enable = true; # maybe?
    settings = {
      branch = {
        autosetuprebase = "always";
        sort = "-committerdate";
      };
      column.ui = "auto";
      commit.verbose = true;
      color.ui = true;
      core.editor = "nvim";
      diff = {
        algorithm = "histogram";
        colorMoved = "plain";
        mnemonicPrefix = true;
        renames = true;
      };
      fetch = {
        all = true;
        prune = true;
        pruneTags = true;
        auto = true;
        parallel = 10;
      };
      github.user = defaultName;
      help.autoCorrect = "prompt";
      init.defaultBranch = "main";
      merge.conflictstyle = "zdiff3";
      push = {
        autoSetupRemote = true;
        default = "simple";
        followTags = true;
      };
      pull.rebase = true;
      rebase = {
        autoSquash = true;
        autoStash = true;
        updateRefs = true;
      };
      tag.sort = "version:refname";
      user = {
        email = defaultEmail;
        name = defaultName;
      };
    };

    signing = {
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID3AsDe157avF+iFa1TavZHwjDpugyePDqJ6gaRNzGIA";
      format = "ssh";
      signByDefault = true;
    };

    # conditional includes based on remote URL
    includes = [
      # github (ssh)
      {
        condition = "hasconfig:remote.*.url:git@github.com:*/**";
        contents.user = github;
      }
      # github (https)
      {
        condition = "hasconfig:remote.*.url:https://github.com/**";
        contents.user = github;
      }
      # gitlab (ssh)
      # {
      #   condition = "hasconfig:remote.*.url:git@gitlab.com:*/**";
      #   contents.user = gitlab;
      # }
      # gitlab (https)
      # {
      #   condition = "hasconfig:remote.*.url:https://gitlab.com/**";
      #   contents.user = gitlab;
      # }
      # codeberg (ssh)
      {
        condition = "hasconfig:remote.*.url:git@codeberg.org:*/**";
        contents.user = codeberg;
      }
      # codeberg (https)
      {
        condition = "hasconfig:remote.*.url:https://codeberg.org/**";
        contents.user = codeberg;
      }
      # tangled (ssh)
      {
        condition = "hasconfig:remote.*.url:git@tangled.sh:*/**";
        contents.user = tangled;
      }
      # tangled (https)
      {
        condition = "hasconfig:remote.*.url:https://tangled.sh/**";
        contents.user = tangled;
      }
    ];
  };
}
