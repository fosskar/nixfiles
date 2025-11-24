{ pkgs, ... }:
{
  # sched-ext needs to be disabled for this to work properly
  services.ananicy = {
    enable = true;
    package = pkgs.ananicy-cpp;
    #package = pkgs.ananicy-cpp.override { withBpf = false; };
    rulesProvider = pkgs.ananicy-rules-cachyos;
    extraRules = [
      {
        "name" = "gamescope";
        "nice" = -20;
      }
    ];
  };
}
