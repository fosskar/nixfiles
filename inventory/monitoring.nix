_: {
  flake.clan.inventory.instances = {
    monitoring = {
      module = {
        name = "monitoring";
        input = "self";
      };

      roles = {
        server.machines."nixbox".settings = {
          extraTelegrafTargets = [ "openwrt.lan:9273" ];
        };
        client.tags = [ "server" ];
      };
    };

    beszel = {
      module = {
        name = "beszel";
        input = "self";
      };
      roles = {
        server.machines."nixbox" = { };
        client.tags = [ "server" ];
        client.machines."nixbox".settings = {
          sensors = "-nct6798_cputin,-nct6798_auxtin0,-nct6798_auxtin2,-nct6798_auxtin4,-bnxt_en";
          filesystem = "/persist";
          extraFilesystems = "/__Root,/nix__Nix,/boot__Boot,/boot-fallback__BootFallback,/tank__Tank,/tank/apps__Apps,/tank/media__Media,/tank/shares__Shares,/tank/backup__Backup";
          smartDevices = "/dev/nvme0,/dev/nvme1,/dev/sda,/dev/sdb,/dev/sdc,/dev/sdd,/dev/sde,/dev/sdf,/dev/sdg";
        };
      };
    };

    ups = {
      module = {
        name = "ups";
        input = "self";
      };
      roles = {
        primary.machines."nixbox" = { };
        secondary.machines."nixworker" = { };
        secondary.machines."desktop" = { };
      };
    };
  };
}
