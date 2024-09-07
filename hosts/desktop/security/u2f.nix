{ pkgs, ... }:
{
  services = {
    pcscd.enable = true;
    udev.packages = [ pkgs.yubikey-personalization ];
  };

  security.pam = {
    u2f = {
      enable = true;
      settings = {
        cue = true;
        control = "sufficient";
        interactive = true;
      };
    };
    services = {
      login.u2fAuth = true;
      greetd.u2fAuth = true;
      hyprlock.u2fAuth = true;
    };
  };

  environment.systemPackages = with pkgs; [
    yubikey-manager
    yubikey-manager-qt
    yubikey-personalization
    yubikey-personalization-gui
    age-plugin-yubikey
  ];
}
