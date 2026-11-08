# ucode with the uci module, which nixpkgs leaves out; runs apply.uc in the flake check
{ pkgs }:
pkgs.ucode.overrideAttrs (old: {
  buildInputs = old.buildInputs ++ [
    pkgs.uci
    pkgs.libubox
  ];
  cmakeFlags = (old.cmakeFlags or [ ]) ++ [ "-DUCI_SUPPORT=ON" ];
})
