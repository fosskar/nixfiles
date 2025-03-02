{ pkgs, ... }:
{
  programs.zed-editor = {
    extensions = [
      "dockerfile"
      "html"
      "nix"
      "toml"
      "xml"
      "scss"
      "vscode-dark-modern"
      "helm"
      "ansible"
      "bearded-icon-theme"
      "jsonnet"
      "log"
    ];
    userSettings = {
      theme = {
        mode = "system";
        light = "VSCode Dark Modern";
        dark = "VSCode Dark Modern";
      };
      icon_theme = "Bearded Icon Theme";
      base_keymap = "VSCode";
      features = {
        edit_prediction_provider = "zed";
      };
      buffer_font_family = "JetBrainsMono Nerd Font";
      buffer_font_size = 16;
      buffer_line_height = "standard";
      ui_font_family = "Inter";
      ui_font_size = 17;
      confirm_quit = true;
      show_whitespaces = "boundary";
      calls = {
        mute_on_join = true;
        share_on_join = false;
      };
      indent_guides = {
        enabled = true;
        coloring = "indent_aware";
      };
      inlay_hints = {
        enabled = true;
      };
      file_finder = {
        modal_max_width = "medium";
      };
      centered_layout = {
        left_padding = 0.15;
        right_padding = 0.15;
      };
      project_panel = {
        indent_size = 15;
        auto_fold_dirs = false;
      };
      outline_panel = {
        indent_size = 15;
        auto_fold_dirs = false;
      };
      collaboration_panel = {
        button = false;
      };
      git_panel = {
        button = true;
      };
      assistant = {
        enabled = true;
        default_model = {
          provider = "zed.dev";
          model = "claude-3-5-sonnet";
        };
        version = "2";
        button = true;
      };
      #language_models = {
      #  ollama = {
      #    api_url = "http://localhost:11434";
      #    low_speed_timeout_in_seconds = 900;
      #  };
      #};
      autosave = {
        after_delay = {
          milliseconds = 2000;
        };
      };
      tabs = {
        git_status = true;
        file_icons = true;
        always_show_close_button = true;
        activate_on_close = "neighbour";
        show_diagnostics = "all";
      };
      tab_bar = {
        show = true;
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
        "**/.jj"
        "**/CVS"
        "**/.DS_Store"
        "**/Thumbs.db"
        "**/.classpath"
        "**/.settings"
        #
        "**/out"
        "**/dist"
        "**/.husky"
        "**/.turbo"
        "**/.vscode-test"
        "**/.vscode"
        "**/.next"
        "**/.storybook"
        "**/.tap"
        "**/.nyc_output"
        "**/report"
        "**/node_modules"
      ];
      journal = {
        hour_format = "hour24";
      };
      load_direnv = "shell_hook";
      terminal = {
        env = {
          EDITOR = "zed --wait";
        };
        line_height = "standard";
        font_size = 14;
      };
      file_types = {
        "Plain Text" = [ "txt" ];
        JSON = [
          "flake.lock"
          "json"
          "jsonc"
          ".code-snippets"
        ];
        JSONC = [
          "**/.zed/**/*.json"
          "**/zed/**/*.json"
          "**/Zed/**/*.json"
          "**/.vscode/**/*.json"
        ];
        "Shell Script" = [ ".env.*" ];
        Dockerfile = [
          "Dockerfile*"
          "Dockerfile"
          "Dockerfile.*"
        ];
        TOML = [ "uv.lock" ];
      };
      languages = {
        Nix = {
          formatter = {
            external = {
              command = "${pkgs.nixfmt-rfc-style}/bin/nixfmt";
              arguments = [
                "--quiet"
                "--"
              ];
            };
          };
          language_servers = [
            "nixd"
            "!nil"
          ];
        };
        Markdown = {
          format_on_save = "on";
          remove_trailing_whitespace_on_save = false; # If you rely on invisible trailing whitespace being converted to <br />
        };
        YAML = {
          # this fixes wrong error for multiple manifest documents in a single .yaml file. docker-compose extensions fault
          language_servers = [
            "yaml-language-server"
            "!docker-compose"
          ];
        };
      };
      lsp = {
        nixd = {
          binary = {
            path_lookup = true;
          };
          settings = {
            diagnostic = {
              suppress = [ "sema-extra-with" ];
            };
          };
        };
        nil = {
          binary = {
            path_lookup = true;
          };
          settings = {
            diagnostics = {
              ignored = [ "unused_binding" ];
            };
          };
        };
      };
    };
  };
}
