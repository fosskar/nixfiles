_: {
  flake.modules.homeManager.mpv = _: {
    programs.mpv = {
      enable = true;
      defaultProfiles = [ "high-quality" ];
      config = {
        border = false;
        gpu-context = "wayland";
        hwdec = "auto";
        osc = false;
        vo = "gpu";
      };
    };
  };
}
