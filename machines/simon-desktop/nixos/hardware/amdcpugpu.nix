{ pkgs, ... }:
{
  environment = {
    variables = {
      RADV_PERFTEST = "gpl";
    };
  };

  boot = {
    kernelParams = [
      "amd_pstate=active"
    ];
  };

  hardware = {
    amdgpu = {
      overdrive.enable = true;
      initrd.enable = true;
      opencl.enable = true; # ROCM maybe for LLM
    };
    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        rocmPackages.clr.icd
      ];
    };
  };
  systemd.services = {
    set-amd-x3d-mode = {
      description = "Set AMD X3D vcache mode to cache";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "/bin/sh -c 'echo cache > /sys/bus/platform/drivers/amd_x3d_vcache/AMDI0101:00/amd_x3d_mode'";
        Type = "oneshot";
      };
    };
    set-rtc-max-user-freq = {
      description = "Set RTC max user frequency";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "/bin/sh -c 'echo 3072 > /sys/class/rtc/rtc0/max_user_freq'";
        Type = "oneshot";
      };
    };
    "user@".serviceConfig = {
      Delegate = "cpu cpuset io memory pids";
    };
  };
}
