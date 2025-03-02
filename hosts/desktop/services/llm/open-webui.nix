_: {
  services = {
    open-webui = {
      enable = true;
      openFirewall = true;
      host = "0.0.0.0";
      port = 8080;
      environment = {
        OLLAMA_BASE_URL = "http://127.0.0.1:11434";
        OLLAMA_API_BASE_URL = "http://127.0.0.0:11434/api";
        # Disable authentication
        WEBUI_AUTH = "False";
        ENABLE_SIGNUP = "False";
        DEFAULT_MODELS = "llama3.1";
        ENABLE_COMMUNITY_SHARING = "False";
        ENABLE_OLLAMA_API = "true";
        ENABLE_RAG_WEB_SEARCH = "true";
        RAG_WEB_SEARCH_ENGINE = "duckduckgo";
      };
    };
  };
}
