{
  programs.warp-terminal = {
    enable = true;
    settings = {
      appearance = {
        text = {
          notebook_font_size = 14.0;
          font_size = 13.0;
        };
        themes = {
          theme = "adeberry";
          system_theme = false;
          selected_system_themes = {
            dark = "adeberry";
            light = "light";
          };
        };
        vertical_tabs = {
          primary_info = "command";
          display_granularity = "panes";
          enabled = true;
          view_mode = "compact";
          compact_subtitle = "working_directory";
        };
        window.override_opacity = 100;
      };

      privacy = {
        telemetry_enabled = false;
        crash_reporting_enabled = false;
      };

      agents = {
        cloud_conversation_storage_enabled = false;
        third_party = {
          should_render_cli_agent_toolbar = true;
          auto_dismiss_composer_after_submit = false;
          auto_open_composer_on_cli_agent_start = false;
        };
        warp_agent = {
          is_any_ai_enabled = false;
          other = {
            show_conversation_history = false;
            show_agent_notifications = true;
          };
        };
      };

      terminal = {
        use_audible_bell = true;
        input = {
          honor_ps1 = true;
          input_box_type_setting = "classic";
          syntax_highlighting = true;
        };
      };

      code.editor = {
        show_global_search = true;
        show_project_explorer = true;
        show_code_review_button = true;
        auto_open_code_review_pane_on_first_agent_change = true;
        open_file_editor = "system_default";
      };

      notifications = {
        toast_duration_secs = 8;
        preferences = {
          is_agent_task_completed_enabled = true;
          is_long_running_enabled = true;
          is_needs_attention_enabled = true;
          is_password_prompt_enabled = true;
          long_running_threshold = 30;
          mode = "enabled";
          play_notification_sound = true;
        };
      };

      warp_drive.enabled = false;
    };

    defaultTabConfig = "nixfiles";

    tabConfigs.nixfiles = {
      name = "nixfiles";
      color = "green";
      panes = [
        {
          id = "root";
          split = "vertical";
          children = [
            "pi"
            "terminal"
          ];
        }
        {
          id = "pi";
          type = "terminal";
          is_focused = true;
          directory = "/home/simon/code/nixfiles";
          commands = [ "pi" ];
        }
        {
          id = "terminal";
          type = "terminal";
          directory = "/home/simon/code/nixfiles";
        }
      ];
    };
  };
}
