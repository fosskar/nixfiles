{
  flake.modules.nixos.base =
    { lib, pkgs, ... }:
    {
      environment = {
        defaultPackages = lib.mkForce [ ]; # no extra default packages are installed
        systemPackages = [
          pkgs.curl
          pkgs.dnsutils
          pkgs.fd
          pkgs.lsof
          pkgs.jq
          pkgs.openssl
          pkgs.tcpdump
          pkgs.nmap
          pkgs.wget
          pkgs.unzip
          pkgs.ripgrep
          pkgs.rsync
          pkgs.yq-go
          pkgs.pciutils
          pkgs.nvme-cli
          pkgs.smartmontools
        ];
      };
    };
}
