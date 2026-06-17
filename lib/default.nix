# one file per helper; merged into the nflib attrset
args: import ./scan-paths.nix args // import ./gatus-endpoint.nix args
