{pkgs, ...}: {
  programs.vscode = {
    enable = true;
    enableUpdateCheck = false;
    enableExtensionUpdateCheck = false;
    mutableExtensionsDir = false;
    package = pkgs.vscodium;
    extensions = with pkgs.vscode-extensions; [
      pkief.material-icon-theme
      bbenoist.nix
      jnoortheen.nix-ide
      redhat.vscode-yaml
      ms-azuretools.vscode-docker
      yzhang.markdown-all-in-one
      kamadorueda.alejandra
      editorconfig.editorconfig
      mkhl.direnv
    ];
    userSettings = {
      "files.autoSave" = "afterDelay";
      "files.insertFinalNewline" = true;
      "files.trimFinalNewlines" = true;
      "files.trimTrailingWhitespace" = true;
      "workbench.iconTheme" = "material-icon-theme";
      "workbench.startupEditor" = "none";
      "redhat.telemetry.enabled" = false;
      "git.enableSmartCommit" = true;
      "git.confirmSync" = false;
      "terminal.integrated.fontFamily" = "JetBrains Mono";
      "editor.fontFamily" = "'JetBrains Mono'";
      "editor.fontSize" = 15;
      "editor.fontLigatures" = true;
      "editor.fontVariations" = false;
      "github.gitProtocol" = "ssh";
      "git.alwaysShowStagedChangesResourceGroup" = true;
      "git.branchRandomName.dictionary" = [
        "colors"
      ];
      "git.branchSortOrder" = "alphabetically";
      "git.defaultCloneDirectory" = "$HOME/code";
      "editor.tabSize" = 2;
      "git.rebaseWhenSync" = true;
    };
  };
}
