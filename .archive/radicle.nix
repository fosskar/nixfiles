{
  config,
  pkgs,
  ...
}:
{
  # ssh key generation via clan vars
  clan.core.vars.generators.radicle = {
    files.ssh-private-key = {
      secret = true;
      owner = "radicle";
    };
    files.ssh-public-key = {
      secret = false;
    };
    runtimeInputs = with pkgs; [ openssh ];
    script = ''
      ssh-keygen -t ed25519 -N "" -f $out/ssh-private-key -C "radicle@hm-nixbox"
      ssh-keygen -y -f $out/ssh-private-key > $out/ssh-public-key
    '';
  };

  services.radicle = {
    enable = true;
    checkConfig = false; # TODO: fix settings format
    privateKeyFile = config.clan.core.vars.generators.radicle.files.ssh-private-key.path;
    publicKey = config.clan.core.vars.generators.radicle.files.ssh-public-key.path;

    httpd = {
      enable = true;
      listenAddress = "127.0.0.1";
      listenPort = 8091;
    };

    node = {
      openFirewall = false;
      listenAddress = "127.0.0.1";
      listenPort = 8776;
    };

    #ci = {
    #  broker.enable = true;
    #  adapters.native.instances.default = {
    #    enable = true;
    #  };
    #};

    settings = {
      preferredSeeds = [
        "z6MkrLMMsiPWUcNPHcRajuMi9mDfYckSoJyPwwnknocNYPm7@seed.radicle.xyz:8776"
        "z6Mkmqogy2qEM2ummccUthFEaaHvyYmYBYh3dbe9W4ebScxo@seed.radicle.garden:8776"
      ];
      node = {
        alias = "hm-nixbox";
        seedingPolicy = {
          default = "allow";
          scope = "followed";
        };
        follow = [ ];
      };
      web = {
        pinned = {
          repositories = [
          ];
        };
      };
    };
  };
}
