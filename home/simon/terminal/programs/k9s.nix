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
      aliases.aliases = {
        cr = "clusterrole";
        crb = "clusterrolebinding";
        de = "deployment";
        dp = "deployment";
        rb = "rolebinding";
        sec = "secrets";
      };
      plugins = {
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
        debug-container-busybox = {
          shortCut = "Ctrl-D";
          description = "debug-container-busybox";
          confirm = true;
          scopes = [ "containers" ];
          command = "sh";
          args = [
            "-c"
            "kubectl debug -it -n=$NAMESPACE $POD --target=$NAME --image=busybox:1.28 --share-processes"
          ];
        };
        debug-container-netshoot = {
          shortCut = "Ctrl-E";
          description = "debug-container-netshoot";
          confirm = true;
          scopes = [ "containers" ];
          command = "sh";
          args = [
            "-c"
            "kubectl debug -it -n=$NAMESPACE $POD --target=$NAME --image=nicolaka/netshoot:v0.11 --share-processes -- bash"
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
      };
    };
  };
}
