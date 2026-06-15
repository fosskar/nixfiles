{ inputs }:
let
  inherit (inputs.nixpkgs) lib;
  nflib = import ../lib { inherit lib; };
in
map (p: import p { inherit inputs; }) (nflib.scanPaths ./. { })
