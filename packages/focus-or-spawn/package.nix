{
  lib,
  buildGoModule,
}:
buildGoModule {
  pname = "focus-or-spawn";
  version = "0.1.0";

  src = ./focus-or-spawn;

  vendorHash = null;

  env.CGO_ENABLED = 0;
  ldflags = [
    "-s"
    "-w"
  ];

  meta = {
    description = "focus a niri or umbriel window by exact app-id, or spawn the command and focus the new window";
    license = lib.licenses.publicDomain;
    mainProgram = "focus-or-spawn";
    platforms = lib.platforms.linux;
  };
}
