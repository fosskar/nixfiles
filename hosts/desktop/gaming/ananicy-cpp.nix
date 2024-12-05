{ pkgs, ... }:
{
  services.ananicy = {
    enable = false;
    package = pkgs.ananicy-cpp.override { withBpf = false; };
    rulesProvider = pkgs.ananicy-rules-cachyos_git;
  };
}
