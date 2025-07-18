_: {
  environment = {
    variables = {
      AMD_VULKAN_ICD = "RADV";
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
      amdvlk = {
        enable = false; # I am using RADV
      };
    };
    graphics = {
      enable = true;
      enable32Bit = true;
    };
  };
  systemd.services.set-amd-x3d-mode = {
    description = "Set AMD X3D vcache mode to cache";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "/bin/sh -c 'echo cache > /sys/bus/platform/drivers/amd_x3d_vcache/AMDI0101:00/amd_x3d_mode'";
      Type = "oneshot";
    };
  };
}
