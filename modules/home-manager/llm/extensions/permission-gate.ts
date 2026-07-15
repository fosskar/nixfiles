/**
 * Derived from rytswd/pi-agent-extensions permission-gate (MIT).
 * https://github.com/rytswd/pi-agent-extensions/tree/main/permission-gate
 */

import * as fs from "node:fs";
import { homedir } from "node:os";
import * as path from "node:path";
import type {
  ExtensionAPI,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import {
  Editor,
  type EditorTheme,
  Key,
  matchesKey,
  truncateToWidth,
} from "@earendil-works/pi-tui";

type RuleEntry = {
  pattern: string;
  label: string;
  flags?: string;
};

type RulesFile = {
  rules?: RuleEntry[];
  extraRules?: RuleEntry[];
  disabledRules?: string[];
};

type RuleSource = "built-in" | "user" | "project";

type CompiledRule = {
  pattern: RegExp;
  label: string;
  source: RuleSource;
};

type GateResult = { allow: true } | { allow: false; reason: string };
type WarnFn = (message: string) => void;

const GATE_SUBCOMMANDS = "list(ls)|add|remove(rm)|reload";

const BLOCK_RULES: RuleEntry[] = [
  { pattern: "\\bclan\\s+vars\\b", label: "clan vars" },
  { pattern: "\\bjj\\s+restore\\b", label: "jj restore" },
  { pattern: "\\bgit\\s+restore\\b", label: "git restore" },
  {
    pattern: "\\bgit\\s+checkout\\s+(\\S+\\s+)?--\\s",
    label: "git checkout --",
  },
  {
    pattern: "\\bgit\\s+checkout\\s+\\.\\s*($|[;&|])",
    label: "git checkout .",
  },
  { pattern: "\\bmkfs(?:\\.[^\\s]+)?\\b", label: "mkfs" },
  { pattern: "\\bdd\\b.*\\bof=/dev/", label: "dd to device" },
  { pattern: ">\\s*/dev/[sh]d[a-z]", label: "raw device redirect" },
  {
    pattern: ":\\(\\)\\s*\\{\\s*:\\s*\\|\\s*:\\s*&\\s*\\}\\s*;",
    label: "fork bomb",
  },
  {
    pattern: ">\\s*\\.env(?!\\.example)(\\b|$)",
    label: "write to .env",
  },
  { pattern: ">\\s*.*\\.(pem|key)\\b", label: "write to key/cert" },
  {
    pattern: "\\btee\\s+.*\\.env(?!\\.example)(\\b|$)",
    label: "write to .env",
  },
];

const DEFAULT_RULES: RuleEntry[] = [
  {
    pattern: "\\brm\\s+(-[^\\s]*r|--recursive)",
    label: "recursive delete",
  },
  { pattern: "\\bsudo\\b", label: "sudo" },
  {
    pattern: "\\bchmod\\b.*777",
    label: "world-writable permissions",
  },
  {
    pattern: "\\bclan\\s+machines\\s+update\\b",
    label: "clan deploy",
  },
  { pattern: "\\bclan\\s+install\\b", label: "clan install" },
  { pattern: "\\bnh\\s+os\\s+switch\\b", label: "nixos switch" },
  { pattern: "\\breboot\\b", label: "reboot" },
  {
    pattern: "\\bsystemctl\\s+(restart|stop|disable)\\b",
    label: "systemctl mutation",
  },
  { pattern: "\\bsetfacl\\b", label: "setfacl" },
  { pattern: "\\bjj\\s+abandon\\b", label: "jj abandon" },
  { pattern: "\\bjj\\s+squash\\b", label: "jj squash" },
  { pattern: "\\bjj\\s+git\\s+push\\b", label: "jj git push" },
  {
    pattern: "\\bgit\\s+push\\s+.*(-f\\b|--force\\b)",
    label: "force push",
  },
  { pattern: "\\bgit\\s+reset\\s+--hard\\b", label: "hard reset" },
  {
    pattern: "\\bgit\\s+clean\\s+-[^\\s]*f",
    label: "git clean",
  },
  {
    pattern: "\\b(curl|wget)\\b.*\\|\\s*(ba)?sh\\b",
    label: "pipe to shell",
  },
  {
    pattern:
      "\\bgh\\s+(issue|pr|repo|release)\\s+(create|close|delete|merge|edit|comment|review|rename|archive)\\b",
    label: "GitHub mutation",
  },
];

const SENSITIVE_FILES: RuleEntry[] = [
  { pattern: "\\.env($|\\.(?!example))", label: ".env file" },
  { pattern: "\\.(pem|key)$", label: "key/cert" },
  { pattern: "id_(rsa|ed25519|ecdsa)", label: "ssh key" },
  { pattern: "\\.ssh/", label: ".ssh directory" },
  {
    pattern: "secrets?\\.(json|ya?ml|toml)$",
    label: "secrets file",
    flags: "i",
  },
];

function configDir(): string {
  const override = path.join(
    homedir(),
    ".pi",
    "agent",
    "pi-agent-extensions.json",
  );
  try {
    const config = JSON.parse(fs.readFileSync(override, "utf-8"));
    if (typeof config.configDir === "string") {
      return path.join(config.configDir, "permission-gate");
    }
  } catch {}

  return path.join(
    process.env.XDG_CONFIG_HOME || path.join(homedir(), ".config"),
    "pi-agent-extensions",
    "permission-gate",
  );
}

function rulesFilePath(): string {
  return path.join(configDir(), "rules.json");
}

function readRulesFile(filePath: string, warn?: WarnFn): RulesFile {
  try {
    if (!fs.existsSync(filePath)) return {};
    return JSON.parse(fs.readFileSync(filePath, "utf-8"));
  } catch (error) {
    warn?.(
      `permission-gate: failed to load ${filePath}: ${(error as Error).message}`,
    );
    return {};
  }
}

function loadRules(
  cwd: string,
  warn?: WarnFn,
): {
  global: RulesFile;
  project: RulesFile;
} {
  return {
    global: readRulesFile(rulesFilePath(), warn),
    project: readRulesFile(path.join(cwd, ".pi", "permission-gate.json"), warn),
  };
}

function saveGlobalRules(config: RulesFile): void {
  const directory = configDir();
  fs.mkdirSync(directory, { recursive: true });
  fs.writeFileSync(rulesFilePath(), `${JSON.stringify(config, null, 2)}\n`);
}

function compileEntries(
  entries: RuleEntry[],
  source: RuleSource,
  disabled: ReadonlySet<string>,
  warn?: WarnFn,
): { rules: CompiledRule[]; hadError: boolean } {
  const rules: CompiledRule[] = [];
  let hadError = false;

  for (const entry of entries) {
    if (disabled.has(entry.label)) continue;
    try {
      rules.push({
        pattern: new RegExp(entry.pattern, entry.flags ?? "i"),
        label: entry.label,
        source,
      });
    } catch (error) {
      hadError = true;
      warn?.(
        `permission-gate: invalid regex for "${entry.label}": ${(error as Error).message}`,
      );
    }
  }

  return { rules, hadError };
}

function compileRules(
  global: RulesFile,
  project: RulesFile,
  warn?: WarnFn,
): CompiledRule[] {
  const disabled = new Set([
    ...(global.disabledRules ?? []),
    ...(project.disabledRules ?? []),
  ]);
  const base = compileEntries(
    global.rules ?? DEFAULT_RULES,
    global.rules ? "user" : "built-in",
    disabled,
    warn,
  );
  const user = compileEntries(global.extraRules ?? [], "user", disabled, warn);
  const projectExtra = compileEntries(
    project.extraRules ?? [],
    "project",
    disabled,
    warn,
  );
  const rules = [...base.rules, ...user.rules, ...projectExtra.rules];

  if (
    rules.length === 0 &&
    (base.hadError || user.hadError || projectExtra.hadError)
  ) {
    warn?.("permission-gate: all rules failed, falling back to defaults");
    return compileEntries(DEFAULT_RULES, "built-in", new Set(), warn).rules;
  }

  return rules;
}

function matchingLabels(rules: CompiledRule[], text: string): string[] {
  return rules.flatMap((rule) => {
    rule.pattern.lastIndex = 0;
    return rule.pattern.test(text) ? [rule.label] : [];
  });
}

function inputPaths(input: unknown): string[] {
  if (typeof input === "object" && input !== null && "path" in input) {
    const candidate = (input as { path?: unknown }).path;
    return typeof candidate === "string" ? [candidate] : [];
  }
  if (typeof input !== "string") return [];

  return Array.from(
    input.matchAll(/^\[([^#\r\n]+)#[0-9A-F]{4}\]$/gm),
    (match) => match[1],
  );
}

async function showReviewPrompt(
  ctx: ExtensionContext,
  command: string,
  labels: string,
): Promise<GateResult> {
  return ctx.ui.custom<GateResult>((tui, theme, _keybindings, done) => {
    let optionIndex = 0;
    let inputMode = false;
    let cachedLines: string[] | undefined;

    const editorTheme: EditorTheme = {
      borderColor: (text) => theme.fg("accent", text),
      selectList: {
        selectedPrefix: (text) => theme.fg("accent", text),
        selectedText: (text) => theme.fg("accent", text),
        description: (text) => theme.fg("muted", text),
        scrollInfo: (text) => theme.fg("dim", text),
        noMatch: (text) => theme.fg("warning", text),
      },
    };
    const editor = new Editor(tui, editorTheme);

    function refresh(): void {
      cachedLines = undefined;
      tui.requestRender();
    }

    editor.onSubmit = (value) => {
      const reason = value.trim()
        ? `Blocked by user (${labels}): ${value.trim()}`
        : `Blocked by user (${labels})`;
      done({ allow: false, reason });
    };

    function handleInput(data: string): void {
      if (inputMode) {
        if (matchesKey(data, Key.escape)) {
          inputMode = false;
          editor.setText("");
          refresh();
          return;
        }
        editor.handleInput(data);
        refresh();
        return;
      }

      if (matchesKey(data, Key.up)) {
        optionIndex = 0;
        refresh();
        return;
      }
      if (matchesKey(data, Key.down)) {
        optionIndex = 1;
        refresh();
        return;
      }
      if (matchesKey(data, Key.enter)) {
        if (optionIndex === 0) {
          done({ allow: true });
        } else {
          inputMode = true;
          editor.setText("");
          refresh();
        }
        return;
      }
      if (matchesKey(data, Key.escape)) {
        done({ allow: false, reason: `Blocked by user (${labels})` });
      }
    }

    function render(width: number): string[] {
      if (cachedLines) return cachedLines;
      const lines: string[] = [];
      const add = (text: string) => lines.push(truncateToWidth(text, width));

      lines.push("");
      add(
        `${theme.fg("warning", " Dangerous command ")}${theme.fg("muted", `(${labels})`)}`,
      );
      add(` ${theme.fg("text", command)}`);
      lines.push("");

      const options = ["Yes", inputMode ? "No (add reason)" : "No"];
      for (let index = 0; index < options.length; index += 1) {
        const selected = index === optionIndex;
        add(
          `${selected ? theme.fg("accent", " > ") : "   "}${theme.fg(selected ? "accent" : "text", options[index])}`,
        );
      }
      lines.push("");

      if (inputMode) {
        add(theme.fg("muted", " Reason:"));
        for (const line of editor.render(width - 2)) add(` ${line}`);
        lines.push("");
        add(theme.fg("dim", " Enter submit • Esc back"));
      } else {
        add(theme.fg("dim", " ↑↓ • Enter • Esc block"));
      }
      lines.push("");

      cachedLines = lines;
      return lines;
    }

    return {
      render,
      invalidate: () => {
        cachedLines = undefined;
      },
      handleInput,
    };
  });
}

export default function permissionGate(pi: ExtensionAPI): void {
  let enabled = true;
  let globalRules: RulesFile = {};
  let projectRules: RulesFile = {};
  let rules = compileRules(globalRules, projectRules);
  const blockRules = compileEntries(BLOCK_RULES, "built-in", new Set()).rules;
  const sensitiveFiles = compileEntries(
    SENSITIVE_FILES,
    "built-in",
    new Set(),
  ).rules;

  function updateStatus(ctx: ExtensionContext): void {
    if (!ctx.hasUI) return;
    ctx.ui.setStatus(
      "gate",
      enabled
        ? ctx.ui.theme.fg("dim", "\uf132 gate")
        : ctx.ui.theme.fg("warning", "\uf132 hard-blocks"),
    );
  }

  function reloadRules(cwd: string, warn?: WarnFn): void {
    const loaded = loadRules(cwd, warn);
    globalRules = loaded.global;
    projectRules = loaded.project;
    rules = compileRules(globalRules, projectRules, warn);
  }

  pi.on("session_start", async (_event, ctx) => {
    if (process.env.PI_NO_GATE === "1") enabled = false;
    const warn: WarnFn = (message) => {
      if (ctx.hasUI) ctx.ui.notify(message, "warning");
    };
    reloadRules(ctx.cwd, warn);
    updateStatus(ctx);
  });

  pi.on("tool_call", async (event, ctx) => {
    if (event.toolName === "bash") {
      const input = event.input as { command?: unknown };
      const command =
        typeof input?.command === "string" ? input.command : undefined;
      if (!command) return undefined;

      const blocked = matchingLabels(blockRules, command);
      if (blocked.length > 0) {
        const labels = blocked.join(", ");
        if (ctx.hasUI) ctx.ui.notify(`Blocked: ${labels}`, "warning");
        return { block: true, reason: labels };
      }

      if (!enabled) return undefined;
      const confirmations = matchingLabels(rules, command);
      if (confirmations.length === 0) return undefined;

      const labels = confirmations.join(", ");
      if (!ctx.hasUI) {
        return {
          block: true,
          reason: `Dangerous command blocked (${labels}) — no UI`,
        };
      }

      pi.events.emit("permission-gate:waiting", { command, labels });
      const result = await showReviewPrompt(ctx, command, labels);
      pi.events.emit("permission-gate:resolved");
      return result.allow ? undefined : { block: true, reason: result.reason };
    }

    if (event.toolName === "write" || event.toolName === "edit") {
      const hits = inputPaths(event.input).flatMap((filePath) =>
        matchingLabels(sensitiveFiles, path.normalize(filePath)),
      );
      if (hits.length > 0) {
        const labels = [...new Set(hits)].join(", ");
        if (ctx.hasUI) ctx.ui.notify(`Blocked: ${labels}`, "warning");
        return { block: true, reason: labels };
      }
    }

    return undefined;
  });

  pi.registerCommand("gate", {
    description: `Permission gate — toggle or manage rules: /gate [${GATE_SUBCOMMANDS}]`,
    handler: async (args, ctx) => {
      const subcommand = args?.trim().toLowerCase() ?? "";

      if (!subcommand) {
        enabled = !enabled;
        updateStatus(ctx);
        ctx.ui.notify(
          enabled
            ? "Permission gate enabled"
            : "Confirmations disabled; hard blocks remain active",
          "info",
        );
        return;
      }

      if (subcommand === "list" || subcommand === "ls") {
        const groups: Record<string, string[]> = {
          "hard block": blockRules.map((rule) => rule.label),
        };
        for (const rule of rules) {
          (groups[rule.source] ??= []).push(rule.label);
        }

        const sections = Object.entries(groups).map(
          ([source, labels]) =>
            `${source.charAt(0).toUpperCase()}${source.slice(1)} (${labels.length}):\n${labels.map((label) => `  • ${label}`).join("\n")}`,
        );
        ctx.ui.notify(sections.join("\n\n"), "info");
        return;
      }

      if (subcommand === "reload") {
        const warn: WarnFn = (message) => ctx.ui.notify(message, "warning");
        reloadRules(ctx.cwd, warn);
        ctx.ui.notify("Permission gate rules reloaded", "info");
        return;
      }

      if (subcommand === "add") {
        const pattern = await ctx.ui.input(
          "Pattern",
          "Regex (e.g. \\bdocker\\s+rm\\b)",
        );
        if (!pattern) return;
        const label = await ctx.ui.input(
          "Label",
          "Short name (e.g. docker remove)",
        );
        if (!label) return;
        try {
          new RegExp(pattern, "i");
        } catch {
          ctx.ui.notify("Invalid regex", "error");
          return;
        }

        globalRules.extraRules = [
          ...(globalRules.extraRules ?? []),
          { pattern, label },
        ];
        try {
          saveGlobalRules(globalRules);
        } catch (error) {
          ctx.ui.notify(
            `Failed to save rule: ${(error as Error).message}`,
            "error",
          );
          return;
        }
        rules = compileRules(globalRules, projectRules);
        ctx.ui.notify(`Rule added: ${label}`, "info");
        return;
      }

      if (subcommand === "remove" || subcommand === "rm") {
        if (rules.length === 0) {
          ctx.ui.notify("No rules to remove", "info");
          return;
        }
        const choice = await ctx.ui.select(
          "Remove rule",
          rules.map((rule) => rule.label),
        );
        if (!choice) return;

        const extraIndex = (globalRules.extraRules ?? []).findIndex(
          (rule) => rule.label === choice,
        );
        if (extraIndex >= 0) {
          globalRules.extraRules?.splice(extraIndex, 1);
        } else {
          globalRules.disabledRules = [
            ...(globalRules.disabledRules ?? []),
            choice,
          ];
        }
        try {
          saveGlobalRules(globalRules);
        } catch (error) {
          ctx.ui.notify(
            `Failed to save rules: ${(error as Error).message}`,
            "error",
          );
          return;
        }
        rules = compileRules(globalRules, projectRules);
        ctx.ui.notify(`Rule removed: ${choice}`, "info");
        return;
      }

      ctx.ui.notify(`Usage: /gate [${GATE_SUBCOMMANDS}]`, "info");
    },
  });
}
