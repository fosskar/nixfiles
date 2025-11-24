_: {
  services = {
    udisks2 = {
      enable = true;
      mountOnMedia = true;
      settings = {
        # general udisks2 configuration
        "udisks2.conf" = {
          defaults = {
            encryption = "luks2"; # alternatively, luks1
          };

          udisks2 = {
            modules = [ "*" ];
            modules_load_preference = "ondemand";
          };
        };
      };
    };
  };
}
