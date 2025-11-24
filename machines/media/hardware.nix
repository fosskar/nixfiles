{ pkgs, ... }:
{
  # # example: intel quicksync
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver # for broadwell and newer
      intel-compute-runtime
      vpl-gpu-rt # oneVPL (QSV) runtime
    ];
  };

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD"; # Prefer the modern iHD backend
  };
}
