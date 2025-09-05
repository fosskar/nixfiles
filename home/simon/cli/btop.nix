_: {
  programs.btop = {
    enable = true;
    settings = {
      color_theme = "current";
      theme_background = false;
      truecolor = true;

      #* Set to true to force tty mode regardless if a real tty has been detected or not.
      #* Will force 16-color mode and TTY theme, set all graph symbols to "tty" and swap out other non tty friendly symbols.
      force_tty = false;

      #* Define presets for the layout of the boxes. Preset 0 is always all boxes shown with default settings. Max 9 presets.
      #* Format: "box_name:P:G,box_name:P:G" P=(0 or 1) for alternate positions, G=graph symbol to use for box.
      #* Use whitespace " " as separator between different presets.
      #* Example: "cpu:0:default,mem:0:tty,proc:1:default cpu:0:braille,proc:0:tty"
      presets = "cpu:1:default,proc:0:default cpu:0:default,mem:0:default,net:0:default cpu:0:block,net:0:tty";

      #* Set to True to enable "h,j,k,l,g,G" keys for directional control in lists.
      #* Conflicting keys for h:"help" and k:"kill" is accessible while holding shift.
      vim_keys = false;

      #* Rounded corners on boxes, is ignored if TTY mode is ON.
      rounded_corners = true;

      #* Default symbols to use for graph creation, "braille", "block" or "tty".
      #* "braille" offers the highest resolution but might not be included in all fonts.
      #* "block" has half the resolution of braille but uses more common characters.
      #* "tty" uses only 3 different symbols but will work with most fonts and should work in a real TTY.
      #* Note that "tty" only has half the horizontal resolution of the other two, so will show a shorter historical view.
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

      #* Manually set which boxes to show. Available values are "cpu mem net proc" and "gpu0" through "gpu5", separate values with whitespace.
      shown_boxes = "cpu mem net proc";

      #* Update time in milliseconds, recommended 2000 ms or above for better sample times for graphs.
      update_ms = 2000;

      #* Processes sorting, "pid" "program" "arguments" "threads" "user" "memory" "cpu lazy" "cpu direct",
      #* "cpu lazy" sorts top process over time (easier to follow), "cpu direct" updates top process directly.
      proc_sorting = "cpu lazy";

      #* Reverse sorting order, True or False.
      proc_reversed = false;

      #* Show processes as a tree.
      proc_tree = false;

      #* Use the cpu graph colors in the process list.
      proc_colors = true;

      #* Use a darkening gradient in the process list.
      proc_gradient = true;

      #* If process cpu usage should be of the core it's running on or usage of the total available cpu power.
      proc_per_core = false;

      #* Show process memory as bytes instead of percent.
      proc_mem_bytes = true;

      #* Show cpu graph for each process.
      proc_cpu_graphs = true;

      #* Use /proc/[pid]/smaps for memory information in the process info box (very slow but more accurate)
      proc_info_smaps = false;

      #* Show proc box on left side of screen instead of right.
      proc_left = false;

      #* (Linux) Filter processes tied to the Linux kernel(similar behavior to htop).
      proc_filter_kernel = false;

      #* In tree-view, always accumulate child process resources in the parent process.
      proc_aggregate = false;

      #* Sets the CPU stat shown in upper half of the CPU graph, "total" is always available.
      #* Select from a list of detected attributes from the options menu.
      cpu_graph_upper = "Auto";

      #* Sets the CPU stat shown in lower half of the CPU graph, "total" is always available.
      #* Select from a list of detected attributes from the options menu.
      cpu_graph_lower = "Auto";

      #* If gpu info should be shown in the cpu box. Available values = "Auto", "On" and "Off".
      show_gpu_info = "Auto";

      #* Toggles if the lower CPU graph should be inverted.
      cpu_invert_lower = true;

      #* Set to True to completely disable the lower CPU graph.
      cpu_single_graph = false;

      #* Show cpu box at bottom of screen instead of top.
      cpu_bottom = false;

      #* Shows the system uptime in the CPU box.
      show_uptime = true;

      #* Show cpu temperature.
      check_temp = true;

      #* Which sensor to use for cpu temperature, use options menu to select from list of available sensors.
      cpu_sensor = "Auto";

      #* Show temperatures for cpu cores also if check_temp is True and sensors has been found.
      show_coretemp = true;

      #* Set a custom mapping between core and coretemp, can be needed on certain cpus to get correct temperature for correct core.
      #* Use lm-sensors or similar to see which cores are reporting temperatures on your machine.
      #* Format "x:y" x=core with wrong temp, y=core with correct temp, use space as separator between multiple entries.
      #* Example: "4:0 5:1 6:3"
      cpu_core_map = "";

      #* Which temperature scale to use, available values: "celsius", "fahrenheit", "kelvin" and "rankine".
      temp_scale = "celsius";

      #* Use base 10 for bits/bytes sizes, KB = 1000 instead of KiB = 1024.
      base_10_sizes = false;

      #* Show CPU frequency.
      show_cpu_freq = true;

      #* Draw a clock at top of screen, formatting according to strftime, empty string to disable.
      #* Special formatting: /host = hostname | /user = username | /uptime = system uptime
      clock_format = "%X";

      #* Update main ui in background when menus are showing, set this to false if the menus is flickering too much for comfort.
      background_update = true;

      #* Custom cpu model name, empty string to disable.
      custom_cpu_name = "";

      #* Optional filter for shown disks, should be full path of a mountpoint, separate multiple values with whitespace " ".
      #* Begin line with "exclude=" to change to exclude filter, otherwise defaults to "most include" filter. Example: disks_filter="exclude=/boot /home/user".
      disks_filter = "";

      #* Show graphs instead of meters for memory values.
      mem_graphs = true;

      #* Show mem box below net box instead of above.
      mem_below_net = false;

      #* Count ZFS ARC in cached and available memory.
      zfs_arc_cached = true;

      #* If swap memory should be shown in memory box.
      show_swap = true;

      #* Show swap as a disk, ignores show_swap value above, inserts itself after first disk.
      swap_disk = true;

      #* If mem box should be split to also show disks info.
      show_disks = true;

      #* Filter out non physical disks. Set this to False to include network disks, RAM disks and similar.
      only_physical = true;

      #* Read diskst list from /etc/fstab. This also disables only_physical.
      use_fstab = true;

      #* Setting this to True will hide all datasets, and only show ZFS pools. (IO stats will be calculated per-pool)
      zfs_hide_datasets = false;

      #* Set to true to show available disk space for privileged users.
      disk_free_priv = false;

      #* Toggles if io activity % (disk busy time) should be shown in regular disk usage view.
      show_io_stat = true;

      #* Toggles io mode for disks, showing big graphs for disk read/write speeds.
      io_mode = false;

      #* Set to True to show combined read/write io graphs in io mode.
      io_graph_combined = false;

      #* Set the top speed for the io graphs in MiB/s (100 by default), use format "mountpoint:speed" separate disks with whitespace " ".
      #* Example: "/mnt/media:100 /:20 /boot:1".
      io_graph_speeds = "";

      #* Set fixed values for network graphs in Mebibits. Is only used if net_auto is also set to False.
      net_download = 100;

      net_upload = 100;

      #* Use network graphs auto rescaling mode, ignores any values set above and rescales down to 10 Kibibytes at the lowest.
      net_auto = true;

      #* Sync the auto scaling for download and upload to whichever currently has the highest scale.
      net_sync = true;

      #* Starts with the Network Interface specified here.
      net_iface = "";

      #* Show battery stats in top right if battery is present.
      show_battery = true;

      #* Which battery to use if multiple are present. "Auto" for auto detection.
      selected_battery = "Auto";

      #* Set loglevel for "~/.config/btop/btop.log" levels are: "ERROR" "WARNING" "INFO" "DEBUG".
      #* The level set includes all lower levels, i.e. "DEBUG" will show all logging info.
      log_level = "WARNING";

      #* Measure PCIe throughput on NVIDIA cards, may impact performance on certain cards.
      nvml_measure_pcie_speeds = true;

      #* Horizontally mirror the GPU graph.
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
}
