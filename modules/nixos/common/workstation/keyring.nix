{
  flake.modules.nixos.workstation =
    {
      lib,
      pkgs,
      ...
    }:
    let
      # keyring tpm auto-unlock setup (one-time, as user): open the keyring once, then
      #   echo -n 'YOUR_KEYRING_PASSWORD' | systemd-creds encrypt --user - ~/.config/keyring-tpm/password.cred
      # the first unlock creates the login keyring with the credential password
      # refs: gnome-keyring-daemon(1) --unlock, mic92 dotfiles niri/kwallet-tpm
      keyring-tpm-unlock = pkgs.writeShellScriptBin "keyring-tpm-unlock" ''
        if [ "$#" -ne 1 ]; then
          echo "usage: keyring-tpm-unlock <credential-file>" >&2
          exit 1
        fi
        cred="$1"
        if [ ! -f "$cred" ]; then
          echo "credential file not found: $cred" >&2
          exit 1
        fi

        # foreground so this unit owns the daemon and the bus name; --replace
        # absorbs an instance that dbus activation raced in earlier
        exec ${pkgs.gnome-keyring}/bin/gnome-keyring-daemon \
          --foreground --replace --components=secrets --unlock \
          < <(${pkgs.systemd}/bin/systemd-creds decrypt --user "$cred" -)
      '';

      keyring-unlock-verify = pkgs.writeShellScript "keyring-unlock-verify" ''
        # fail the unit unless the default collection really reports unlocked
        for _ in $(seq 1 100); do
          locked=$(${pkgs.systemd}/bin/busctl --user get-property \
            org.freedesktop.secrets \
            /org/freedesktop/secrets/aliases/default \
            org.freedesktop.Secret.Collection Locked 2>/dev/null) || true
          if [ "$locked" = "b false" ]; then
            exit 0
          fi
          sleep 0.2
        done
        echo "login keyring did not unlock" >&2
        exit 1
      '';

      # dbus activation of the secrets names must start this unit, not a bare
      # --start daemon: a bare instance wins the bus name race at login, has no
      # control directory (invisible to --replace) and prompts for the password.
      # hiPrio beats gnome-keyring's own service files in the system-path merge;
      # dbus scans system-path before package service dirs.
      keyring-dbus-activation = lib.hiPrio (
        pkgs.runCommand "keyring-dbus-activation" { } ''
          mkdir -p $out/share/dbus-1/services
          for name in org.freedesktop.secrets org.gnome.keyring org.freedesktop.impl.portal.Secret; do
            cat > $out/share/dbus-1/services/$name.service <<EOF
          [D-BUS Service]
          Name=$name
          Exec=/run/wrappers/bin/gnome-keyring-daemon --start --foreground --components=secrets
          SystemdService=keyring-tpm-unlock.service
          EOF
          done
        ''
      );
    in
    {
      # gnome-keyring provides org.freedesktop.secrets; unlock at session start
      # through tpm-sealed credentials instead of pam
      services.gnome.gnome-keyring.enable = true;
      programs.seahorse.enable = true;

      xdg.portal.config.niri."org.freedesktop.impl.portal.Secret" = lib.mkForce "gnome-keyring";

      environment.systemPackages = [
        keyring-tpm-unlock
        keyring-dbus-activation
      ];

      systemd.user.services.keyring-tpm-unlock = {
        description = "run login keyring unlocked with tpm-sealed credentials";
        after = [ "dbus.socket" ];
        # startup completes only once ExecStartPost sees the keyring unlocked,
        # so session apps that ask for secrets do not race the unlock and get a
        # password prompt
        before = [ "graphical-session.target" ];
        wantedBy = [ "graphical-session.target" ];
        serviceConfig = {
          Type = "exec";
          # a dbus-activated --start instance has no control directory, which
          # makes it invisible to --replace; kill strays so this unit's daemon
          # owns the bus name (no-op at session start, nothing runs yet)
          ExecStartPre = "-${pkgs.procps}/bin/pkill -u %u -f gnome-keyring-daemon";
          ExecStart = "${keyring-tpm-unlock}/bin/keyring-tpm-unlock %h/.config/keyring-tpm/password.cred";
          ExecStartPost = "${keyring-unlock-verify}";
          Restart = "on-failure";
          RestartSec = 2;
        };
      };
    };
}
