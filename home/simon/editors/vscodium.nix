{ pkgs, ... }:
{
  programs.vscode = {
    enable = true;
    enableUpdateCheck = false;
    enableExtensionUpdateCheck = false;
    mutableExtensionsDir = false;
    package = pkgs.vscodium;
    extensions = with pkgs.vscode-extensions; [
      editorconfig.editorconfig
      pkief.material-icon-theme
      bbenoist.nix
      jnoortheen.nix-ide
      redhat.vscode-yaml
      yzhang.markdown-all-in-one
      eamodio.gitlens
      christian-kohler.path-intellisense
      esbenp.prettier-vscode
      alefragnani.project-manager
      continue.continue
    ];
    userSettings = {
      "update.mode" = "none";
      "diffEditor.ignoreTrimWhitespace" = false;
      "files.autoSave" = "afterDelay";
      "files.insertFinalNewline" = true;
      "files.trimFinalNewlines" = true;
      "files.trimTrailingWhitespace" = true;
      "files.exclude" = {
        "**/.git" = true;
        "**/.pre-commit-config.yaml" = true;
        "**/.direnv" = true;
      };
      "workbench.iconTheme" = "material-icon-theme";
      "workbench.startupEditor" = "none";
      "workbench.editor.highlightModifiedTabs" = true;
      "workbench.editorAssociations"."*.md" = "vscode.markdown.preview.editor";
      "workbench.list.smoothScrolling" = true;
      "window.titleBarStyle" = "custom";
      "redhat.telemetry.enabled" = false;
      "git.enableSmartCommit" = true;
      "git.enableCommitSigning" = true;
      "git.confirmSync" = false;
      "git.autofetch" = true;
      "git.alwaysShowStagedChangesResourceGroup" = true;
      "git.branchRandomName.dictionary" = [ "colors" ];
      "git.branchSortOrder" = "alphabetically";
      "git.defaultCloneDirectory" = "$HOME/code";
      "git.rebaseWhenSync" = true;
      "github.gitProtocol" = "ssh";
      "terminal.integrated.fontFamily" = "JetBrainsMono Nerd Font";
      "terminal.integrated.scrollback" = 5000;
      "terminal.integrated.shellIntegration.enabled" = true;
      "terminal.integrated.smoothScrolling" = true;
      "terminal.integrated.defaultProfile.linux" = "zsh";
      "terminal.integrated.profiles.linux" = {
        bash.path = "${pkgs.bash}/bin/bash";
        zsh.path = "${pkgs.zsh}/bin/zsh";
      };
      "telemetry.telemetryLevel" = "off";
      "editor.fontFamily" = "JetBrainsMono Nerd Font";
      "editor.fontSize" = 15;
      "editor.fontLigatures" = true;
      "editor.fontVariations" = false;
      "editor.formatOnSave" = true;
      "editor.tabSize" = 2;
      "editor.defaultFormatter" = "esbenp.prettier-vscode";
      "editor.acceptSuggestionOnEnter" = "off";
      "editor.bracketPairColorization.enabled" = true;
      "editor.minimap.enabled" = false;
      "search.exclude" = {
        "**/.direnv" = true;
      };
      # nix
      # i use the nixd lang server here
      "nix.enableLanguageServer" = true;
      "nix.serverPath" = "${pkgs.nixd}/bin/nixd";
      "nix.formatterPath" = "${pkgs.nixfmt-rfc-style}/bin/nixfmt";
      "nix.serverSettings" = {
        nixd = {
          formatting = {
            command = [ "${pkgs.nixfmt-rfc-style}/bin/nixfmt" ];
          };
        };
      };
      "[nix]" = {
        "editor.defaultFormatter" = "jnoortheen.nix-ide";
      };
      # yaml
      "yaml.format.enable" = true;
      "[yaml]" = {
        "editor.defaultFormatter" = "redhat.vscode-yaml";
      };
      # markdown
      "[markdown]" = {
        "editor.defaultFormatter" = "yzhang.markdown-all-in-one";
      };
      # continue local llm settings
      "continue.telemetryEnabled" = false;
      "continue.enableTabAutocomplete" = true;
    };
  };
}
