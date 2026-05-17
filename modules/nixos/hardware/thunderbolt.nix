{
  flake.modules.nixos.thunderbolt = _: {
    services = {
      hardware.bolt.enable = true;

      udev.extraRules = ''
        # keep Intel Thunderbolt controllers powered to avoid dock disconnects
        ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x8086", ATTR{class}=="0x088000", ATTR{power/control}="on"
      '';
    };
  };
}
