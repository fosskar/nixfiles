{ pkgs, ... }:
let
  jellyfin-ffmpeg-overlay = (
    _final: prev: {
      jellyfin-ffmpeg = prev.jellyfin-ffmpeg.override {
        # Exact version depends on jellyfin-ffmpeg package
        # In 24.11 it's ffmpeg_7-full
        ffmpeg_7-full = prev.ffmpeg_7-full.override {
          withMfx = false; # Older media driver
          withVpl = true; # New driver for Arc GPUs
          withUnfree = true;
        };
      };
    }
  );
in
{
  nixpkgs.overlays = [ jellyfin-ffmpeg-overlay ];

  # jellyfin media server
  services.jellyfin = {
    enable = true;
    openFirewall = true; # port 8096
    user = "jellyfin";
    group = "media";
  };

  environment.systemPackages = [
    pkgs.jellyfin
    pkgs.jellyfin-web
    pkgs.jellyfin-ffmpeg
    pkgs.intel-gpu-tools # for intel_gpu_top monitoring
    pkgs.fontconfig
  ];

  # configure shared media group
  users = {
    groups.media = {
      gid = 10000; # maps to host 110000 (storage_shared)
    };
    users.jellyfin = {
      extraGroups = [
        "render"
        "video"
      ];
    };
  };

  systemd.services.jellyfin.environment.LIBVA_DRIVER_NAME = "iHD";
}
