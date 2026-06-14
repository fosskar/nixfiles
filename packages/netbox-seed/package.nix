{ pkgs }:

pkgs.writeShellApplication {
  name = "netbox-seed";
  runtimeInputs = [ pkgs.openssh ];
  text = ''
    exec ssh nixbox.s 'sudo -u netbox netbox-manage shell' < ${./seed.py}
  '';
}
