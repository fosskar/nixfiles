{ inputs, config, ... }:
{
  imports = [
    inputs.authentik-nix.nixosModules.default
  ];
  services.authentik = {
    enable = true;
    # The environmentFile needs to be on the target host!
    # Best use something like sops-nix or agenix to manage it
    environmentFile = config.age.secrets.envs.path;
    settings = {
      nginx.enable = false;
      #email = {
      #  host = "smtp.example.com";
      #  port = 587;
      #  username = "authentik@example.com";
      #  use_tls = true;
      #  use_ssl = false;
      #  from = "authentik@example.com";
      #};
      disable_startup_analytics = true;
      avatars = "initials";
    };
  };
  networking.firewall.allowedTCPPorts = [
    9091 # authelia
    9000 # authentik http
    9443 # authentik https
  ];
}
