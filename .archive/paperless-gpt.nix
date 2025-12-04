{ config, ... }:
{
  virtualisation.oci-containers.containers.paperless-gpt = {
    image = "icereed/paperless-gpt:latest";

    volumes = [
      "/var/lib/paperless-gpt/prompts:/app/prompts:U"
      "/var/lib/paperless-gpt/hocr:/app/hocr:U"
      "/var/lib/paperless-gpt/pdf:/app/pdf:U"
    ];

    environmentFiles = [ config.sops.secrets."paperless.env".path ];

    environment = {
      PAPERLESS_BASE_URL = "http://localhost:28981";
      PAPERLESS_PUBLIC_URL = "https://docs.osscar.me";
      MANUAL_TAG = "review"; # default is "paperless-gpt"
      AUTO_TAG = "paperless-gpt-auto"; # Optional, default: paperless-gpt-auto

      # Ollama (Local)
      LLM_PROVIDER = "ollama";
      LLM_MODEL = "gemma3:4b";
      OLLAMA_HOST = "http://10.0.0.106:11434";
      OLLAMA_CONTEXT_LENGTH = "4096"; # reduced from 8192 for better performance on intel arc vulkan
      TOKEN_LIMIT = "1000"; # Recommended for smaller models or 16384

      # Optional LLM Settings
      LLM_LANGUAGE = "German";

      # OCR Configuration
      OCR_PROVIDER = "llm";
      VISION_LLM_PROVIDER = "ollama";
      VISION_LLM_MODEL = "minicpm-v:8b";

      # OCR Processing Mode
      OCR_PROCESS_MODE = "image";

      # Enhanced OCR Features
      CREATE_LOCAL_HOCR = "true"; # Optional, save hOCR files locally
      LOCAL_HOCR_PATH = "/app/hocr"; # Optional, path for hOCR files
      CREATE_LOCAL_PDF = "true"; # Optional, save enhanced PDFs locally
      LOCAL_PDF_PATH = "/app/pdf"; # Optional, path for PDF files

      # PDF Upload to paperless-ngx
      PDF_UPLOAD = "false"; # Optional, upload enhanced PDFs to paperless-ngx
      PDF_REPLACE = "false"; # Optional and DANGEROUS, delete original after upload
      PDF_COPY_METADATA = "true"; # Optional, copy metadata from original document
      PDF_OCR_TAGGING = "true"; # Optional, add tag to processed documents
      PDF_OCR_COMPLETE_TAG = "paperless-gpt-ocr-complete"; # Optional, tag name

      AUTO_OCR_TAG = "paperless-gpt-ocr-auto"; # Optional, default: paperless-gpt-ocr-auto
      OCR_LIMIT_PAGES = "5"; # Optional, default: 5. Set to 0 for no limit.
      LOG_LEVEL = "debug"; # Optional: debug, warn, error
    };

    extraOptions = [
      "--network=host"
      "--cap-drop=ALL"
      "--security-opt=no-new-privileges=true"
      # resource limits removed - they cause paperless-gpt to stop/hang
    ];
  };
  systemd.tmpfiles.rules = [
    "d /var/lib/paperless-gpt 0755 root root -"
    "d /var/lib/paperless-gpt/prompts 0755 root root -"
    "d /var/lib/paperless-gpt/hocr 0755 root root -"
    "d /var/lib/paperless-gpt/pdf 0755 root root -"
  ];

  networking.firewall.allowedTCPPorts = [ 8080 ];
}
