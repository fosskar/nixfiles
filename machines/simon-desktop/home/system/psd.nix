_: {
  services.psd = {
    enable = true;
    browsers = [
      "firefox"
      "brave"
      "zen"
    ];
  };

  # custom browser definitions (psd doesn't support these natively)
  home.file.".config/psd/browsers/brave".text = ''
    DIRArr[0]="$XDG_CONFIG_HOME/BraveSoftware/Brave-Browser"
    PSNAME="brave"
  '';

  home.file.".config/psd/browsers/zen".text = ''
    DIRArr[0]="$HOME/.zen"
    PSNAME="zen"
    check_suffix=1
  '';
}
