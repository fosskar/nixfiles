{ pkgs, ... }:
{
  services.ollama = {
    enable = true;
    acceleration = "rocm";
  };

  environment.systemPackages = with pkgs; [ oterm ];
}
