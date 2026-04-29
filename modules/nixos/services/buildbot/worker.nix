{
  flake.modules.nixos.buildbotWorker =
    {
      config,
      inputs,
      lib,
      ...
    }:
    {
      imports = [ inputs.buildbot-nix.nixosModules.buildbot-worker ];

      config = {
        services.buildbot-nix.worker = {
          enable = true;
          masterUrl = lib.mkDefault "tcp:host=localhost:port=9989";
          workers = lib.mkDefault 16;
          workerPasswordFile = config.clan.core.vars.generators.buildbot-master.files."worker-password".path;
        };
      };
    };
}
