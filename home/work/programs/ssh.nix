_: {
  programs.ssh = {
    enable = true;
    extraConfig = ''
      Include ~/.ssh/extra_config
    '';
  };
}
