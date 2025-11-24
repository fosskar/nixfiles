{ pkgs, ... }:
let
  # custom ollama with vulkan support
  ollama-vulkan = pkgs.ollama.overrideAttrs (oldAttrs: {
    buildInputs = (oldAttrs.buildInputs or [ ]) ++ [
      pkgs.vulkan-loader
      pkgs.vulkan-headers
    ];

    nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ]) ++ [
      pkgs.vulkan-loader
      pkgs.shaderc # provides glslc shader compiler
    ];

    env = (oldAttrs.env or { }) // {
      VULKAN_SDK = "${pkgs.vulkan-loader}";
    };
  });
in
{
  services.ollama = {
    enable = true;
    package = ollama-vulkan;
    environmentVariables = {
      # opencl configuration
      OCL_ICD_VENDORS = "/run/opengl-driver/etc/OpenCL/vendors";
      VK_ICD_FILENAMES = "/run/opengl-driver/share/vulkan/icd.d/intel_icd.x86_64.json";
      LIBVA_DRIVER_NAME = "iHD";

      # ollama intel gpu settings
      OLLAMA_NUM_GPU = "99"; # 48 or 24
      OLLAMA_INTEL_GPU = "true";
    };
    host = "10.0.0.106";
    openFirewall = true;

    loadModels = [
      # llm
      "deepseek-r1:7b"
      "qwen3:8b"
      #"qwen3:14b"
      "gemma3:4b"
      #"gemma3:27b"
      #"gpt-oss:20b"
      "phi4:14b"

      # vision
      "minicpm-v:8b"

      # coding
      "deepseek-r1:14b"
    ];
  };
}
