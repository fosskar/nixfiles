{ pkgs, ... }:
{
  services.ollama = {
    enable = true;
    package = pkgs.ollama-vulkan;
    environmentVariables = {
      # opencl configuration
      OCL_ICD_VENDORS = "/run/opengl-driver/etc/OpenCL/vendors";
      VK_ICD_FILENAMES = "/run/opengl-driver/share/vulkan/icd.d/intel_icd.x86_64.json";
      LIBVA_DRIVER_NAME = "iHD";

      # ollama intel gpu settings
      OLLAMA_NUM_GPU = "99"; # 48 or 24 ?
      OLLAMA_INTEL_GPU = "true";
      OLLAMA_VULKAN = "1";
    };
    host = "127.0.0.1";
    openFirewall = false;

    loadModels = [
      # llm
      "deepseek-r1:7b"
      "qwen3:8b"
      "gemma3:4b"

      # vision
      "minicpm-v:8b"
    ];
  };
}
