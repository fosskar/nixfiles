_: {
  services.open-webui = {
    enable = false;
    port = 11111;
    host = "10.0.0.106";
    openFirewall = true;
    environment = {
      OLLAMA_API_BASE_URL = "http://127.0.0.1:11434";
      ANONYMIZED_TELEMETRY = "False";
      DO_NOT_TRACK = "True";
      SCARF_NO_ANALYTICS = "True";

      OCL_ICD_VENDORS = "/run/opengl-driver/etc/OpenCL/vendors";
      LIBVA_DRIVER_NAME = "iHD";

      # RAG
      #RAG_EMBEDDING_ENGINE = "ollama";
      #RAG_EMBEDDING_MODEL = "nomic-embed-text";

      #CONTENT_EXTRACTION_ENGINE = "tika";
      #PDF_EXTRACT_IMAGES = "true";
      #TIKA_SERVER_ENDPOINT = "http://127.0.0.1:9998";
    };
  };
}
