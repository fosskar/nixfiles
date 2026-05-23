{
  flake.modules.nixos.base =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.foot.terminfo
        pkgs.kitty.terminfo
        pkgs.wezterm.terminfo
        (pkgs.runCommand "ghostty-terminfo"
          {
            nativeBuildInputs = [ pkgs._7zz ];
          }
          ''
            7zz -snld x ${pkgs.ghostty-bin.src}
            mkdir -p $out/share/terminfo/{g,x}
            cp -r Ghostty.app/Contents/Resources/terminfo/67/ghostty $out/share/terminfo/g
            cp -r Ghostty.app/Contents/Resources/terminfo/78/xterm-ghostty $out/share/terminfo/x
          ''
        )
      ];
    };
}
