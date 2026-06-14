_: {
  flake.modules.homeManager.mpv = _: {
    programs.mpv = {
      enable = true;
      defaultProfiles = [ "gpu-hq" ];
      config = {
        border = false;
        gpu-context = "wayland";
        hwdec = "auto";
        osc = false;
        profile = "gpu-hq";
        vo = "gpu";
      };
    };
  };
}
