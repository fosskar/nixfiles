_: {
  programs.git = {
    ignores = [
      ".cache/"
      ".DS_Store"
      ".idea/"
      "*.swp"
      "*.elc"
      "auto-save-list"
      "Thumbs.db"
      ".vscode"
      ".vscodium"
      ".direnv"
      "pre-commit-config.yaml"
    ];
  };
}
