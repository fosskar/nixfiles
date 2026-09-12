{
  flake.modules.nixos.usbguard = _: {
    services.usbguard = {
      enable = true;
      dbus.enable = true;

      # internal keyboard, touchpad, camera and fingerprint reader sit on the
      # usb bus; blocking them before anyone can authorize would lock the
      # machine out, so whatever is attached when the daemon starts stays
      presentDevicePolicy = "allow";
      presentControllerPolicy = "allow";

      implicitPolicyTarget = "block";
      insertedDevicePolicy = "apply-policy";

      IPCAllowedGroups = [ "wheel" ];

      # setting rules moves the policy into the store, so `usbguard
      # allow-device -p` cannot write drift back to /var/lib/usbguard;
      # hot-plugged devices outside this list need a per-session
      # `usbguard allow-device <id>`
      rules = ''
        allow id 1050:*
      '';
    };
  };
}
