{ pkgs, ... }:
let
  ttl = 900;

  # phone-session.age holds a software age key (line 1) and ssh key (rest),
  # encrypted to the phone and yubikey age recipients. one fingerprint
  # unlocks both for 15 minutes: the phone itself asks on every single use
  phone-session = pkgs.writeShellApplication {
    name = "phone-session";
    runtimeInputs = [
      pkgs.age
      pkgs.coreutils
      pkgs.keyutils
      pkgs.local.phonetpm
      pkgs.openssh
      pkgs.util-linux
    ];
    text = ''
      dir=$XDG_RUNTIME_DIR/phone-session
      export SSH_AUTH_SOCK=$dir/ssh-agent.sock

      unlock() {
        exec 9>"$dir/lock"
        flock 9
        if keyctl search @u user phone-session >/dev/null 2>&1 && ssh-add -l >/dev/null 2>&1; then
          return
        fi
        plain=$(PHONETPM_DESCRIPTION="unlock the nixworker session for $((${toString ttl} / 60)) min" \
          age --decrypt --identity <(phonetpm identity age) ${./phone-session.age})
        id=$(head -n 1 <<<"$plain" | keyctl padd user phone-session @u)
        keyctl timeout "$id" ${toString ttl}
        tail -n +2 <<<"$plain" | ssh-add -q -t ${toString ttl} -
      }

      case "''${1-}" in
        unlock) unlock ;;
        age-key)
          unlock >&2
          keyctl pipe "$(keyctl search @u user phone-session)"
          ;;
        *)
          echo "usage: phone-session unlock|age-key" >&2
          exit 2
          ;;
      esac
    '';
  };
in
{
  home.packages = [ phone-session ];

  # connecting unlocks the session first, then reaches the agent below
  systemd.user.sockets.phone-session = {
    Unit.Description = "ssh-agent socket that unlocks the phone session";
    Socket = {
      ListenStream = "%t/phone-session/agent.sock";
      SocketMode = "0600";
      DirectoryMode = "0700";
      Accept = true;
    };
    Install.WantedBy = [ "sockets.target" ];
  };

  systemd.user.services."phone-session@" = {
    Unit.Description = "unlock the phone session and relay to its ssh-agent";
    Service = {
      StandardInput = "socket";
      StandardOutput = "socket";
      StandardError = "journal";
      ExecStart = toString (
        pkgs.writeShellScript "phone-session-relay" ''
          ${phone-session}/bin/phone-session unlock >&2
          exec ${pkgs.socat}/bin/socat STDIO UNIX-CONNECT:"$XDG_RUNTIME_DIR/phone-session/ssh-agent.sock"
        ''
      );
    };
  };

  systemd.user.services.phone-session-agent = {
    Unit = {
      Description = "ssh-agent holding the unlocked phone session key";
      Requires = [ "phone-session.socket" ];
      After = [ "phone-session.socket" ];
    };
    Service = {
      # a killed agent leaves its socket behind and ssh-agent refuses to bind
      ExecStartPre = "${pkgs.coreutils}/bin/rm -f %t/phone-session/ssh-agent.sock";
      ExecStart = "${pkgs.openssh}/bin/ssh-agent -D -a %t/phone-session/ssh-agent.sock";
    };
    Install.WantedBy = [ "default.target" ];
  };
}
