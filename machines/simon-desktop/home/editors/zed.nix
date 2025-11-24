{
  pkgs,
  ...
}:
{
  programs.zed-editor = {
    enable = true;
    #package = pkgs.zed-editor_git;
    installRemoteServer = true;
    extraPackages = with pkgs; [
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
    extensions = [
      "ansible"
      "basher"
      "docker-compose"
      "dockerfile"
      "fish"
      #"helm" #i use too much crds manifests
      "html"
      #"jj-lsp" #no pkgs in nixpkgs
      "jsonnet"
      "log"
      "material-icon-theme"
      "nix"
      "scss"
      "terraform"
      "toml"
      "vscode-dark-modern"
      "xml"
    ];
    userSettings = {
      theme = {
        mode = "system";
        light = "VSCode Dark Modern";
        dark = "VSCode Dark Modern";
      };
      "experimental.theme_overrides" = {
        "background.appearance" = "blurred";
        "background" = "#111111D7";
        "status_bar.background" = "#111111d7";
        "title_bar.background" = "#111111d7";
        "title_bar.inactive_background" = "#111111d7";
        "elevated_surface.background" = "#1E1E1EF2";
        "surface.background" = "#111111d7";
        "editor.background" = "#00000000";
        "editor.gutter.background" = "#00000000";
        "tab_bar.background" = "#00000000";
        "terminal.background" = "#00000000";
        "toolbar.background" = "#00000000";
        "tab.active_background" = "#00000055";
        "tab.inactive_background" = "#00000000";
        "panel.indent_guide" = "#111111d7";
        "panel.background" = "#00000000";
        "panel.focused_border" = "00000000";
        "element.active" = "#00000000";
        "border.variant" = "#00000000";
        "scrollbar.track.border" = "#00000000";
        "editor.active_line.background" = "#00000042";
        "scrollbar.track.background" = "#00000000";
      };
      icon_theme = "Material Icon Theme";
      base_keymap = "VSCode";
      buffer_font_family = "JetBrainsMono Nerd Font";
      buffer_line_height = "standard";
      ui_font_family = "Inter";
      confirm_quit = true;
      show_whitespaces = "boundary";
      calls = {
        mute_on_join = true;
        share_on_join = false;
      };
      context_servers = {
        mcp-server-nixos = {
          source = "custom";
          enabled = true;
          command = "nix";
          args = [
            "run"
            "github:utensils/mcp-nixos"
            "--"
          ];
          env = { };
        };
        mcp-server-git = {
          source = "custom";
          enabled = true;
          command = "nix";
          args = [
            "run"
            "github:natsukium/mcp-servers-nix#mcp-server-git"
            "--"
          ];
          env = { };
        };
      };
      soft_wrap = "editor_width";
      title_bar = {
        show_branch_icon = true;
      };
      indent_guides = {
        line_width = 1;
        active_line_width = 2;
        coloring = "indent_aware";
      };
      inlay_hints = {
        enabled = true;
      };
      project_panel = {
        sticky_scroll = false;
      };
      collaboration_panel = {
        button = false;
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
      };
      tab_size = 2;
      telemetry = {
        diagnostics = false;
        metrics = false;
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
      git = {
        inline_blame = {
          show_commit_summary = true;
        };
      };
      load_direnv = "shell_hook";
      journal = {
        hour_format = "hour24";
      };
      terminal = {
        env = {
          EDITOR = "zeditor";
        };
        line_height = "standard";
        font_size = 14;
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
        "Shell Script" = [ ".env.*" ];
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
            "!nixd"
            "nil"
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
