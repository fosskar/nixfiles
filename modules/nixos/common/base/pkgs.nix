{
  flake.modules.nixos.base =
    { lib, pkgs, ... }:
    {
      environment = {
        defaultPackages = lib.mkForce [ ]; # no extra default packages are installed
        systemPackages = [
          pkgs.coreutils
          pkgs.curl
          pkgs.dnsutils
          pkgs.fd
          pkgs.findutils
          pkgs.lsof
          pkgs.gitMinimal
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
