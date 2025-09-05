_: {
  programs.zellij = {
    enable = true;
    enableFishIntegration = true;
    enableZshIntegration = true;
    themes = {
      default = ''
        bg "#ffffff";
        fg "#eeeeee";
        red "#ed333b";
        green "#2BBF6E";
        blue "#3584e4";
        yellow "#e5a50a";
        magent "#9141ac";
        orange "#ff7800";
        cyan "#2BBF6E";
        black "#171717";
        white "#eeeeee";
      '';
    };
  };
}
