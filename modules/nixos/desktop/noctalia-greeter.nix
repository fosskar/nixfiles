{
  flake.modules.nixos.noctalia-greeter =
    {
      config,
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
      services.greetd = {
        enable = true;
        settings.default_session = {
          # pin niri as the default session (overrides last-used at open).
          command = "${noctalia-greeter}/bin/noctalia-greeter-session -- --session niri";
          user = "greeter";
        };
      };

      # registers the apply-appearance polkit action plus binary so noctalia-shell
      # (Settings -> Noctalia Greeter -> Sync Now) can sync wallpaper/palette.
      environment.systemPackages = [ noctalia-greeter ];

      # the greeter scans the hardcoded /usr/share/wayland-sessions; point it at
      # the wayland session desktop files collected by the display manager.
      systemd.tmpfiles.settings."10-noctalia-greeter" = {
        "/var/lib/noctalia-greeter".d = {
          user = "greeter";
          group = "greeter";
          mode = "0755";
        };
        "/usr/share/wayland-sessions".L.argument =
          "${config.services.displayManager.sessionData.desktops}/share/wayland-sessions";
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
