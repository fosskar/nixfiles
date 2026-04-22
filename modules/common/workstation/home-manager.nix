{
  flake.modules.nixos.workstation =
    {
      config,
      lib,
      inputs,
      pkgs,
      ...
    }:
    {
      imports = [
        inputs.home-manager.nixosModules.home-manager
      ];

      home-manager = {
        verbose = true;
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = null;
        backupCommand = pkgs.writeShellScript "hm-backup" ''
          src="$1"
          ts="$(date +%Y%m%d%H%M%S)"
          dst="$src.hm.$ts"
          i=0
          while [ -e "$dst" ]; do
            i=$((i+1))
            dst="$src.hm.$ts.$i"
          done
          mv -- "$src" "$dst"
        '';

        extraSpecialArgs = {
          inherit inputs;
          mylib = import "${inputs.self}/lib" {
            inherit lib;
            inherit (inputs) self;
          };
        };

        sharedModules = [
          {
            nix.package = lib.mkForce config.nix.package;
            programs.home-manager.enable = true;

            manual = {
              manpages.enable = false;
              html.enable = false;
              json.enable = false;
            };
            programs.man.enable = true;
          }
        ];
      };
    };
}
