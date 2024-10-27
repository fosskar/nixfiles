{ pkgs, ... }:
{
  programs.zed-editor = {
    extensions = [
      "dockerfile"
      "html"
      "nix"
      "toml"
      "git-firefly"
      "xml"
      "vscode-dark-modern"
      "java"
      "helm"
      "ansible"
    ];
    userSettings = {
      theme = {
        mode = "system";
        light = "VSCode Dark Modern";
        dark = "VSCode Dark Modern";
      };
      base_keymap = "VSCode";
      features = {
        inline_completion_provider = "none";
      };
      buffer_font_family = "JetBrainsMono Nerd Font";
      buffer_font_size = 15;
      buffer_line_height = "standard";
      ui_font_family = "Inter";
      ui_font_size = 16;
      confirm_quit = true;
      show_whitespaces = "boundary";
      calls = {
        mute_on_join = true;
        share_on_join = false;
      };
      indent_guides = {
        coloring = "indent_aware";
      };
      search = {
        regex = true;
      };
      inlay_hints = {
        enabled = true;
      };
      project_panel = {
        indent_size = 15;
        auto_fold_dirs = false;
        scrollbar = {
          show = "auto";
        };
      };
      outline_panel = {
        indent_size = 15;
        auto_fold_dirs = false;
      };
      assistant = {
        default_model = {
          provider = "zed.dev";
          model = "claude-3-5-sonnet-20240620";
        };
      };
      language_models = {
        ollama = {
          low_speed_timeout_in_seconds = 60;
          available_models = [
            {
              provider = "ollama";
              name = "deepseek-coder-v2:16b";
              display_name = "DeepSeek Coder v2";
              max_tokens = 33000;
              keep_alive = "10m";
            }
          ];
        };
      };
      autosave = {
        after_delay = {
          milliseconds = 2000;
        };
      };
      tab_bar = {
        show_nav_history_buttons = false;
      };
      tabs = {
        git_status = true;
        file_icons = true;
      };
      extend_comment_on_newline = false;
      tab_size = 2;
      telemetry = {
        diagnostics = false;
        metrics = false;
      };
      auto_update = false;
      diagnostics = {
        include_warnings = true;
      };
      file_scan_exclusions = [
        "**/.direnv"
        "**/.pre-commit-config.yaml"
        "**/.git"
        "**/.svn"
        "**/.hg"
        "**/CVS"
        "**/.DS_Store"
        "**/Thumbs.db"
        "**/.classpath"
        "**/.settings"
      ];
      journal = {
        hour_format = "hour24";
      };

      terminal = {
        copy_on_select = false;
        env = {
          EDITOR = "zed --wait";
        };
        line_height = "standard";
        font_size = 14;
      };
      file_types = {
        "Plain Text" = [ "txt" ];
        JSON = [ "flake.lock" ];
        JSONC = [
          "**/.zed/**/*.json"
          "**/zed/**/*.json"
          "**/Zed/**/*.json"
          "tsconfig.json"
          "pyrightconfig.json"
        ];
        Dockerfile = [ "Dockerfile*" ];
        TOML = [ "uv.lock" ];
      };
      auto_install_extensions = {
        html = true;
        nix = true;
        dockerfile = true;
        toml = true;
        git-firefly = true;
        xml = true;
        vscode-dark-modern = true;
        java = true;
        helm = true;
        ansible = true;
      };
      languages = {
        Nix = {
          formatter = {
            external = {
              command = "${pkgs.nixfmt-rfc-style}/bin/nixfmt";
              arguments = [ "-" ];
            };
          };
          prettier = {
            allowed = true;
          };
          language_servers = [
            "nixd"
            "!nil"
          ];
        };
        Markdown = {
          format_on_save = "on";
          use_on_type_format = false;
          remove_trailing_whitespace_on_save = false; # If you rely on invisible trailing whitespace being converted to <br />
          prettier = {
            allowed = true;
          };
        };
      };
      lsp = {
        nixd = {
          binary = {
            path_lookup = true;
          };
        };
        ## future nil support in nix extension? see: https://github.com/zed-extensions/nix/pull/13
        #nil = {
        #  binary = {
        #    path_lookup = true;
        #  };
        #};
        yaml-language-server = {
          settings = {
            yaml = {
              keyOrdering = true; # Enforces alphabetical ordering of keys in maps
            };
          };
        };
        json-language-server = {
          binary = {
            path_lookup = true;
          };
        };
      };
    };
  };
}
