{pkgs, ...}: {
  users.users.simon = {
    initialPassword = "123";
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [
      "audio"
      "corectrl"
      "input"
      "libvirtd"
      "networkmanager"
      "video"
      "wheel"
    ];
  };
}
