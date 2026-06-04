{
  self,
  mylib,
  inputs,
  ...
}:
{
  imports = [
    inputs.spaces.nixosModules.pi-chat
    self.modules.nixos.gaming
    self.modules.nixos.greetd
    self.modules.nixos.betaflight
    self.modules.nixos.wooting
    self.modules.nixos.arctisNovaProWireless
    self.modules.nixos.amdGpu
    self.modules.nixos.amdCpu
    self.modules.nixos.systemdBoot
    self.modules.nixos.tunedPpd
    self.modules.nixos.deepSleep
    self.modules.nixos.docker
    self.modules.nixos.podman
    self.modules.nixos.agentDesktop
    self.modules.nixos.arbor
    self.modules.nixos.limux
    self.modules.nixos.t3code
    self.modules.nixos.yubikeyGpgSsh
    self.modules.nixos.yubikeyU2f
  ]
  ++ mylib.scanPaths ./. { };

  services.pi-chat = {
    enable = true;
    llmUrl = "https://llama-cpp.nx3.eu";
    defaultModel = "qwen3_6-35b-a3b";
  };
  services.llama-swap.enable = false;
}
