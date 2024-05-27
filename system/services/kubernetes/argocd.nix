{
  inputs,
  pkgs,
  ...
}: let
  kubelib = inputs.nix-kube-generators.lib {inherit pkgs;};
in {
  argo = kubelib.buildHelmChart {
    name = "argo";
    chart = (inputs.nixhelm.charts {inherit pkgs;}).argoproj.argo-cd;
    namespace = "argo";
  };
}
