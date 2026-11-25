{
  lib,
  stdenv,
  python3,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  bash,
}:
let
  # these four are not in nixpkgs. pypi wheels, because sentencex and
  # pipecat-resampler are rust and loudness is c++ behind python bindings
  wheel =
    {
      pname,
      version,
      url,
      hash,
      dependencies ? [ ],
    }:
    python3.pkgs.buildPythonPackage {
      inherit pname version dependencies;
      format = "wheel";
      src = fetchurl { inherit url hash; };
      nativeBuildInputs = [ autoPatchelfHook ];
      buildInputs = [ stdenv.cc.cc.lib ];
      # pipecat pins protobuf <7, soundfile ~=0.13.1 and sentencex ==1.0.34
      dontCheckRuntimeDeps = true;
    };

  loudness = wheel {
    pname = "loudness";
    version = "0.2.0";
    url = "https://files.pythonhosted.org/packages/8a/7b/d6b6873ef676abe0957c851aa24222a6a9ba30a17bc1e8e26d2083e3cdad/loudness-0.2.0-cp314-cp314-manylinux_2_24_x86_64.manylinux_2_28_x86_64.whl";
    hash = "sha256-6FR6eY9s6Qu2CQCJGNhj5p/geJmlc/fmxEle86Vjm5A=";
    dependencies = [ python3.pkgs.numpy ];
  };

  sentencex = wheel {
    pname = "sentencex";
    version = "1.0.34";
    url = "https://files.pythonhosted.org/packages/70/4d/8540f7c30402fe5f162e0e607915accc817afdd38891b7491543d32a4207/sentencex-1.0.34-cp314-cp314-manylinux2014_x86_64.manylinux_2_17_x86_64.whl";
    hash = "sha256-WvCBippjhd6GAbN42fCnflz4Z8Ygkmt+J4I4WvkVFS4=";
  };

  pipecat-resampler = wheel {
    pname = "pipecat-resampler";
    version = "0.2.0";
    url = "https://files.pythonhosted.org/packages/47/5e/a397b19d2c9e782839122e5ccbe4af0a51017c5d04d465dbf3052ee1befe/pipecat_resampler-0.2.0-cp311-abi3-manylinux2014_x86_64.manylinux_2_17_x86_64.whl";
    hash = "sha256-MOyf9JTEME+gcjqscR1SZEX6xPNFrcHwLpuIhVl2U9c=";
    dependencies = [ python3.pkgs.numpy ];
  };

  pipecat-ai = wheel {
    pname = "pipecat-ai";
    version = "1.17.0";
    url = "https://files.pythonhosted.org/packages/67/9d/0d1c0bad8e1726cf76e4ef250954b5dea4a1c9fa7510e3330c1213996312/pipecat_ai-1.17.0-py3-none-any.whl";
    hash = "sha256-KNrLBynO7kZQ09UD7h62i9FeAfhh496ubxShPWZaQgA=";
    dependencies = [
      loudness
      sentencex
      pipecat-resampler
    ]
    ++ (with python3.pkgs; [
      aiofiles
      aiohttp
      docstring-parser
      loguru
      markdown
      numpy
      pillow
      protobuf
      pydantic
      python-dotenv
      soundfile
      openai
      websockets
      pyyaml
      num2words
      onnxruntime
      # extra: local audio transport
      pyaudio
    ]);
  };

  pythonEnv = python3.withPackages (_: [ pipecat-ai ]);
in
stdenv.mkDerivation {
  pname = "voice-assistant";
  version = "0.1.0";

  src = ./voice_assistant.py;
  dontUnpack = true;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall
    install -Dm644 $src $out/share/voice-assistant/voice_assistant.py
    makeWrapper ${pythonEnv}/bin/python $out/bin/voice-assistant \
      --add-flags $out/share/voice-assistant/voice_assistant.py \
      --prefix PATH : ${lib.makeBinPath [ bash ]}
    runHook postInstall
  '';

  meta = {
    description = "Interruptible desktop voice assistant on pipecat";
    mainProgram = "voice-assistant";
    platforms = [ "x86_64-linux" ];
    # the three binary wheels
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
