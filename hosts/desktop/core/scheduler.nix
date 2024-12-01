_: {
  services.scx = {
    enable = true;
    scheduler = "scx_lavd"; # best for gaming? scx since kernel 6.12 so no chaotic-nyx required anymore
    extraArgs = [ "--performance" ];
  };
}
