{
  flake.modules.nixos.noctalia-greeter =
    {
      inputs,
      pkgs,
      ...
    }:
    let
      # upstream ships a relative exec.path; polkit needs the absolute binary path
      # so noctalia-shell's pkexec sync authorizes against this action.
      noctalia-greeter =
        inputs.noctalia-greeter.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs
          (old: {
            postInstall = (old.postInstall or "") + ''
              substituteInPlace $out/share/polkit-1/actions/org.noctalia.greeter.apply-appearance.policy \
                --replace-fail '>noctalia-greeter-apply-appearance<' \
                '>'"$out"'/bin/noctalia-greeter-apply-appearance<'
            '';
          });
    in
    {
      imports = [ inputs.noctalia-greeter.nixosModules.default ];

      programs.noctalia-greeter = {
        enable = true;
        package = noctalia-greeter;
      };

      # greeter state (synced appearance, remembered scheme) lives here.
      preservation.preserveAt."/persist".directories = [
        {
          directory = "/var/lib/noctalia-greeter";
          user = "greeter";
          group = "greeter";
        }
      ];
    };
}
