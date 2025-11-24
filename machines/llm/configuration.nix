{ mylib, ... }:
{
  imports = [
    ../../modules/lxc
    ../../modules/monitoring
    ../../modules/shared
  ]
  ++ (mylib.scanPaths ./. {
    exclude = [
      "ipex-llm.nix"
      "tika.nix"
    ];
  });

  nixpkgs.hostPlatform = "x86_64-linux";
}
