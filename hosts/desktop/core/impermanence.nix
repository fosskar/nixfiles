{ inputs, ... }:
{
  imports = [ inputs.impermanence.nixosModules.impermanence ];

  # Impermanence configuration based on https://www.notashelf.dev/posts/impermanence
  environment.persistence."/persist" = {
    enable = true;
    hideMounts = true;
    directories = [
      # System directories
      "/etc/nixos"
      "/etc/nix"
      "/etc/NetworkManager/system-connections"
      "/etc/secureboot"
      "/run/secrets.d/"
      "/var/db/sudo"
      "/var/lib/bluetooth"
      "/var/lib/nixos"
      "/var/lib/pipewire"
      "/var/lib/sops-nix/"
      "/var/lib/systemd/coredump"
      "/var/cache/tailscale"
      "/var/lib/tailscale"
    ];
    files = [
      # Essential system files
      "/etc/machine-id"

      # SSH host keys (critical!)
      #"/etc/ssh/ssh_host_ed25519_key"
      #"/etc/ssh/ssh_host_ed25519_key.pub"
      #"/etc/ssh/ssh_host_rsa_key"
      #"/etc/ssh/ssh_host_rsa_key.pub"
    ];
  };
}
