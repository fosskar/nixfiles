_: {
  services = {
    ollama = {
      enable = true;
      acceleration = "rocm";
      # the models to download as soon as the service starts. Search for models of your choice from: https://ollama.com/library
      loadModels = [ ]; # is shit better pull manually
      rocmOverrideGfx = "11.0.2";
      openFirewall = true;
      port = 11434;
      host = "127.0.0.1";

    };

    # UI but currently using open-webui
    #nextjs-ollama-llm-ui = {
    #  enable = true;
    #};
  };
}
