{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [ toybox ];
}
