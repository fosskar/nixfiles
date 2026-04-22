{
  flake.modules.nixos.workstation =
    {
      lib,
      pkgs,
      ...
    }:
    let
      # kwallet tpm auto-unlock setup (one-time, as user):
      #   1) create/open kwallet once so salt exists
      #   2) seal wallet password in user creds store:
      #      echo -n 'YOUR_KWALLET_PASSWORD' | systemd-creds encrypt --user - ~/.config/kwallet-tpm/password.cred
      #
      # refs/credits:
      # - mic92 dotfiles: nixosModules/niri/kwallet-tpm
      # - autokdewallet: https://github.com/Himalian/autokdewallet
      pythonEnv = pkgs.python3.withPackages (ps: [ ps.dbus-python ]);

      kwallet-tpm-unlock = pkgs.writeScriptBin "kwallet-tpm-unlock" ''
        #!${pythonEnv}/bin/python3
        from __future__ import annotations

        import hashlib
        import subprocess
        import sys
        from pathlib import Path

        import dbus

        iterations = 50000
        key_size = 56
        hash_algo = "sha512"

        salt_path = Path.home() / ".local/share/kwalletd/kdewallet.salt"


        def load_salt(path: Path = salt_path) -> bytes:
          if not path.exists():
            raise FileNotFoundError(f"salt file not found: {path}")
          return path.read_bytes()


        def decrypt_password(cred_file: Path) -> bytes:
          result = subprocess.run(
            ["systemd-creds", "decrypt", "--user", str(cred_file), "-"],
            capture_output=True,
            check=True,
          )
          return result.stdout.strip()


        def derive_hash(password: bytes, salt: bytes) -> bytes:
          return hashlib.pbkdf2_hmac(hash_algo, password, salt, iterations, key_size)


        def pam_open_wallet(password_hash: bytes) -> bool:
          try:
            bus = dbus.SessionBus()
            proxy = bus.get_object("org.kde.kwalletd6", "/modules/kwalletd6")
            interface = dbus.Interface(proxy, "org.kde.KWallet")
            interface.pamOpen("kdewallet", dbus.ByteArray(password_hash), 0)
          except dbus.DBusException as e:
            print(f"dbus error unlocking wallet: {e}", file=sys.stderr)
            return False
          else:
            return True


        def main() -> None:
          if len(sys.argv) != 2:
            print(f"usage: {sys.argv[0]} <credential-file>", file=sys.stderr)
            sys.exit(1)

          cred_file = Path(sys.argv[1])
          if not cred_file.exists():
            print(f"credential file not found: {cred_file}", file=sys.stderr)
            sys.exit(1)

          salt = load_salt()
          password = decrypt_password(cred_file)
          password_hash = derive_hash(password, salt)

          if not pam_open_wallet(password_hash):
            sys.exit(1)


        if __name__ == "__main__":
          main()
      '';
    in
    {
      # gnome-keyring - secret storage for apps using freedesktop secrets api
      # browsers and many apps use this for credential storage
      # services.gnome.gnome-keyring.enable = lib.mkDefault true;

      # seahorse - gui for managing keyring secrets and keys
      # programs.seahorse.enable = lib.mkDefault true;

      # unlock keyring on login for greeters/lock screens
      # security.pam.services = {
      #   login.enableGnomeKeyring = lib.mkDefault true;
      #   greetd.enableGnomeKeyring = lib.mkIf config.services.greetd.enable true;
      #   hyprlock.enableGnomeKeyring = lib.mkIf config.programs.hyprlock.enable true;
      #   cosmic-greeter.enableGnomeKeyring = lib.mkIf config.services.displayManager.cosmic-greeter.enable true;
      # };

      # kwallet + tpm unlock
      services.gnome.gnome-keyring.enable = lib.mkForce false;
      programs.seahorse.enable = lib.mkForce false;

      environment.systemPackages = [
        pkgs.kdePackages.kwallet
        pkgs.kdePackages.kwalletmanager
        kwallet-tpm-unlock
      ];

      security.pam.services.greetd.kwallet.enable = false;

      systemd.user.services.kwallet-tpm-unlock = {
        description = "unlock kwallet using tpm-sealed credentials";
        after = [
          "dbus.socket"
          "graphical-session.target"
        ];
        wantedBy = [ "graphical-session.target" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${kwallet-tpm-unlock}/bin/kwallet-tpm-unlock %h/.config/kwallet-tpm/password.cred";
          Restart = "on-failure";
          RestartSec = 2;
          RestartMode = "direct";
        };
      };
    };
}
