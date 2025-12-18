{ inputs, ... }:
{
  imports = [ inputs.tangled.nixosModules.knot ];

  services.tangled.knot = {
    enable = true;
    stateDir = "/var/lib/tangled-knot";

    server = {
      hostname = "knot.simonoscar.me";
      owner = "did:plc:an4f4yxu6sfuhvc7ih56dyl2";
      listenAddr = "127.0.0.1:5555"; # behind reverse proxy
    };
  };
}
