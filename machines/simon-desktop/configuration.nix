{
  self,
  mylib,
  ...
}:
{
  imports = [
    self.modules.nixos.gaming
    self.modules.nixos.dmsGreeter
    self.modules.nixos.nostrChat
    self.modules.nixos.hyprland
    self.modules.nixos.betaflight
    self.modules.nixos.wooting
    self.modules.nixos.arctisNovaProWireless
    self.modules.nixos.amdGpu
    self.modules.nixos.amdCpu
    self.modules.nixos.btrfs
    self.modules.nixos.systemdBoot
    self.modules.nixos.docker
    self.modules.nixos.podman
    self.modules.nixos.preservation
    self.modules.nixos.agentDesktop
    self.modules.nixos.arbor
    self.modules.nixos.t3code
  ]
  ++ mylib.scanPaths ./. { };

  preservation.rollback = {
    type = "btrfs";
    deviceLabel = "nixos";
  };
}
