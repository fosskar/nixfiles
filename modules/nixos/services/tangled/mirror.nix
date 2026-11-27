{
  # mirrors github repos into the local tangled knot. the knot checks ssh keys
  # per account, so the public key must be added to the tangled account with
  # auth usage, which lets it push to every repo of that account
  flake.modules.nixos.tangledMirror =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      repos = [ "nixfiles" ];
      stateDir = "/var/lib/tangled-mirror";
      sshCommand = lib.concatStringsSep " " [
        "ssh"
        "-i $CREDENTIALS_DIRECTORY/ssh-key"
        "-o IdentitiesOnly=yes"
        "-o StrictHostKeyChecking=accept-new"
        "-o UserKnownHostsFile=${stateDir}/known_hosts"
      ];
    in
    {
      clan.core.vars.generators.tangled-mirror = {
        files.private-key.secret = true;
        files.public-key.secret = false;
        runtimeInputs = [ pkgs.openssh ];
        script = ''
          ssh-keygen -t ed25519 -N "" -C tangled-mirror -f "$out/private-key"
          mv "$out/private-key.pub" "$out/public-key"
        '';
      };

      systemd.services.tangled-mirror = {
        description = "Mirror GitHub repositories into the tangled knot";
        after = [
          "network-online.target"
          "knot-rs.service"
        ];
        wants = [ "network-online.target" ];
        path = [
          pkgs.git
          pkgs.openssh
        ];
        environment.HOME = stateDir;
        script = ''
          export GIT_SSH_COMMAND="${sshCommand}"
        ''
        + lib.concatMapStrings (name: ''
          repo="${stateDir}/${name}.git"
          [ -d "$repo" ] || git init --bare --quiet "$repo"
          git -C "$repo" fetch --prune https://github.com/fosskar/${name}.git \
            '+refs/heads/*:refs/heads/*' '+refs/tags/*:refs/tags/*'
          git -C "$repo" push --prune ssh://git@127.0.0.1:2222/fosskar.eu/${name} \
            '+refs/heads/*:refs/heads/*' '+refs/tags/*:refs/tags/*'
        '') repos;
        serviceConfig = {
          Type = "oneshot";
          DynamicUser = true;
          StateDirectory = "tangled-mirror";
          LoadCredential = [
            "ssh-key:${config.clan.core.vars.generators.tangled-mirror.files.private-key.path}"
          ];
        };
      };

      systemd.timers.tangled-mirror = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "*:0/15";
          Persistent = true;
        };
      };
    };
}
