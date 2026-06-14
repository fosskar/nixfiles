{
  flake.modules.homeManager.btop = _: {
    programs.btop = {
      enable = true;
      settings = {
        color_theme = "current";
        theme_background = false;
        truecolor = true;

        force_tty = false;

        presets = "cpu:1:default,proc:0:default cpu:0:default,mem:0:default,net:0:default cpu:0:block,net:0:tty";

        vim_keys = false;

        rounded_corners = true;

        graph_symbol = "braille";

        # Graph symbol to use for graphs in cpu box, "default", "braille", "block" or "tty".
        graph_symbol_cpu = "default";

        # Graph symbol to use for graphs in gpu box, "default", "braille", "block" or "tty".
        graph_symbol_gpu = "default";

        # Graph symbol to use for graphs in cpu box, "default", "braille", "block" or "tty".
        graph_symbol_mem = "default";

        # Graph symbol to use for graphs in cpu box, "default", "braille", "block" or "tty".
        graph_symbol_net = "default";

        # Graph symbol to use for graphs in cpu box, "default", "braille", "block" or "tty".
        graph_symbol_proc = "default";

        shown_boxes = "cpu mem net proc";

        update_ms = 2000;

        proc_sorting = "cpu lazy";

        proc_reversed = false;

        proc_tree = false;

        proc_colors = true;

        proc_gradient = true;

        proc_per_core = false;

        proc_mem_bytes = true;

        proc_cpu_graphs = true;

        proc_info_smaps = false;

        proc_left = false;

        proc_filter_kernel = false;

        proc_aggregate = false;

        cpu_graph_upper = "Auto";

        cpu_graph_lower = "Auto";

        show_gpu_info = "Auto";

        cpu_invert_lower = true;

        cpu_single_graph = false;

        cpu_bottom = false;

        show_uptime = true;

        check_temp = true;

        cpu_sensor = "Auto";

        show_coretemp = true;

        cpu_core_map = "";

        temp_scale = "celsius";

        base_10_sizes = false;

        show_cpu_freq = true;

        clock_format = "%X";

        background_update = true;

        custom_cpu_name = "";

        disks_filter = "";

        mem_graphs = true;

        mem_below_net = false;

        zfs_arc_cached = true;

        show_swap = true;

        swap_disk = true;

        show_disks = true;

        only_physical = true;

        use_fstab = true;

        zfs_hide_datasets = false;

        disk_free_priv = false;

        show_io_stat = true;

        io_mode = false;

        io_graph_combined = false;

        io_graph_speeds = "";

        net_download = 100;

        net_upload = 100;

        net_auto = true;

        net_sync = true;

        net_iface = "";

        show_battery = true;

        selected_battery = "Auto";

        log_level = "WARNING";

        nvml_measure_pcie_speeds = true;

        gpu_mirror_graph = true;

        custom_gpu_name0 = "";
        custom_gpu_name1 = "";
        custom_gpu_name2 = "";
        custom_gpu_name3 = "";
        custom_gpu_name4 = "";
        custom_gpu_name5 = "";
      };
      themes = {
        current = ''
          # Main background, empty for terminal default, need to be empty if you want transparent background
          theme[main_bg]=""

          # Main text color
          theme[main_fg]="#EAEAEA"

          # Title color for boxes
          theme[title]="#8a8a8d"

          # Highlight color for keyboard shortcuts
          theme[hi_fg]="#f59e0b"

          # Background color of selected item in processes box
          theme[selected_bg]="#f59e0b"

          # Foreground color of selected item in processes box
          theme[selected_fg]="#EAEAEA"

          # Color of inactive/disabled text
          theme[inactive_fg]="#333333"

          # Misc colors for processes box including mini cpu graphs, details memory graph and details status text
          theme[proc_misc]="#8a8a8d"

          # Cpu box outline color
          theme[cpu_box]="#8a8a8d"

          # Memory/disks box outline color
          theme[mem_box]="#8a8a8d"

          # Net up/down box outline color
          theme[net_box]="#8a8a8d"

          # Processes box outline color
          theme[proc_box]="#8a8a8d"

          # Box divider line and small boxes line color
          theme[div_line]="#8a8a8d"

          # Temperature graph colors
          theme[temp_start]="#8a8a8d"
          theme[temp_mid]="#f59e0b"
          theme[temp_end]="#b91c1c"

          # CPU graph colors
          theme[cpu_start]="#8a8a8d"
          theme[cpu_mid]="#f59e0b"
          theme[cpu_end]="#b91c1c"

          # Mem/Disk free meter
          theme[free_start]="#8a8a8d"
          theme[free_mid]="#f59e0b"
          theme[free_end]="#b91c1c"

          # Mem/Disk cached meter
          theme[cached_start]="#8a8a8d"
          theme[cached_mid]="#f59e0b"
          theme[cached_end]="#b91c1c"

          # Mem/Disk available meter
          theme[available_start]="#8a8a8d"
          theme[available_mid]="#f59e0b"
          theme[available_end]="#b91c1c"

          # Mem/Disk used meter
          theme[used_start]="#8a8a8d"
          theme[used_mid]="#f59e0b"
          theme[used_end]="#b91c1c"

          # Download graph colors
          theme[download_start]="#8a8a8d"
          theme[download_mid]="#f59e0b"
          theme[download_end]="#b91c1c"

          # Upload graph colors
          theme[upload_start]="#8a8a8d"
          theme[upload_mid]="#f59e0b"
          theme[upload_end]="#b91c1c"
        '';
      };
    };
  };
}
