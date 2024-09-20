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
    buffer_font_fallbacks = [ ];
    buffer_font_features = {
      calt = true;
    };
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
    hover_popover_enabled = true;
    confirm_quit = false;
    restore_on_startup = "last_workspace";
    drop_target_size = 0.2;
    when_closing_with_no_tabs = "platform_default";
    use_system_path_prompts = true;
    cursor_blink = true;
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
    always_treat_brackets_as_autoclosed = true;
    show_inline_completions = true;
    show_whitespaces = "selection";
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
      edit_debounce_ms = 700;
      scroll_debounce_ms = 50;
    };
    project_panel = {
      button = true;
      default_width = 240;
      dock = "left";
      file_icons = true;
      folder_icons = true;
      git_status = true;
      indent_size = 10;
      auto_reveal_entries = true;
      auto_fold_dirs = false;
      scrollbar = {
        show = "always";
      };
    };
    outline_panel = {
      button = true;
      default_width = 300;
      dock = "left";
      file_icons = true;
      folder_icons = true;
      git_status = true;
      indent_size = 10;
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
      show_nav_history_buttons = true;
    };
    tabs = {
      git_status = true;
      close_position = "right";
      file_icons = true;
    };
    preview_tabs = {
      enabled = true;
      enable_preview_from_file_finder = false;
      enable_preview_from_code_navigation = false;
    };
    remove_trailing_whitespace_on_save = true;
    extend_comment_on_newline = false;
    ensure_final_newline_on_save = true;
    format_on_save = "on";
    formatter = "auto";
    soft_wrap = "prefer_line";
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
      working_directory = "current_project_directory";
      blinking = "terminal_controlled";
      alternate_scroll = "off";
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
            ".env"
            "env"
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
      ];
    };
    auto_install_extensions = {
      html = true;
      nix = true;
      dockerfile = true;
    };
    languages = {
      HTML = {
        prettier = {
          allowed = true;
        };
      };
      Java = {
        prettier = {
          allowed = true;
          plugins = [ "prettier-plugin-java" ];
        };
      };
      JavaScript = {
        language_servers = [
          "!typescript-language-server"
          "vtsls"
          "..."
        ];
        prettier = {
          allowed = true;
        };
      };
      JSON = {
        prettier = {
          allowed = true;
        };
      };
      JSONC = {
        prettier = {
          allowed = true;
        };
      };
      Markdown = {
        format_on_save = "on";
        use_on_type_format = false;
        prettier = {
          allowed = true;
        };
      };
      Nix = {
        format_on_save = "on";
        language_servers = [ "nixd" ];
        formatter = {
          external = {
            arguments = [ ];
            command = "${pkgs.nixfmt-rfc-style}/bin/nixfmt";
          };
        };
      };
      TypeScript = {
        language_servers = [
          "!typescript-language-server"
          "vtsls"
          "..."
        ];
        prettier = {
          allowed = true;
        };
      };
      XML = {
        prettier = {
          allowed = true;
          plugins = [ "@prettier/plugin-xml" ];
        };
      };
      YAML = {
        prettier = {
          allowed = true;
        };
      };
    };
    language_models = {
      ollama = {
        api_url = "http://127.0.0.1:11434/v1";
      };
    };
    prettier = {
      allowed = true;
    };
    lsp = {
      nixd = {
        command = "${pkgs.nixd}/bin/nixd";
        arguments = [ "--stdio" ];
      };
    };
    vim = {
      use_system_clipboard = "always";
      use_multiline_find = false;
      use_smartcase_find = false;
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
  };
}
