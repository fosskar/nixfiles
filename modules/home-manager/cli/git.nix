_: {
  flake.modules.homeManager.git =
    { pkgs, ... }:
    let
      # default identity (used when no conditional match)
      defaultEmail = "fosskar.educated493@passmail.net";
      defaultName = "fosskar";

      # forge-specific identities
      github = {
        name = "fosskar";
        email = "117449098+fosskar@users.noreply.github.com";
      };
      codeberg = {
        name = "fosskar";
        email = "fosskar@noreply.codeberg.org";
      };
    in
    {
      home.packages = [
        pkgs.gh
        pkgs.glab
        pkgs.fjo
        pkgs.forgejo-cli
      ];

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
          core.editor = "micro";
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

          alias = {
            a = "add --patch";
            ad = "add";

            b = "branch";
            ba = "branch -a";
            bd = "branch --delete";
            bD = "branch -D";

            c = "commit";
            ca = "commit --amend";
            cm = "commit -m";
            co = "checkout";
            cb = "checkout -b";
            cl = "clone";
            d = "diff";
            ds = "diff --staged";
            h = "show";
            p = "push";
            pf = "push --force-with-lease";
            pl = "pull";
            l = "log";
            r = "rebase";
            s = "status --short --branch";
            st = "status --short --branch";
            ss = "status";
            sta = "stash";
            stc = "stash clear";
            forgor = "commit --amend --no-edit";
            graph = "log --all --decorate --graph --oneline";
            oops = "checkout --";
            f = "fetch";
            sw = "switch";
          };
        };

        ignores = [
          ".cache/"
          ".DS_Store"
          ".idea/"
          "*.swp"
          "*.elc"
          "auto-save-list"
          "Thumbs.db"
          ".vscode"
          ".vscodium"
        ];

        # signing.key is set per-user; format/signByDefault are common
        signing = {
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
          # github (ssh://)
          {
            condition = "hasconfig:remote.*.url:ssh://git@github.com/**";
            contents.user = github;
          }
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
          # codeberg (ssh://)
          {
            condition = "hasconfig:remote.*.url:ssh://git@codeberg.org/**";
            contents.user = codeberg;
          }
        ];
      };
    };
}
