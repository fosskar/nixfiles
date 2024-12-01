_: {
  programs.corectrl = {
    enable = false;
    gpuOverclock = {
      enable = true;
      ppfeaturemask = "0xffffffff";
    };
  };
}
