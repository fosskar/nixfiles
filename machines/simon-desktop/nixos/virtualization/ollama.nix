{ ... }:
{
  services = {
    ollama = {
      enable = false;
      #package = inputs.nixpkgs-stable.legacyPackages.${pkgs.system}.ollama;

      #package =
      #  let
      #    # get stable rocm packages
      #    stableRocm = inputs.nixpkgs-stable.legacyPackages.${pkgs.system}.rocmPackages;
      #
      #    # override ollama with stable rocm
      #    customOllama = inputs.nixpkgs.legacyPackages.${pkgs.system}.ollama.override {
      #      rocmPackages = stableRocm;
      #    };
      #  in
      #  customOllama;

      #package = inputs.nixpkgs.legacyPackages.${pkgs.system}.ollama.override {
      #  rocmPackages = inputs.nixpkgs-stable.legacyPackages.${pkgs.system}.rocmPackages;
      #};

      acceleration = "rocm";
      rocmOverrideGfx = "11.0.2";
      openFirewall = true;
    };

    ## UI but currently using open-webui
    #nextjs-ollama-llm-ui = {
    #  enable = true;
    #  port = 3001;
    #};
  };
}
