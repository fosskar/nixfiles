_: {
  services.kanshi = {
    enable = true;
    settings = [
      {
        profile.name = "internal";
        profile.outputs = [
          {
            criteria = "eDP-1";
            mode = "2880x1920@120Hz";
            position = "0,0";
            scale = 1.75;
            adaptiveSync = true;
          }
        ];
      }
    ];
  };
}
