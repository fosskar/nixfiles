---
name: ops-review
description: Scan the infra for operational risk — blast radius, restore paths, probe coverage, drift — present findings as a visual HTML report, then grill through whichever one you pick.
disable-model-invocation: true
---

# Ops Review

Surface operational risk and propose **hardening opportunities**. Where architecture-review asks "is this module deep?", ops-review asks: when this fails at 3am, what breaks, does anything alert, and how do I get it back?

## Vocabulary

Use these terms exactly in every finding:

- **failure domain** — what fails together: a host, a network zone, a dependency chain.
- **blast radius** — everything that breaks when a failure domain dies.
- **SPOF** — a failure domain with no degraded mode.
- **state boundary** — the rung a service's state sits on: ephemeral → persisted → backed up → offsite. State sitting below the rung you believed it was on is a finding.
- **restore path** — the concrete steps from repo + backups to a running service.
- **probe** — a health check wired to an alert route. Probe coverage: every user-facing service has one.
- **exposure surface** — where a service is reachable from: loopback, mesh, LAN, public.
- **drift surface** — load-bearing configuration living outside the repo.

Two tests replace architecture-review's deletion test:

- **pull-the-plug test** — kill this host or service right now: what breaks, does anything alert, how do you get it back?
- **restore test** — rebuild from repo + backups alone: does the path exist end to end? A step that lives only in memory or a web UI is a drift finding.

## Process

### 1. Explore

Read `AGENTS.md` and decision records (`docs/decisions/` or similar) first — a risk accepted there is not a finding.

The repo declares intent; live systems reveal drift. Explore repo-first (`rg`, `nix eval`); go live only when the repo can't answer — is the timer actually firing, does the live mapping match the declared one — and only read-only: `systemctl status`, `journalctl`, `systemctl list-timers`, sqlite reads over ssh. The review observes; fixes, restarts, and deploys belong to the work that follows, never to the review.

Use sub-agents to walk the infrastructure along these lenses:

- Trace dependency chains — auth, DNS, mesh coordination, ingress, alerting — and apply the pull-the-plug test to each host: which are SPOFs, and how far does each blast radius reach?
- Walk every stateful service's state boundary and apply the restore test: state on the ephemeral root that misses persistence, persisted state with no backup, backups with no offsite rung.
- Probe coverage: which user-facing services lack a probe? Is the alert path itself probed — what alerts when alerting dies?
- Exposure: where does the surface exceed intent — public that should be mesh-only, a bind address wider than its consumers, an open port with no consumer?
- Secrets outside the repo's generator pattern; rotation that requires archaeology.
- Update risk: what does a bad update do to each host once deployed, and what is the rollback story?

In this setup the anchors are: inventory in `machines/flake-module.nix`; state boundary = `preservation.preserveAt."/persist"` + `clan.core.state.<svc>`; probes = gatus endpoints + `systemd-email-alerts`; exposure = `*.nx3.eu` caddy vhosts (LAN) vs `*.fosskar.eu` netbird-proxy (public — configured in the netbird UI, a drift surface by design; read it via `docs/netbird-exposure.md`); secrets = `clan.core.vars.generators`; update risk = manual `clan machines update` (nixbot only opens update PRs — deployment stays manual) + NixOS generations and the preservation rollback modules.

Exploration is complete when every host and every user-facing service is accounted for under every lens — it either produced a finding or is explicitly covered.

### 2. Present findings as an HTML report

Write a self-contained HTML file to the OS temp directory so nothing lands in the repo. Resolve the temp dir from `$TMPDIR`, falling back to `/tmp`, and write to `<tmpdir>/ops-review-<timestamp>.html` so each run gets a fresh file. Open it for the user with `xdg-open <path>` and tell them the absolute path.

The report is **dark mode**, uses **Tailwind via CDN** and **Mermaid via CDN**. Each finding gets a card:

- **Failure domain** — hosts/services involved
- **Finding** — what breaks, when, and how you'd find out
- **Mitigation** — plain English description of what would change
- **Wins** — in vocabulary terms: blast radius shrinks, restore path shortens, probe added
- **Diagram** — blast-radius graph, exposure path, or state-boundary cross-section
- **Severity** — one of `Critical`, `Worth hardening`, `Accepted risk`, rendered as a badge

End the report with a **Top risk** section: what you'd harden first and why.

**Decision-record conflicts**: surface a finding that contradicts a recorded decision only when the risk is severe enough to reopen the decision, marked with a warning callout.

See [HTML-REPORT.md](HTML-REPORT.md) for the scaffold, diagram patterns, and styling.

Do NOT design mitigations yet. After the file is written, ask the user: "Which finding should we dig into?"

### 3. Grilling loop

Once the user picks a finding, run the grilling skill — walk the failure scenario, the mitigation's shape, what the restore path becomes, and which probe proves it works.

Side effects happen inline as decisions crystallize:

- **Naming a failure domain or probe the repo's vocabulary doesn't cover?** Add the term where the repo keeps its vocabulary (`AGENTS.md` or docs).
- **User accepts a risk with a load-bearing reason?** Offer a decision record: _"Want me to record this so future ops reviews don't re-flag it?"_ Skip ephemeral reasons and self-evident ones.
- **Mitigation needs a new module design?** That's architecture-review territory — run the codebase-design skill.
