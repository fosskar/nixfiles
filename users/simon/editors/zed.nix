{
  pkgs,
  config,
  inputs,
  ...
}:
let
  t = config.theme;
in
{
  programs.zed-editor = {
    enable = true;
    package = inputs.zed.packages.${pkgs.stdenv.hostPlatform.system}.default;
    installRemoteServer = true;
    extraPackages = with pkgs; [
      nil
      nixd
      nixfmt
    ];
    extensions = [
      "ansible"
      "basher"
      "docker-compose"
      "dockerfile"
      "fish"
      "helm"
      "html"
      "jj-lsp"
      "jsonnet"
      "log"
      "material-icon-theme"
      "nix"
      "terraform"
      "toml"
      "vscode-dark-modern"
    ];
    userSettings = {
      theme = "VSCode Dark Modern";
      # transparent window; niri provides blur through its window-rule.
      # `blurred` asks Zed/GPUI to use a Wayland blur protocol, which niri does not expose here.
      "experimental.theme_overrides" = {
        "background.appearance" = "transparent";
        "background" = "${t.dark.bg.base}CC"; # window base

        "panel.background" = "#00000000"; # panels: project, agent, sidebar content
        "status_bar.background" = "${t.dark.bg.base}CC"; # bottom bar
        "title_bar.background" = "${t.dark.bg.base}CC"; # top bar and sidebar/threads header
        "title_bar.inactive_background" = "${t.dark.bg.base}CC"; # when Zed is not focused
        "editor.background" = "#00000040"; # code area
        "editor.gutter.background" = "#00000040"; # line number gutter
        "elevated_surface.background" = "${t.dark.bg.base}D9"; # right-click popups
        "ghost_element.background" = "#00000033"; # contrast behind buttons/areas
        "tab_bar.background" = "#00000033"; # tab bars
        "tab.active_background" = "#00000000"; # active tab
        "tab.inactive_background" = "#00000040"; # inactive tabs
        "terminal.ansi.background" = "#00000000"; # terminal ANSI default background
        "terminal.background" = "#00000000"; # terminal pane background
        "toolbar.background" = "#00000033"; # breadcrumbs/toolbars

        "error" = "${t.dark.semantic.error}40";
        "warning" = "${t.dark.semantic.warning}40";
        "success" = "${t.dark.semantic.success}40";
        "text.accent" = "${t.dark.accent.primary}40";
      };
      colorize_brackets = true;
      bottom_dock_layout = "left_aligned";
      edit_predictions = {
        provider = "copilot";
        allow_data_collection = "no";
      };
      agent = {
        enable_feedback = false;
        play_sound_when_agent_done = "always";
        show_turn_stats = true;
        thinking_display = "always_collapsed";
      };
      agent_servers = {
        claude-acp = {
          type = "registry";
        };
        codex-acp = {
          type = "registry";
        };
        opencode = {
          type = "registry";
        };
        pi-acp = {
          type = "registry";
        };
        amp-acp = {
          type = "registry";
        };
        factory-droid = {
          type = "registry";
        };
      };
      icon_theme = "Material Icon Theme";
      #vim_mode = true;
      buffer_font_family = config.theme.fonts.mono;
      buffer_line_height = "standard";
      ui_font_family = config.theme.fonts.sans;
      confirm_quit = true;
      show_whitespaces = "boundary";
      calls = {
        mute_on_join = true;
      };
      soft_wrap = "editor_width";
      semantic_tokens = "combined";
      restore_on_startup = "last_workspace";
      indent_guides = {
        active_line_width = 2;
        coloring = "indent_aware";
      };
      inlay_hints = {
        enabled = true;
      };
      collaboration_panel = {
        button = false;
      };
      project_panel = {
        entry_spacing = "standard";
        indent_size = 15;
        diagnostic_badges = true;
        git_status_indicator = true;
        drag_and_drop = false;
      };
      git_panel = {
        tree_view = true;
        file_icons = true;
        show_count_badge = true;
      };
      autosave = {
        after_delay = {
          milliseconds = 2000;
        };
      };
      tabs = {
        git_status = true;
        file_icons = true;
        show_diagnostics = "all";
        show_pinned_tabs_in_separate_row = true;
      };
      preview_tabs = {
        enable_preview_from_file_finder = true;
      };
      tab_size = 2;
      telemetry = {
        diagnostics = false;
        metrics = false;
      };
      diagnostics = {
        inline = {
          enabled = true;
        };
      };
      status_bar = {
        line_endings_button = true;
      };
      title_bar = {
        button_layout = "standard";
      };
      auto_update = false;
      file_scan_exclusions = [
        "**/.direnv"
        "**/.pre-commit-config.yaml"
        "**/.git"
        "**/.svn"
        "**/.hg"
        "**/.jj"
        "**/.repo"
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
      load_direnv = "shell_hook";
      journal = {
        hour_format = "hour24";
      };
      terminal = {
        #env = {
        #  EDITOR = "zeditor";
        #};
        scrollbar = {
          show = "never";
        };
        font_size = 14;
        show_count_badge = true;
        toolbar = {
          breadcrumbs = true;
        };
      };
      file_types = {
        Ansible = [
          "**.ansible.yml"
          "**.ansible.yaml"
          "**/defaults/*.yml"
          "**/defaults/*.yaml"
          "**/meta/*.yml"
          "**/meta/*.yaml"
          "**/tasks/*.yml"
          "**/tasks/*.yaml"
          "**/handlers/*.yml"
          "**/handlers/*.yaml"
          "**/group_vars/*.yml"
          "**/group_vars/*.yaml"
          "**/host_vars/*.yml"
          "**/host_vars/*.yaml"
          "**/playbooks/*.yml"
          "**/playbooks/*.yaml"
          "**playbook*.yml"
          "**playbook*.yaml"
        ];
        Dockerfile = [
          "Dockerfile*"
          "Dockerfile"
          "Dockerfile.*"
        ];
        Helm = [
          "**/templates/**/*.tpl"
          "**/templates/**/*.yaml"
          "**/templates/**/*.yml"
          "**/helmfile.d/**/*.yaml"
          "**/helmfile.d/**/*.yml"
          "**/values*.yaml"
          "**/Chart.yaml"
        ];
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
        "Plain Text" = [ "txt" ];
        TOML = [
          "uv.lock"
          "Cargo.toml"
          "toml"
        ];
        XML = [
          "rdf"
          "gpx"
          "kml"
        ];
      };
      languages = {
        Nix = {
          formatter = {
            external = {
              command = "nixfmt";
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
        "Shell Script" = {
          formatter = {
            external = {
              command = "shfmt";
              arguments = [
                "--filename"
                "{buffer_path}"
                "--indent"
                "2"
              ];
            };
          };
        };
        YAML = {
          formatter = "language_server";
          # this fixes wrong error for multiple manifest documents in a single .yaml file. docker-compose extensions fault
          language_servers = [
            "yaml-language-server"
            "!docker-compose"
          ];
        };
        Markdown = {
          format_on_save = "on";
        };
      };
      lsp = {
        json-language-server = {
          settings = {
            json = {
              schemas = [
                {
                  fileMatch = [
                    "renovate.json"
                    ".renocaterc"
                    ".renovaterc.json"
                  ];
                  url = "https://docs.renovatebot.com/renovate-schema.json";
                }
              ];
            };
          };
        };
        jsonnet-language-server = {
          settings = {
            resolve_paths_with_tanka = true;
          };
        };
        nixd = {
          settings = {
            diagnostic = {
              suppress = [ "sema-extra-with" ];
            };
          };
        };
        nil = {
          settings = {
            diagnostics = {
              ignored = [ "unused_binding" ];
            };
          };
        };
        terraform-ls = {
          initialization_options = {
            experimentalFeatures = {
              prefillRequiredFields = true;
            };
          };
        };
        helm-ls = {
          settings = {
            "helm-ls" = {
              valuesFiles = {
                mainValuesFile = "values.yaml";
                additionalValuesFilesGlobPattern = "*.values.yaml";
              };
              helmLint = {
                enabled = true;
                ignoredMessages = { };
              };
              yamlls = {
                enabled = false; # cant be enabled breaks when using non standard kubernetes yaml schemas and i dont want to add on every file a customcrd schema mal abgesehen davon that not every crd has its own schema
              };
            };
          };
        };
        yaml-language-server = {
          settings = {
            yaml = {
              keyOrdering = false;
              format = {
                enable = true;
                singleQuote = false;
              };
              completion = true;
            };
            schemas = {
              "https://raw.githubusercontent.com/ansible/ansible/main/lib/ansible/utils/schema/ansible-schema.json" =
                [
                  "./inventory/*.yaml"
                  "./inventory/*.yml"
                  "hosts.yaml"
                  "hosts.yml"
                ];
            };
          };
        };
      };
    };
  };
}
