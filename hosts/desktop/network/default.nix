_: {
  imports = [
    ./firewall.nix
    ./networkmanager.nix
    ./openssh.nix
    ./optimize.nix
    ./resolved.nix
    ./tailscale.nix
  ];

  networking = {
    hostName = "nixos";
  };
}
