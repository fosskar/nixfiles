{ pkgs, ... }:
{
  programs.zsh.plugins = [
    {
      name = "zsh-nix-shell";
      src = "${pkgs.zsh-nix-shell}/share/zsh-nix-shell/nix-shell.plugin.zsh";
    }
    {
      name = "fast-syntax-highlighting";
      src = "${pkgs.zsh-fast-syntax-highlighting}/share/zsh/site-functions";
    }
    {
      name = "zsh-autosuggestions";
      src = "${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh";
    }
  ];
}
