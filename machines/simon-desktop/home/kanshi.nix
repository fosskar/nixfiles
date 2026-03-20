_: {
  services.kanshi = {
    enable = true;
    settings = [
      {
        profile.name = "desktop";
        profile.outputs = [
          {
            criteria = "DP-1";
            mode = "3440x1440@164.900Hz";
            position = "0,0";
            scale = 1.0;
          }
          {
            criteria = "HDMI-A-2";
            mode = "1920x1080@239.761Hz";
            position = "3440,-450";
            scale = 1.0;
            transform = "270";
            adaptiveSync = true;
          }
        ];
      }
    ];
  };
}
