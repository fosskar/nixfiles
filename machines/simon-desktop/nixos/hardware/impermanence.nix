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
  # Fix home directory ownership issues
  systemd.tmpfiles.rules = [
    "d /home/simon 0755 simon users -"
    "d /home/simon/.cache 0755 simon users -"
    "d /home/simon/.config 0755 simon users -"
    "d /home/simon/.local 0755 simon users -"
    "d /home/simon/.local/share 0755 simon users -"
    "Z /home/simon - simon users - -" # Fix ownership recursively
  ];
}
