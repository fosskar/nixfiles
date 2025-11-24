{
  lib,
  buildGoModule,
  fetchFromGitHub,
  makeWrapper,
  lm_sensors,
}:

buildGoModule rec {
  pname = "pulse-host-agent";
  version = "4.28.0";

  src = fetchFromGitHub {
    owner = "rcourtman";
    repo = "Pulse";
    rev = "v${version}";
    hash = "sha256-aRFjQGYNwV6F+fYqd976dqboGQTFYonuf1CxZMAuf4A=";
  };

  sourceRoot = "${src.name}";

  subPackages = [ "cmd/pulse-host-agent" ];

  vendorHash = "sha256-VIY7gEueKunDK8S+sbyUoYX1KnsZ5+cM0i/2RaXy5cE=";

  nativeBuildInputs = [ makeWrapper ];

  ldflags = [
    "-s"
    "-w"
  ];

  postInstall = ''
    wrapProgram $out/bin/pulse-host-agent \
      --prefix PATH : ${lib.makeBinPath [ lm_sensors ]}
  '';

  meta = {
    description = "host agent for pulse monitoring platform - monitors standalone servers outside proxmox/docker infrastructure";
    homepage = "https://github.com/rcourtman/Pulse";
    license = lib.licenses.mit;
    maintainers = [ ];
    mainProgram = "pulse-host-agent";
    platforms = lib.platforms.linux;
  };
}
