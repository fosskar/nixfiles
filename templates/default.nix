{ self, ... }:
{
  devshell = {
    description = "Flake devshell template";
    path = "${self}/templates/devshell";
  };

  go = {
    description = "Flake GO template";
    path = "${self}/templates/go";
  };

  module = {
    description = "NixOS module template";
    path = "${self}/templates/module";
  };

  overlay = {
    description = "NixOS overlay template";
    path = "${self}/templates/overlay";
  };

  node = {
    description = "Flake node template";
    path = "${self}/templates/node";
  };

  python = {
    description = "Flake Python template";
    path = "${self}/templates/python";
  };

  rust = {
    description = "Flake Rust template";
    path = "${self}/templates/rust";
  };
}
