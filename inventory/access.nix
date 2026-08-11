{
  self,
  config,
  ...
}:
{
  flake.clan.inventory.instances = {
    emergency-access = {
      module = {
        name = "emergency-access";
        input = "clan-core";
      };
      roles.default.tags = [ "nixos" ];
    };

    sshd = {
      module = {
        name = "sshd";
        input = "clan-core";
      };
      roles.server = {
        tags = [ "all" ];
        settings = {
          authorizedKeys = {
            simon = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID3AsDe157avF+iFa1TavZHwjDpugyePDqJ6gaRNzGIA openpgp:0xDA6712BE";
            simon-piv = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBG7nahd/01skftk7ujmj2F2T8vzqUH/UWqQViSz7XEVaQbPIEYTwR6V/TpFx54wKlzJA75BDV+fHIBJsmhNzd3U=";
          };
          certificate.searchDomains = [
            "lan"
            "local"
            config.flake.domains.local
          ];
        };
      };
      roles.client.tags = [ "all" ];
    };

    root-user = {
      module = {
        name = "users";
        input = "clan-core";
      };
      roles.default.tags = [ "all" ];
      roles.default.settings = {
        user = "root";
        prompt = true;
        share = true;
      };
    };

    simon-user = {
      module = {
        name = "users";
        input = "clan-core";
      };

      roles.default = {
        machines."desktop" = { };
        machines."lpt-titan" = { };
        settings = {
          user = "simon";
          share = true;
          groups = [
            "wheel"
            "input"
          ];
        };
        extraModules = [ "${self}/users/simon" ];
      };
    };

    # nixworker's headless dev user: username simon (ssync session identity
    # needs the same user/home path on every peer), but its own per-machine
    # password — deliberately NOT share=true like simon-user above.
    workspace-user = {
      module = {
        name = "users";
        input = "clan-core";
      };

      roles.default = {
        machines."nixworker" = { };
        settings = {
          user = "simon";
          groups = [ "wheel" ];
          openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID3AsDe157avF+iFa1TavZHwjDpugyePDqJ6gaRNzGIA openpgp:0xDA6712BE"
            "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBG7nahd/01skftk7ujmj2F2T8vzqUH/UWqQViSz7XEVaQbPIEYTwR6V/TpFx54wKlzJA75BDV+fHIBJsmhNzd3U="
          ];
        };
        extraModules = [ "${self}/users/workspace" ];
      };
    };

    clan-cache = {
      module = {
        name = "trusted-nix-caches";
        input = "clan-core";
      };
      roles.default.tags = [ "all" ];
    };
  };
}
