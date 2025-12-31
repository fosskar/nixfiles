_: {
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    tmux.enableShellIntegration = true;
    colors = {
      bg = "#171717";
      fg = "#eeeeee";
      hl = "#a3a3a3";
      "bg+" = "#1e1e1e";
      "fg+" = "#eeeeee";
      "hl+" = "#a3a3a3";
      info = "#999999";
      prompt = "#a3a3a3";
      pointer = "#a3a3a3";
      marker = "#a3a3a3";
      spinner = "#a3a3a3";
      header = "#999999";
      border = "#333333";
    };
    defaultOptions = [
      "--color=16"
      "--border=rounded"
      "--cycle"
      "--height=50%"
      "--layout=reverse"
      "--margin=1"
      "--padding=1"
    ];
  };
}
