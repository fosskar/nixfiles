/**
 * safety-net — intercepts dangerous tool calls with block/confirm logic.
 * toggle via /safety-net. status bar shows "" when active.
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import * as path from "node:path";

type Rule = { re: RegExp; tag: string };

const NEVER: Rule[] = [
  { re: /\bclan\s+vars\b/, tag: "clan vars (never)" },
  { re: /\bjj\s+restore\b/, tag: "jj restore" },
  { re: /\bgit\s+restore\b/, tag: "git restore" },
  { re: /\bgit\s+checkout\s+(\S+\s+)?--\s/, tag: "git checkout --" },
  { re: /\bgit\s+checkout\s+\.\s*($|[;&|])/, tag: "git checkout ." },
  { re: /\bmkfs\b/, tag: "mkfs" },
  { re: /\bdd\b.*\bof=\/dev\//, tag: "dd to device" },
  { re: />\s*\/dev\/[sh]d[a-z]/, tag: "redirect to device" },
  { re: /:\(\)\s*\{\s*:\s*\|\s*:\s*&\s*\}\s*;/, tag: "fork bomb" },
];

const ASK: Rule[] = [
  // deploys & system
  { re: /\bclan\s+machines\s+update\b/, tag: "clan deploy" },
  { re: /\bclan\s+install\b/, tag: "clan install" },
  { re: /\bnh\s+os\s+switch\b/, tag: "nixos switch" },
  { re: /\breboot\b/, tag: "reboot" },
  { re: /\bsystemctl\s+(restart|stop|disable)\b/, tag: "systemctl" },
  { re: /\bsudo\b/, tag: "sudo" },
  // file destruction
  { re: /\brm\s+(-[^\s]*r|--recursive)/, tag: "recursive rm" },
  { re: /\bchmod\b.*777/, tag: "chmod 777" },
  // vcs
  { re: /\bjj\s+abandon\b/, tag: "jj abandon" },
  { re: /\bjj\s+squash\b/, tag: "jj squash" },
  { re: /\bgit\s+push\s+.*(-f\b|--force\b)/, tag: "force push" },
  { re: /\bgit\s+reset\s+--hard\b/, tag: "hard reset" },
  { re: /\bgit\s+clean\s+-[^\s]*f/, tag: "git clean" },
  { re: /\bjj\s+git\s+push\b/, tag: "jj git push" },
  // remote exec
  { re: /\bcurl\b.*\|\s*(ba)?sh\b/, tag: "curl | sh" },
  { re: /\bwget\b.*\|\s*(ba)?sh\b/, tag: "wget | sh" },
  // github cli
  {
    re: /\bgh\s+(issue|pr|repo|release)\s+(create|close|delete|merge|edit|comment|review|rename|archive)\b/,
    tag: "gh mutation",
  },
];

const SENSITIVE_FILES: Rule[] = [
  { re: /\.env($|\.(?!example))/, tag: ".env file" },
  { re: /\.(pem|key)$/, tag: "key/cert" },
  { re: /id_(rsa|ed25519|ecdsa)/, tag: "ssh key" },
  { re: /\.ssh\//, tag: ".ssh dir" },
  { re: /secrets?\.(json|ya?ml|toml)$/i, tag: "secrets file" },
];

const SENSITIVE_WRITES = [
  />\s*\.env(?!\.example)(\b|$)/,
  />\s*.*\.(pem|key)\b/,
  /tee\s+.*\.env(?!\.example)(\b|$)/,
];

// strip single- and double-quoted strings so rules don't match inside
// argument values (e.g. commit messages, here-strings).
function stripQuoted(cmd: string): string {
  return cmd.replace(/'[^']*'/g, "''").replace(/"(?:[^"\\]|\\.)*"/g, '""');
}

function match(rules: Rule[], text: string): string[] {
  return rules.filter((r) => r.re.test(text)).map((r) => r.tag);
}

export default function (pi: ExtensionAPI) {
  let on = true;

  const setIndicator = (ctx: any) => {
    if (ctx.hasUI) {
      ctx.ui.setStatus(
        "safety-net",
        on ? ctx.ui.theme.fg("warning", "") : undefined,
      );
    }
  };

  pi.registerCommand("safety-net", {
    description: "toggle safety-net — block/confirm dangerous commands",
    handler: async (_args, ctx) => {
      if (!ctx.hasUI) return;
      on = !on;
      setIndicator(ctx);
      ctx.ui.notify(on ? "safety-net on" : "safety-net off", "info");
    },
  });

  pi.on("session_start", async (_ev, ctx) => setIndicator(ctx));

  pi.on("tool_call", async (event, ctx) => {
    if (!on) return undefined;

    // bash commands
    if (event.toolName === "bash") {
      const cmd = event.input.command as string;
      const scan = stripQuoted(cmd);

      const blocked = match(NEVER, scan);
      if (blocked.length) {
        ctx.hasUI && ctx.ui.notify(`🚫 ${blocked.join(", ")}`, "warning");
        return { block: true, reason: blocked.join(", ") };
      }

      if (SENSITIVE_WRITES.some((re) => re.test(scan))) {
        ctx.hasUI && ctx.ui.notify("🚫 write to sensitive path", "warning");
        return { block: true, reason: "write to sensitive path" };
      }

      const needs_ok = match(ASK, scan);
      if (needs_ok.length) {
        const summary = needs_ok.join(", ");
        if (!ctx.hasUI) {
          return { block: true, reason: `${summary} — no ui` };
        }
        const ok = await ctx.ui.select(`⚠️  ${summary}\n\n  ${cmd}\n\nallow?`, [
          "yes",
          "no",
        ]);
        if (ok !== "yes") {
          return { block: true, reason: `denied: ${summary}` };
        }
      }
      return undefined;
    }

    // file writes
    if (event.toolName === "write" || event.toolName === "edit") {
      const fp = path.normalize(event.input.path as string);
      const hits = match(SENSITIVE_FILES, fp);
      if (hits.length) {
        ctx.hasUI && ctx.ui.notify(`🚫 ${hits.join(", ")}: ${fp}`, "warning");
        return { block: true, reason: hits.join(", ") };
      }
    }

    return undefined;
  });
}
