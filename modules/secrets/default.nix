{
  inputs,
  lib,
  config,
  ...
}:
let
  # derive machine name from clan's settings or fallback to hostName
  machineName = config.clan.core.settings.machine.name or config.networking.hostName;

  # read ssh host key from clan vars if it exists, otherwise fall back to host.pub
  clanVarsKeyPath = "${inputs.self}/vars/per-machine/${machineName}/openssh/ssh.id_ed25519.pub/value";
  manualHostPubKeyPath = "${inputs.self}/machines/${machineName}/host.pub";

  hostPubKey =
    if builtins.pathExists clanVarsKeyPath then
      builtins.readFile clanVarsKeyPath
    else if builtins.pathExists manualHostPubKeyPath then
      builtins.readFile manualHostPubKeyPath
    else
      null;

  generatedSecretsDir = "${inputs.self}/secrets/generated/${machineName}";
  localStorageDir = "${inputs.self}/secrets/rekeyed/${machineName}";
in
{
  imports = [
    inputs.agenix.nixosModules.default
    inputs.agenix-rekey.nixosModules.default
  ];

  # centralised agenix-rekey defaults
  age = {
    #ageBin = "PATH=$PATH:${lib.makeBinPath [ pkgs.age-plugin-yubikey ]} ${pkgs.rage}/bin/rage";
    rekey = {
      storageMode = lib.mkDefault "local";
      hostPubkey = lib.mkIf (hostPubKey != null) (lib.mkDefault hostPubKey);
      generatedSecretsDir = lib.mkDefault generatedSecretsDir;
      localStorageDir = lib.mkDefault localStorageDir;
      masterIdentities = [
        "${inputs.nixsecrets}/agenix/yubikey-identities/age-yubikey-desktop.pub"
        "${inputs.nixsecrets}/agenix/yubikey-identities/age-yubikey-go.pub"
      ];
    };
  };
}
