# nixworker — minisforum ms-a2

## hardware

- CPU: AMD Ryzen 9 9955HX (zen 5, 16c/32t, 5.4GHz boost)
- RAM: 96GB
- form factor: mini PC

## roles

### 1. buildbot-nix (CI)

auto-build nixfiles on push, populate binary cache. builds locally on ms-a2 — no need for remote build distribution (only x86_64-linux, 16c/32t is plenty for 5-machine fleet).

- compatible forges: GitHub, Gitea/Forgejo, codeberg (forgejo-based)
- NOT compatible: tangled (no forge API)
- auto flake input updates: script with `gh`/`tea` cli + cron/systemd timer
  - update each input individually → create PR → buildbot builds → auto-merge if green
- reference: mic92's setup on eve — same pattern but he offloads to university servers for multi-arch. we don't need that.

### 2. nix remote builder

other machines (simon-desktop, lpt-titan) offload builds here via `nix.buildMachines`.

```nix
nix.buildMachines = [{
  hostName = "ms-a2";
  systems = ["x86_64-linux"];
  maxJobs = 16;
  speedFactor = 10;
  supportedFeatures = ["nixos-test" "big-parallel" "kvm"];
}];
nix.distributedBuilds = true;
```

### 3. binary cache (harmonia)

serve locally-built store paths over HTTP. other machines pull instead of rebuild.

- **harmonia** = serves local nix store (own builds)
- **ncps** = proxy upstream caches (consider moving from nixbox)

### 4. remote dev server (Zed)

Zed remote server via SSH. code remotely, builds + LSPs + evals run on ms-a2. 96GB RAM makes sense here — multiple `nix develop` shells, big evals, test VMs. laptop becomes thin client.

## what was ruled out

- **kubernetes (k8s/talos/k3s)**: overkill for homelab, NixOS already provides declarative service management, single physical machine = no real HA
- **VM lab as primary role**: optional/on-demand, not a dedicated use case

## practical stack

```
ms-a2 (NixOS)
├── buildbot-nix (CI, connected to codeberg/forgejo)
├── harmonia (binary cache for own builds)
├── ncps (proxy upstream caches)
├── nix remote builder (other hosts offload here)
└── remote dev server (Zed remote SSH)
```

## open questions

- codeberg vs self-hosted forgejo for buildbot-nix integration?
- move ncps from nixbox to ms-a2 or keep separate?
- auto-merge flake update PRs or manual approval?
- network: same LAN as other home machines? IP assignment?
- disk layout: zfs? disko? ephemeral root with persistence?
- machine tags: `server`, `home`, `builder`?
