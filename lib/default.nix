# one file per helper; merged into the nflib attrset
args:
import ./scan-paths.nix args // import ./scan-flake-modules.nix args
