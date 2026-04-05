{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.proton-pass-cli ];
  environment.sessionVariables.PROTON_PASS_LINUX_KEYRING = "dbus";
}
