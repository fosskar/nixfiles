{ pkgs, ... }:
let
  jsonFormat = pkgs.formats.json { };
in
{
  xdg.configFile."zed/settings.json".source = jsonFormat.generate "zed-settings.json" {
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
    buffer_font_weight = 400;
    buffer_line_height = "standard";
    ui_font_family = "Inter";
    ui_font_fallbacks = [ ];
    ui_font_features = {
      calt = false;
    };
    ui_font_weight = 400;
    ui_font_size = 16;
    active_pane_magnification = 1.0;
    centered_layout = {
      left_padding = 0.2;
      right_padding = 0.2;
    };
    multi_cursor_modifier = "alt";
    vim_mode = false;
    hover_popover_enabled = false;
    confirm_quit = true;
    restore_on_startup = "last_workspace";
    drop_target_size = 0.2;
    when_closing_with_no_tabs = "platform_default";
    use_system_path_prompts = true;
    cursor_blink = true;
    cursor_shape = "bar";
    current_line_highlight = "all";
    show_completions_on_input = true;
    show_completion_documentation = true;
    completion_documentation_secondary_query_debounce = 300;
    auto_signature_help = false;
    show_signature_help_after_edits = true;
    show_wrap_guides = true;
    wrap_guides = [ ];
    redact_private_values = false;
    expand_excerpt_lines = 3;
    private_files = [
      "**/.env*"
      "**/*.pem"
      "**/*.key"
      "**/*.cert"
      "**/*.crt"
      "**/secrets.yml"
    ];
    use_on_type_format = true;
    use_autoclose = true;
    use_auto_surround = true;
    always_treat_brackets_as_autoclosed = false;
    show_inline_completions = true;
    show_whitespaces = "boundary";
    calls = {
      mute_on_join = true;
      share_on_join = false;
    };
    toolbar = {
      breadcrumbs = true;
      quick_actions = true;
      selections_menu = true;
    };
    scrollbar = {
      show = "auto";
      cursors = true;
      git_diff = true;
      search_results = true;
      selected_symbol = true;
      diagnostics = true;
    };
    unnecessary_code_fade = 0.5;
    double_click_in_multibuffer = "select";
    gutter = {
      line_numbers = true;
      code_actions = true;
      runnables = true;
      folds = true;
    };
    indent_guides = {
      enabled = true;
      line_width = 1;
      active_line_width = 1;
      coloring = "indent_aware";
      background_coloring = "disabled";
    };
    scroll_beyond_last_line = "one_page";
    vertical_scroll_margin = 3;
    scroll_sensitivity = 1.0;
    relative_line_numbers = false;
    search_wrap = true;
    seed_search_query_from_cursor = "always";
    inlay_hints = {
      enabled = true;
      show_type_hints = true;
      show_parameter_hints = true;
      show_other_hints = true;
      show_background = false;
      edit_debounce_ms = 700;
      scroll_debounce_ms = 50;
    };
    search = {
      whole_word = false;
      case_sensitive = false;
      include_ignored = false;
      regex = true;
    };
    project_panel = {
      button = true;
      default_width = 240;
      dock = "left";
      file_icons = true;
      folder_icons = true;
      git_status = true;
      indent_size = 15;
      auto_reveal_entries = true;
      auto_fold_dirs = false;
      scrollbar = {
        show = "never";
      };
    };
    projects_online_by_default = true;
    outline_panel = {
      button = true;
      default_width = 240;
      dock = "left";
      file_icons = true;
      folder_icons = true;
      git_status = true;
      indent_size = 15;
      auto_reveal_entries = true;
      auto_fold_dirs = true;
    };
    collaboration_panel = {
      button = true;
      dock = "left";
      default_width = 240;
    };
    chat_panel = {
      button = true;
      dock = "right";
      default_width = 240;
    };
    message_editor = {
      auto_replace_emoji_shortcode = true;
    };
    notification_panel = {
      button = true;
      dock = "right";
      default_width = 380;
    };
    assistant = {
      version = 2;
      enabled = true;
      button = true;
      default_model = {
        provider = "ollama";
        model = "deepseek-coder-v2:16b";
      };
    };
    slash-commands = {
      docs = {
        enabled = false;
      };
      projects = {
        enabled = false;
      };
    };
    show_call_status_icon = true;
    enable_language_server = true;
    linked_edits = true;
    language_servers = [ ];
    autosave = {
      after_delay = {
        milliseconds = 500;
      };
    };
    tab_bar = {
      show = true;
      show_nav_history_buttons = false;
    };
    tabs = {
      git_status = true;
      close_position = "right";
      file_icons = true;
    };
    preview_tabs = {
      enabled = true;
      enable_preview_from_file_finder = true;
      enable_preview_from_code_navigation = true;
    };
    remove_trailing_whitespace_on_save = true;
    extend_comment_on_newline = false;
    ensure_final_newline_on_save = true;
    format_on_save = "on";
    formatter = "auto";
    soft_wrap = "editor_width";
    preferred_line_length = 80;
    hard_tabs = false;
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
    git = {
      git_gutter = "tracked_files";
      inline_blame = {
        enabled = true;
      };
    };
    load_direnv = "shell_hook";
    inline_completions = {
      disabled_globs = [ ".env" ];
    };
    journal = {
      path = "~";
      hour_format = "hour24";
    };
    terminal = {
      shell = "system";
      dock = "bottom";
      default_width = 640;
      default_height = 320;
      working_directory = {
        always = {
          directory = "~/code";
        };
      };
      blinking = "terminal_controlled";
      alternate_scroll = "on";
      option_as_meta = false;
      copy_on_select = false;
      button = true;
      env = {
        EDITOR = "zed --wait";
      };
      line_height = "standard";
      detect_venv = {
        on = {
          directories = [
            ".venv"
            "venv"
          ];
          activate_script = "default";
        };
      };
      toolbar = {
        title = true;
      };
      font_size = 14;
    };
    code_actions_on_format = { };
    tasks = {
      variables = { };
    };
    file_types = {
      JSON = [ "flake.lock" ];
      JSONC = [
        "**/.zed/**/*.json"
        "**/zed/**/*.json"
        "**/Zed/**/*.json"
        "tsconfig.json"
        "pyrightconfig.json"
      ];
      Dockerfile = [ "Dockerfile*" ];
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
      docker-compose = true;
    };
    languages = {
      HTML = { };
      Java = {
        prettier = {
          plugins = [ "prettier-plugin-java" ];
        };
      };
      JavaScript = {
        language_servers = [
          "!typescript-language-server"
          "vtsls"
          "..."
        ];
      };
      JSON = { };
      JSONC = { };
      Markdown = {
        use_on_type_format = false;
      };
      Nix = {
        formatter = {
          external = {
            command = "${pkgs.nixfmt-rfc-style}/bin/nixfmt";
            arguments = [ ];
          };
        };
        prettier = {
          allowed = false;
        };
        language_servers = [ "nixd" ]; # [ "nixd", "!nil" ] OR [ "nil", "!nixd" ]
      };
      TypeScript = {
        language_servers = [
          "!typescript-language-server"
          "vtsls"
          "..."
        ];
      };
      XML = {
        prettier = {
          plugins = [ "@prettier/plugin-xml" ];
        };
      };
      YAML = {
        prettier = {
          allowed = false;
        };
        language_servers = [ "yaml-language-server" ];
      };
    };
    language_models = {
      ollama = {
        api_url = "http://localhost:11434";
        available_models = [
          {
            provider = "ollama";
            name = "deepseek-coder-v2:16b";
            max_tokens = 12000;
            keep_alive = "3m";
          }
        ];
      };
    };
    prettier = {
      allowed = true;
      trailingComma = "es5";
      tabWidth = 2;
      semi = false;
      singleQuote = true;
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
    };
    jupyter = {
      enabled = true;
    };
    vim = {
      toggle_relative_line_number = false;
      use_system_clipboard = "always";
      use_multiline_find = false;
      use_smartcase_find = false;
      custom_digraphs = { };
    };
    server_url = "https://zed.dev";
    preview = { };
    nightly = { };
    stable = { };
    dev = { };
    task = {
      show_status_indicator = true;
    };
    line_indicator_format = "long";
    proxy = null;
    command_aliases = { };
    ssh_connections = null;
    experimental.context_servers = {
      servers = [ ];
    };
  };
}
