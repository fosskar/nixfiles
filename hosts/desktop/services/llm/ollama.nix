_: {
  services = {
    ollama = {
      enable = true;
      acceleration = "rocm";
      rocmOverrideGfx = "11.0.2";
      openFirewall = true;
      loadModels = [
        "deepseek-r1:8b"
      ];
    };

    ## UI but currently using open-webui
    #nextjs-ollama-llm-ui = {
    #  enable = true;
    #  port = 3001;
    #};
  };
}
