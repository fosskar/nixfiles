{ ... }:
{
  # audiobookshelf - audiobook and podcast server
  services.audiobookshelf = {
    enable = true;
    host = "10.0.0.111";
    port = 13378;
    openFirewall = true;
    user = "audiobookshelf";
    group = "media";
  };
}
