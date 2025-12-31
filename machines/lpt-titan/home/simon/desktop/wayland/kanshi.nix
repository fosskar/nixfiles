_: {
  services.kanshi = {
    enable = true;
    systemdTarget = "graphical-session.target";

    settings = [
      # laptop only - just the internal display
      {
        profile = {
          name = "laptop";
          outputs = [
            {
              criteria = "eDP-1";
              status = "enable";
              mode = "1920x1080@60Hz";
              position = "0,0";
            }
          ];
        };
      }

      # home setup - ultrawide + vertical monitor, laptop off
      {
        profile = {
          name = "home";
          outputs = [
            {
              criteria = "eDP-1";
              status = "disable";
            }
            {
              # Dell AW3423DWF ultrawide
              criteria = "Dell Inc. AW3423DWF 45952S3";
              status = "enable";
              mode = "3440x1440@100Hz";
              position = "0,0";
            }
            {
              # Dell AW2518HF vertical
              criteria = "Dell Inc. DELL AW2518HF 5C2X09210GHU";
              status = "enable";
              mode = "1920x1080";
              position = "3440,0";
              transform = "270";
            }
          ];
        };
      }

      # office setup - two 27" monitors + laptop
      # note: update the serial numbers when you're at the office with: niri msg outputs
      {
        profile = {
          name = "office";
          outputs = [
            {
              # Iiyama PL2792Q left - update serial!
              criteria = "Iiyama North America PL2792Q 1152103302144";
              status = "enable";
              mode = "2560x1440@70Hz";
              position = "0,0";
            }
            {
              # Iiyama PL2792Q right - update serial!
              criteria = "Iiyama North America PL2792Q 1152103302467";
              status = "enable";
              mode = "2560x1440@70Hz";
              position = "2560,0";
            }
            {
              criteria = "eDP-1";
              status = "enable";
              mode = "1920x1080@60Hz";
              position = "5120,0";
            }
          ];
        };
      }
    ];
  };
}
