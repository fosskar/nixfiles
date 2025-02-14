{
  config,
  lib,
  ...
}:
with lib;

let
  cfg = config.module.terminal.programs.k9s;
in
{
  options.module.terminal.programs.k9s = {
    enable = mkEnableOption "Enable k9s";
  };

  config = mkIf cfg.enable {
    home.sessionVariables.KUBE_EDITOR = "nvim";

    programs.k9s = {
      enable = true;
      settings.k9s = {
        ui = {
          enableMouse = false; # can scroll, but dont click. true = cant scroll, but can click
          headless = false;
          logoless = true;
          noIcons = true;
        };
        skipLatestRevCheck = true;
      };
      plugin.plugin = {
        # kubectl-blame by knight42
        # Annotate each line in the given resource's YAML with information from the managedFields to show who last modified the field.
        # Source: https://github.com/knight42/kubectl-blame
        # Install via:
        #   krew: `kubectl krew install blame`
        #   go: `go install github.com/knight42/kubectl-blame@latest`
        blame = {
          shortCut = "b";
          confirm = false;
          description = "Blame";
          scopes = [ "all" ];
          command = "sh";
          background = false;
          args = [
            "-c"
            "kubectl-blame $RESOURCE_NAME $NAME -n $NAMESPACE --context $CONTEXT | less"
          ];
        };
        #--- Create debug container for selected pod in current namespace
        # See https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/#ephemeral-container
        debug = {
          shortCut = "Shift-D";
          description = "Add debug container";
          dangerous = true;
          scopes = [ "containers" ];
          command = "bash";
          background = false;
          confirm = true;
          args = [
            "-c"
            "kubectl debug -it --context $CONTEXT -n=$NAMESPACE $POD --target=$NAME --image=nicolaka/netshoot:v0.12 --share-processes -- bash"
          ];
        };
        dive = {
          shortCut = "d";
          confirm = false;
          description = "Dive image";
          scopes = [ "containers" ];
          command = "dive";
          background = false;
          args = "$COL-IMAGE";
        };
        remove_finalizers = {
          shortCut = "Ctrl-F";
          confirm = true;
          dangerous = true;
          scopes = [ "all" ];
          description = "Removes all finalizers from selected resource. Be careful when using it, it may leave dangling resources or delete them";
          command = "kubectl";
          background = true;
          args = [
            "patch"
            "--context"
            "$CONTEXT"
            "--namespace"
            "$NAMESPACE"
            "$RESOURCE_NAME"
            "$NAME"
            "-p"
            "{'metadata':{'finalizers':null}}"
            "--type"
            "merge"
          ];
        };
        watch-events = {
          shortCut = "Shift-E";
          confirm = false;
          description = "Get Events";
          scopes = [ "all" ];
          command = "sh";
          background = false;
          args = [
            "-c"
            "watch -n 5 kubectl get events --context $CONTEXT --namespace $NAMESPACE --field-selector involvedObject.name=$NAME"
          ];
        };
      };
    };
  };
}
