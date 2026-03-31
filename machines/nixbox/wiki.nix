{ inputs, ... }:
{
  nixfiles.caddy.vhosts.wiki = {
    root = inputs.wiki.packages.x86_64-linux.default;
  };
}
