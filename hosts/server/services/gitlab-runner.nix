{ config, lib, ... }:
{
  services.gitlab-runner = {
    enable = true;
    #settings = "";
    clear-docker-cache.enable = true;
    services.nixos-gitlab-runner = {
      #description = "gitlab-runner on nixos server with podman"; # doesnt work with auth-token only UI
      authenticationTokenConfigFile = config.sops.secrets.Z2l0bGFiLXJ1bm5lci1yZWdpc3RyYXRpb24.path;
      dockerImage = "alpine";
      #tagList = [ "nixos" ]; # doesnt work with auth-token only UI
      #runUntagged = false; # doesnt work with auth-token only UI
      requestConcurrency = 1;
      #protected = false; # doesnt work with auth-token only UI
      limit = 2;
      executor = "docker";
      environmentVariables = {
        FF_NETWORK_PER_BUILD = "1";
      };
      dockerExtraHosts = [ "unix:///run/podman/podman.sock" ];
      dockerVolumes = [ ]; # bind podman socket here
      dockerDisableCache = false;
      cloneUrl = "https://gitlab.com";
      buildsDir = "/var/lib/gitlab-runner/builds";
    };
  };
  systemd.services = lib.mkIf config.virtualisation.podman.enable {
    gitlab-runner = {
      after = [ "podman.service" ];
      requires = [ "podman.service" ];
      serviceConfig.SupplementaryGroups = [ "podman" ];
    };
  };
}
