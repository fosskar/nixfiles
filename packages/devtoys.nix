{
  stdenv,
  lib,
  fetchFromGitHub,
  cmake,
  makeWrapper,
}:
stdenv.mkDerivation rec {
  pname = "devtoys";
  version = "1.0.13.0";

  src = fetchFromGitHub {
    owner = "DevToys-app";
    repo = "DevToys";
    rev = "1.0.13.0";
    sha256 = lib.fakeSha256; # Replace with the actual sha256
  };

  nativeBuildInputs = [cmake makeWrapper];

  buildPhase = ''
    cmake . -DCMAKE_INSTALL_PREFIX=$out
    make
  '';

  installPhase = ''
    make install
  '';

  meta = with lib; {
    description = "DevToys - All-in-one toolbox for developers";
    license = licenses.mit; # Replace with the actual license
    platforms = platforms.unix;
    maintainers = with maintainers; [your-github-username];
  };
}
