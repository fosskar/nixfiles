/**
 * pi-pong — two models ping-pong on a task until they converge.
 *
 * /pong <task>
 *   1. picks a second model (current model = A, you pick B)
 *   2. creates two isolated workspaces (jj workspace > git worktree > tmp copy)
 *   3. round 0: both models implement the task in parallel
 *   4. ping-pong rounds: each model in turn sees its own + the other's diff,
 *      may revise its own files, and emits a verdict (stable/revised)
 *   5. converges when both consecutive turns return "stable"
 *      stable  = i made no changes this turn; my workspace is final from my POV
 *      revised = i edited my workspace this turn (round needs to continue)
 *   6. on convergence: rsync chosen workspace -> cwd (with confirm)
 *      on no convergence after MAX rounds: user picks A / B / abort
 */

import { spawn } from "node:child_process";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import type { Message } from "@mariozechner/pi-ai";
import {
  Container,
  SelectList,
  type SelectItem,
  Text,
} from "@mariozechner/pi-tui";
import type {
  ExtensionAPI,
  ExtensionContext,
} from "@mariozechner/pi-coding-agent";

// ---- config ----

// soft safety cap; the loop exits naturally when both consecutive turns
// report "stable". increase if your tasks legitimately need more iterations.
const MAX_TURNS = 50;
// accept old (agree/disagree) and new (stable/revised) tokens for back-compat;
// normalize at parse time.
const VERDICT_RE =
  /===\s*VERDICT:\s*(stable|revised|agree|disagree|pending)\s*(?::\s*([^=]*?))?\s*===/i;
// ASK_USER block: a question on its own line, optionally followed by an
// OPTIONS line listing | -separated choices.
const ASK_USER_RE = /===\s*ASK_USER:\s*([^=]+?)\s*===/i;
const ASK_OPTIONS_RE = /===\s*OPTIONS:\s*([^=]+?)\s*===/i;
const RSYNC_EXCLUDES = [
  ".git",
  ".jj",
  "node_modules",
  ".direnv",
  "result",
  ".pi/state",
];

// ---- types ----

type Side = "A" | "B";
type Verdict = "stable" | "revised" | "pending" | "ask" | "unknown";
type WorkspaceKind = "jj" | "git" | "tmp";

interface Workspace {
  side: Side;
  dir: string;
  kind: WorkspaceKind;
  cleanup: () => Promise<void>;
}

interface PiResult {
  exitCode: number;
  finalText: string;
  verdict: Verdict;
  verdictReason?: string;
  askUser?: { question: string; options?: string[] };
  stderr: string;
  turnsUsed: number;
  cost: number;
  usage: UsageStats;
  items: DisplayItem[];
  errorMessage?: string;
  stopReason?: string;
}

interface ModelChoice {
  provider: string;
  id: string;
  display: string;
}

// ---- vcs detection ----

function findRepoRoot(start: string, marker: ".jj" | ".git"): string | null {
  let cur = path.resolve(start);
  while (true) {
    if (fs.existsSync(path.join(cur, marker))) return cur;
    const parent = path.dirname(cur);
    if (parent === cur) return null;
    cur = parent;
  }
}

function detectVcs(cwd: string): { kind: WorkspaceKind; root: string } {
  const jjRoot = findRepoRoot(cwd, ".jj");
  if (jjRoot) return { kind: "jj", root: jjRoot };
  const gitRoot = findRepoRoot(cwd, ".git");
  if (gitRoot) return { kind: "git", root: gitRoot };
  return { kind: "tmp", root: cwd };
}

// ---- exec helper ----

interface ExecResult {
  stdout: string;
  stderr: string;
  code: number;
}

function exec(
  command: string,
  args: string[],
  options: {
    cwd?: string;
    env?: NodeJS.ProcessEnv;
    signal?: AbortSignal;
    input?: string;
  } = {},
): Promise<ExecResult> {
  return new Promise((resolve, reject) => {
    const proc = spawn(command, args, {
      cwd: options.cwd,
      env: options.env ?? process.env,
      stdio: [options.input !== undefined ? "pipe" : "ignore", "pipe", "pipe"],
    });
    let stdout = "";
    let stderr = "";
    proc.stdout?.on("data", (d) => {
      stdout += d.toString();
    });
    proc.stderr?.on("data", (d) => {
      stderr += d.toString();
    });
    proc.on("close", (code) => resolve({ stdout, stderr, code: code ?? 0 }));
    proc.on("error", (err) => reject(err));
    if (options.signal) {
      const onAbort = () => proc.kill("SIGTERM");
      if (options.signal.aborted) onAbort();
      else options.signal.addEventListener("abort", onAbort, { once: true });
    }
    if (options.input !== undefined && proc.stdin) {
      proc.stdin.write(options.input);
      proc.stdin.end();
    }
  });
}

// ---- file tree copy (rsync replacement) ----

async function copyTree(
  src: string,
  dst: string,
  excludesTopLevel: string[],
): Promise<void> {
  const exSet = new Set(excludesTopLevel);
  const srcAbs = path.resolve(src);
  await fs.promises.cp(srcAbs, dst, {
    recursive: true,
    force: true,
    errorOnExist: false,
    // verbatimSymlinks: copy symlinks as-is without resolving target.
    // dereference:false alone is not enough — fs.cp still stats deeper paths,
    // which throws ENOENT on broken/relative symlinks (e.g. sops-nix layout).
    dereference: false,
    verbatimSymlinks: true,
    filter: (s) => {
      const rel = path.relative(srcAbs, s);
      if (!rel) return true;
      const top = rel.split(path.sep)[0];
      return !exSet.has(top);
    },
  });
}

// ---- workspace creation ----

async function createWorkspace(
  side: Side,
  cwd: string,
  baseTmp: string,
  runId: string,
  vcs: { kind: WorkspaceKind; root: string },
): Promise<Workspace> {
  const dir = path.join(baseTmp, side);

  if (vcs.kind === "jj") {
    // unique per-run workspace name avoids collisions with stale leftovers
    const wsName = `pi-pong-${runId}-${side}`;
    const r = await exec("jj", ["workspace", "add", "--name", wsName, dir], {
      cwd: vcs.root,
    });
    if (r.code !== 0) throw new Error(`jj workspace add failed: ${r.stderr}`);
    return {
      side,
      dir,
      kind: "jj",
      cleanup: async () => {
        await exec("jj", ["workspace", "forget", wsName], {
          cwd: vcs.root,
        }).catch(() => {});
        await fs.promises.rm(dir, { recursive: true, force: true });
      },
    };
  }

  if (vcs.kind === "git") {
    const r = await exec("git", ["worktree", "add", "--detach", dir, "HEAD"], {
      cwd: vcs.root,
    });
    if (r.code !== 0) throw new Error(`git worktree add failed: ${r.stderr}`);
    return {
      side,
      dir,
      kind: "git",
      cleanup: async () => {
        await exec("git", ["worktree", "remove", "--force", dir], {
          cwd: vcs.root,
        }).catch(() => {});
      },
    };
  }

  // tmp: copy cwd -> dir using node fs.cp (no rsync dependency)
  await fs.promises.mkdir(dir, { recursive: true });
  await copyTree(cwd, dir, RSYNC_EXCLUDES);
  return {
    side,
    dir,
    kind: "tmp",
    cleanup: async () => {
      await fs.promises.rm(dir, { recursive: true, force: true });
    },
  };
}

// ---- diffs ----

async function getDiff(ws: Workspace, originalCwd: string): Promise<string> {
  if (ws.kind === "jj") {
    const r = await exec("jj", ["diff", "--git", "--no-pager"], {
      cwd: ws.dir,
    });
    return r.stdout;
  }
  if (ws.kind === "git") {
    const r = await exec("git", ["diff", "HEAD"], { cwd: ws.dir });
    return r.stdout;
  }
  // tmp: diff against original
  const args = ["-ruN"];
  for (const ex of RSYNC_EXCLUDES) {
    args.push("--exclude", ex);
  }
  args.push(originalCwd, ws.dir);
  const r = await exec("diff", args);
  return r.stdout;
}

// ---- pi subprocess ----

function parseVerdict(text: string): {
  verdict: Verdict;
  reason?: string;
  askUser?: { question: string; options?: string[] };
} {
  const askMatch = text.match(ASK_USER_RE);
  if (askMatch) {
    const question = askMatch[1].trim();
    const optMatch = text.match(ASK_OPTIONS_RE);
    const options = optMatch
      ? optMatch[1]
          .split("|")
          .map((s) => s.trim())
          .filter(Boolean)
      : undefined;
    return { verdict: "ask", askUser: { question, options } };
  }
  const m = text.match(VERDICT_RE);
  if (!m) return { verdict: "unknown" };
  const raw = m[1].toLowerCase();
  // normalize: agree -> stable, disagree -> revised
  const v: Verdict =
    raw === "agree"
      ? "stable"
      : raw === "disagree"
        ? "revised"
        : (raw as Verdict);
  return { verdict: v, reason: m[2]?.trim() || undefined };
}

function getPiInvocation(args: string[]): {
  command: string;
  args: string[];
} {
  const currentScript = process.argv[1];
  const isBunVirtualScript = currentScript?.startsWith("/$bunfs/root/");
  if (currentScript && !isBunVirtualScript && fs.existsSync(currentScript)) {
    return { command: process.execPath, args: [currentScript, ...args] };
  }
  const execName = path.basename(process.execPath).toLowerCase();
  const isGenericRuntime = /^(node|bun)(\.exe)?$/.test(execName);
  if (!isGenericRuntime) {
    return { command: process.execPath, args };
  }
  return { command: "pi", args };
}

type DisplayItem =
  | { type: "text"; text: string }
  | { type: "toolCall"; name: string; args: Record<string, unknown> };

interface UsageStats {
  input: number;
  output: number;
  cacheRead: number;
  cacheWrite: number;
  cost: number;
  contextTokens: number;
  turns: number;
}

interface ProgressSnapshot {
  turns: number;
  lastText: string;
  lastTool: { name: string; args: Record<string, unknown> } | undefined;
  items: DisplayItem[];
  usage: UsageStats;
}

function formatTokens(count: number): string {
  if (count < 1000) return count.toString();
  if (count < 10000) return `${(count / 1000).toFixed(1)}k`;
  if (count < 1000000) return `${Math.round(count / 1000)}k`;
  return `${(count / 1000000).toFixed(1)}M`;
}

function formatUsageStats(usage: UsageStats, model?: string): string {
  const parts: string[] = [];
  if (usage.turns)
    parts.push(`${usage.turns} turn${usage.turns > 1 ? "s" : ""}`);
  if (usage.input) parts.push(`↑${formatTokens(usage.input)}`);
  if (usage.output) parts.push(`↓${formatTokens(usage.output)}`);
  if (usage.cacheRead) parts.push(`R${formatTokens(usage.cacheRead)}`);
  if (usage.cacheWrite) parts.push(`W${formatTokens(usage.cacheWrite)}`);
  if (usage.cost) parts.push(`$${usage.cost.toFixed(4)}`);
  if (usage.contextTokens > 0)
    parts.push(`ctx:${formatTokens(usage.contextTokens)}`);
  if (model) parts.push(model);
  return parts.join(" ");
}

function formatToolCall(
  toolName: string,
  args: Record<string, unknown>,
  themeFg: (color: any, text: string) => string,
): string {
  const shortenPath = (p: string) => {
    const home = os.homedir();
    return p.startsWith(home) ? `~${p.slice(home.length)}` : p;
  };
  switch (toolName) {
    case "bash": {
      const command = (args.command as string) || "...";
      const preview =
        command.length > 60 ? `${command.slice(0, 60)}...` : command;
      return themeFg("muted", "$ ") + themeFg("toolOutput", preview);
    }
    case "read": {
      const rawPath = (args.file_path || args.path || "...") as string;
      return (
        themeFg("muted", "read ") + themeFg("accent", shortenPath(rawPath))
      );
    }
    case "write": {
      const rawPath = (args.file_path || args.path || "...") as string;
      const content = (args.content || "") as string;
      const lines = content.split("\n").length;
      let text =
        themeFg("muted", "write ") + themeFg("accent", shortenPath(rawPath));
      if (lines > 1) text += themeFg("dim", ` (${lines} lines)`);
      return text;
    }
    case "edit": {
      const rawPath = (args.file_path || args.path || "...") as string;
      return (
        themeFg("muted", "edit ") + themeFg("accent", shortenPath(rawPath))
      );
    }
    case "ls": {
      const rawPath = (args.path || ".") as string;
      return themeFg("muted", "ls ") + themeFg("accent", shortenPath(rawPath));
    }
    case "grep": {
      const pattern = (args.pattern || "") as string;
      const rawPath = (args.path || ".") as string;
      return (
        themeFg("muted", "grep ") +
        themeFg("accent", `/${pattern}/`) +
        themeFg("dim", ` in ${shortenPath(rawPath)}`)
      );
    }
    case "find": {
      const pattern = (args.pattern || "*") as string;
      const rawPath = (args.path || ".") as string;
      return (
        themeFg("muted", "find ") +
        themeFg("accent", pattern) +
        themeFg("dim", ` in ${shortenPath(rawPath)}`)
      );
    }
    default: {
      const argsStr = JSON.stringify(args);
      const preview =
        argsStr.length > 50 ? `${argsStr.slice(0, 50)}...` : argsStr;
      return themeFg("accent", toolName) + themeFg("dim", ` ${preview}`);
    }
  }
}

// extensions to forward into child processes (resolved at parent location).
// keep --no-extensions on but explicitly load these via -e, so we get the
// targeted behaviors without pulling in everything (e.g. safety-net confirms
// would break in -p mode).
const FORWARDED_EXTENSIONS = ["pi-to-PI.ts"];

function resolveForwardedExtensions(): string[] {
  const dirs = [
    path.join(os.homedir(), ".pi", "agent", "extensions"),
    path.join(process.cwd(), ".pi", "extensions"),
  ];
  const found: string[] = [];
  for (const name of FORWARDED_EXTENSIONS) {
    for (const dir of dirs) {
      const candidate = path.join(dir, name);
      if (fs.existsSync(candidate)) {
        found.push(candidate);
        break;
      }
    }
  }
  return found;
}

function runPi(
  model: string,
  prompt: string,
  cwd: string,
  signal: AbortSignal | undefined,
  onProgress: (snap: ProgressSnapshot) => void,
  logFile: string | undefined,
): Promise<PiResult> {
  return new Promise((resolve) => {
    const args = ["--mode", "json", "-p", "--no-session", "--no-extensions"];
    for (const extPath of resolveForwardedExtensions()) {
      args.push("-e", extPath);
    }
    args.push("--model", model, prompt);
    const env = { ...process.env, PI_PONG_CHILD: "1" };
    const invocation = getPiInvocation(args);
    const proc = spawn(invocation.command, invocation.args, {
      cwd,
      env,
      stdio: ["ignore", "pipe", "pipe"],
    });
    const logStream = logFile
      ? fs.createWriteStream(logFile, { flags: "a" })
      : undefined;
    if (logStream) {
      logStream.write(`\n=== runPi model=${model} cwd=${cwd} ===\n`);
      logStream.write(
        `cmd: ${invocation.command} ${invocation.args.join(" ")}\n\n`,
      );
    }

    let buffer = "";
    let stderr = "";
    let finalText = "";
    let turnsUsed = 0;
    let aborted = false;
    let stopReason: string | undefined;
    let errorMessage: string | undefined;
    const items: DisplayItem[] = [];
    const usage: UsageStats = {
      input: 0,
      output: 0,
      cacheRead: 0,
      cacheWrite: 0,
      cost: 0,
      contextTokens: 0,
      turns: 0,
    };

    const handleLine = (line: string) => {
      if (!line.trim()) return;
      let event: any;
      try {
        event = JSON.parse(line);
      } catch {
        return;
      }
      if (event.type === "message_end" && event.message) {
        const msg = event.message as Message;
        if (msg.role === "assistant") {
          turnsUsed++;
          usage.turns = turnsUsed;
          const u = msg.usage;
          if (u) {
            usage.input += u.input ?? 0;
            usage.output += u.output ?? 0;
            usage.cacheRead += u.cacheRead ?? 0;
            usage.cacheWrite += u.cacheWrite ?? 0;
            usage.cost += u.cost?.total ?? 0;
            usage.contextTokens = u.totalTokens ?? usage.contextTokens;
          }
          if ((msg as any).stopReason) stopReason = (msg as any).stopReason;
          if ((msg as any).errorMessage)
            errorMessage = (msg as any).errorMessage;
          let lastTool:
            | { name: string; args: Record<string, unknown> }
            | undefined;
          for (const part of msg.content) {
            if (part.type === "text" && part.text) {
              finalText = part.text;
              items.push({ type: "text", text: part.text });
            }
            if (part.type === "toolCall") {
              const name = (part as any).name as string;
              const args = ((part as any).arguments ?? {}) as Record<
                string,
                unknown
              >;
              lastTool = { name, args };
              items.push({ type: "toolCall", name, args });
            }
          }
          onProgress({
            turns: turnsUsed,
            lastText: finalText,
            lastTool,
            items: [...items],
            usage: { ...usage },
          });
        }
      }
    };

    proc.stdout.on("data", (d) => {
      const s = d.toString();
      logStream?.write(s);
      buffer += s;
      const lines = buffer.split("\n");
      buffer = lines.pop() ?? "";
      for (const l of lines) handleLine(l);
    });
    proc.stderr.on("data", (d) => {
      const s = d.toString();
      logStream?.write(`[stderr] ${s}`);
      stderr += s;
    });

    proc.on("close", (code) => {
      if (buffer.trim()) handleLine(buffer);
      logStream?.write(
        `\n=== exit code=${code} stopReason=${stopReason ?? ""} ===\n`,
      );
      logStream?.end();
      const { verdict, reason, askUser } = parseVerdict(finalText);
      resolve({
        exitCode: code ?? 0,
        finalText,
        verdict: aborted ? "unknown" : verdict,
        verdictReason: reason,
        askUser,
        stderr,
        turnsUsed,
        cost: usage.cost,
        usage: { ...usage },
        items: [...items],
        stopReason,
        errorMessage,
      });
    });

    proc.on("error", () => {
      resolve({
        exitCode: 1,
        finalText: "",
        usage: { ...usage },
        items: [...items],
        verdict: "unknown",
        stderr: stderr || "spawn error",
        turnsUsed: 0,
        cost: 0,
      });
    });

    if (signal) {
      const onAbort = () => {
        aborted = true;
        proc.kill("SIGTERM");
        setTimeout(() => {
          if (!proc.killed) proc.kill("SIGKILL");
        }, 3000);
      };
      if (signal.aborted) onAbort();
      else signal.addEventListener("abort", onAbort, { once: true });
    }
  });
}

// ---- prompts ----

function clarificationsBlock(
  clarifications: { question: string; answer: string }[],
): string {
  if (clarifications.length === 0) return "";
  let s = "\n# User clarifications (apply to your work)\n\n";
  for (const c of clarifications) {
    s += `- Q: ${c.question}\n  A: ${c.answer}\n`;
  }
  return s;
}

const ROUND0_PROMPT = (
  task: string,
  clarifications: { question: string; answer: string }[],
) => `# Task

${task}
${clarificationsBlock(clarifications)}
# Scope (IMPORTANT)

- Edit ONLY files directly required by the task. Do NOT modify unrelated files, config, generators, secrets, or vars.
- If the task references a specific file or directory (e.g. via @path), keep changes inside that path unless absolutely necessary.
- Do NOT run commands that mutate state outside this workspace (no \`clan vars generate\`, no \`nix-store\` writes, no system services).
- Read freely to understand context, but every \`write\`/\`edit\` must be justifiable as part of the task.

# Instructions

You are collaborating with another AI model on this task. Each of you works in your own isolated workspace (this directory). You will independently produce a first solution; afterwards, you will both critique each other and iterate until you converge.

For this round, implement the task by editing files in the current working directory. Use the available tools (read, write, edit, bash, etc.).

If the task is genuinely ambiguous and you need a decision from the human user before proceeding, you can ask a clarifying question. End your message with EXACTLY:

=== ASK_USER: <one clear question> ===

Optionally followed by a second line listing concrete choices:

=== OPTIONS: option a | option b | option c ===

Use this sparingly — only when you cannot reasonably proceed without input.

Otherwise, when you are done with this round, end your final assistant message with EXACTLY:

=== VERDICT: pending ===

(In later rounds you'll get to compare against the other model and either keep your work as-is or revise it.)
`;

const PINGPONG_PROMPT = (
  task: string,
  diffSelf: string,
  diffOther: string,
  otherVerdictReason: string | undefined,
  clarifications: { question: string; answer: string }[],
) => `# Task

${task}
${clarificationsBlock(clarifications)}
# Your current solution (diff vs. baseline in your workspace)

\`\`\`diff
${diffSelf || "(no changes yet)"}
\`\`\`

# The other model's current solution (diff vs. its baseline)

\`\`\`diff
${diffOther || "(no changes yet)"}
\`\`\`

${otherVerdictReason ? `\n# Other model's last verdict reason\n\n${otherVerdictReason}\n` : ""}

# Scope (IMPORTANT)

- Edit ONLY files directly required by the task. Do NOT touch unrelated files, config, generators, secrets, or vars.
- If the task references a specific file or directory, keep changes scoped to it unless absolutely necessary.
- Read freely to understand the other solution's diff; only use \`write\`/\`edit\` for your own task-relevant changes.

# Instructions

You are ping-ponging with another AI model toward convergence. Each turn, you can either keep your workspace as-is or refine it by incorporating ideas from the other solution.

End your message with EXACTLY ONE of these markers:

  === VERDICT: stable ===
    means: you did NOT change any files this turn. your workspace is final from your perspective. (use this when the other solution is good enough, or when your own solution is already as good as it gets and you wouldn't pull anything from theirs.)

  === VERDICT: revised: <one-line reason> ===
    means: you edited files in YOUR workspace this turn (incorporated ideas from the other model and/or fixed issues). round will continue.

  === ASK_USER: <one clear question> ===
    use only when you genuinely need a human decision (ambiguous requirement, preference, etc.) before you can proceed. optional second line:
    === OPTIONS: option a | option b | option c ===
    after the user answers, you'll be prompted again to apply the answer. do not use this for trivial uncertainty.

Convergence happens when two consecutive turns both report "stable". Don't bikeshed cosmetic differences. Mark stable as soon as you genuinely have nothing more to improve.
`;

// ---- main flow ----

async function pickModelB(ctx: ExtensionContext): Promise<ModelChoice | null> {
  const available = ctx.modelRegistry.getAvailable();
  const choices: ModelChoice[] = [];
  for (const m of available) {
    // skip current model — we want a different opinion
    if (ctx.model && m.provider === ctx.model.provider && m.id === ctx.model.id)
      continue;
    choices.push({
      provider: m.provider,
      id: m.id,
      display: `${m.provider}/${m.id}`,
    });
  }
  if (choices.length === 0) {
    ctx.ui.notify("no other models available", "error");
    return null;
  }

  const current = ctx.model
    ? `${ctx.model.provider}/${ctx.model.id}`
    : "(none)";
  return await ctx.ui.custom<ModelChoice | null>((tui, theme, _kb, done) => {
    const container = new Container();
    container.addChild(
      new Text(
        theme.bold(theme.fg("accent", "🏓 pi-pong — pick model B")),
        0,
        0,
      ),
    );
    container.addChild(
      new Text(theme.fg("dim", `  current model (A) = ${current}`), 0, 0),
    );
    container.addChild(new Text("", 0, 0));

    const items: SelectItem[] = choices.map((c) => ({
      value: c.display,
      label: c.display,
    }));
    const visible = Math.min(items.length, 15);
    const list = new SelectList(items, visible, {
      selectedPrefix: (t) => theme.bold(theme.fg("accent", t)),
      selectedText: (t) => theme.bold(theme.fg("accent", t)),
      description: (t) => theme.fg("muted", t),
      scrollInfo: (t) => theme.fg("dim", t),
      noMatch: (t) => theme.fg("warning", t),
    });
    list.onSelect = (item) => {
      const c = choices.find((x) => x.display === item.value) ?? null;
      done(c);
    };
    list.onCancel = () => done(null);
    container.addChild(list);
    container.addChild(new Text("", 0, 0));
    container.addChild(
      new Text(
        theme.fg("dim", "  ↑↓ navigate • enter select • esc cancel"),
        0,
        0,
      ),
    );

    return {
      render: (w) => container.render(w),
      invalidate: () => container.invalidate(),
      handleInput: (data) => {
        list.handleInput(data);
        tui.requestRender();
      },
    };
  });
}

function modelSpec(provider: string, id: string): string {
  return `${provider}/${id}`;
}

function sideFailed(r: PiResult): boolean {
  return (
    r.exitCode !== 0 ||
    r.stopReason === "error" ||
    r.stopReason === "aborted" ||
    !!r.errorMessage
  );
}

// preflight ping: tiny prompt to each model so quota/auth errors surface in
// seconds instead of after a full round 0. uses --no-tools to avoid any side
// effects in the parent cwd.
async function preflightModel(
  model: string,
  cwd: string,
  signal: AbortSignal | undefined,
): Promise<{ ok: boolean; error?: string }> {
  return new Promise((resolve) => {
    const args = [
      "--mode",
      "json",
      "-p",
      "--no-session",
      "--no-extensions",
      "--no-tools",
    ];
    for (const extPath of resolveForwardedExtensions()) {
      args.push("-e", extPath);
    }
    args.push("--model", model, "ping");
    const env = { ...process.env, PI_PONG_CHILD: "1" };
    const invocation = getPiInvocation(args);
    const proc = spawn(invocation.command, invocation.args, {
      cwd,
      env,
      stdio: ["ignore", "pipe", "pipe"],
    });
    let buffer = "";
    let stderr = "";
    let errorMessage: string | undefined;
    let stopReason: string | undefined;
    let aborted = false;

    const handleLine = (line: string) => {
      if (!line.trim()) return;
      try {
        const event = JSON.parse(line);
        if (event.type === "message_end" && event.message) {
          const m = event.message as any;
          if (m.errorMessage) errorMessage = m.errorMessage;
          if (m.stopReason) stopReason = m.stopReason;
        }
      } catch {
        /* ignore non-json */
      }
    };

    proc.stdout.on("data", (d) => {
      buffer += d.toString();
      const lines = buffer.split("\n");
      buffer = lines.pop() ?? "";
      for (const l of lines) handleLine(l);
    });
    proc.stderr.on("data", (d) => {
      stderr += d.toString();
    });
    proc.on("close", (code) => {
      if (buffer.trim()) handleLine(buffer);
      const ok =
        !aborted &&
        code === 0 &&
        !errorMessage &&
        stopReason !== "error" &&
        stopReason !== "aborted";
      resolve({
        ok,
        error: errorMessage ?? (stderr ? stderr.slice(0, 300) : undefined),
      });
    });
    proc.on("error", (err) => {
      resolve({ ok: false, error: err.message });
    });

    if (signal) {
      const onAbort = () => {
        aborted = true;
        proc.kill("SIGTERM");
      };
      if (signal.aborted) onAbort();
      else signal.addEventListener("abort", onAbort, { once: true });
    }
  });
}

async function applyWorkspace(
  ws: Workspace,
  cwd: string,
  ctx: ExtensionContext,
): Promise<boolean> {
  // copy chosen workspace -> cwd via fs.cp, skipping vcs metadata + excludes.
  // note: this overlays files but does not delete files that exist only in
  // cwd, mirroring rsync without --delete.
  try {
    await copyTree(ws.dir, cwd, RSYNC_EXCLUDES);
    return true;
  } catch (err) {
    ctx.ui.notify(`apply failed: ${(err as Error).message}`, "error");
    return false;
  }
}

async function writeDiffToFile(
  diff: string,
  label: string,
  baseDir: string,
): Promise<string> {
  const file = path.join(baseDir, `final-${label}.diff`);
  await fs.promises.writeFile(file, diff, "utf-8");
  return file;
}

export default function (pi: ExtensionAPI) {
  pi.registerCommand("pong", {
    description: "ping-pong two models on a task until they converge",
    handler: async (args, ctx) => {
      if (!ctx.hasUI) {
        ctx.ui.notify("pi-pong requires interactive mode", "error");
        return;
      }
      if (process.env.PI_PONG_CHILD) {
        ctx.ui.notify(
          "pi-pong: refusing to recurse inside a pong child",
          "error",
        );
        return;
      }

      let task = (args ?? "").trim();
      if (!task) {
        const editorText = ctx.ui.getEditorText().trim();
        if (editorText) {
          task = editorText;
          ctx.ui.setEditorText("");
        } else {
          const input = await ctx.ui.input(
            "task for pi-pong:",
            "describe what should be solved",
          );
          if (!input || !input.trim()) return;
          task = input.trim();
        }
      }

      if (!ctx.model) {
        ctx.ui.notify("no current model set", "error");
        return;
      }
      const modelA: ModelChoice = {
        provider: ctx.model.provider,
        id: ctx.model.id,
        display: `${ctx.model.provider}/${ctx.model.id}`,
      };

      const modelB = await pickModelB(ctx);
      if (!modelB) {
        ctx.ui.notify("cancelled", "info");
        return;
      }

      // ---- preflight: ping each model so quota/auth errors surface fast ----
      ctx.ui.setStatus("pi-pong", "preflight: pinging both models…");
      ctx.ui.notify("🏓 preflight: pinging both models…", "info");
      const [pingA, pingB] = await Promise.all([
        preflightModel(
          modelSpec(modelA.provider, modelA.id),
          ctx.cwd,
          ctx.signal,
        ),
        preflightModel(
          modelSpec(modelB.provider, modelB.id),
          ctx.cwd,
          ctx.signal,
        ),
      ]);
      ctx.ui.setStatus("pi-pong", undefined);
      if (!pingA.ok || !pingB.ok) {
        if (!pingA.ok)
          ctx.ui.notify(
            `❌ A (${modelA.display}) preflight failed: ${pingA.error ?? "unknown"}`,
            "error",
          );
        if (!pingB.ok)
          ctx.ui.notify(
            `❌ B (${modelB.display}) preflight failed: ${pingB.error ?? "unknown"}`,
            "error",
          );
        ctx.ui.notify(
          "aborted before workspace setup. fix the failing model(s) and retry.",
          "warning",
        );
        return;
      }
      ctx.ui.notify("✅ preflight ok — both models reachable", "info");

      const vcs = detectVcs(ctx.cwd);
      const ts = new Date().toISOString().replace(/[:.]/g, "-");
      const baseTmp = path.join(os.tmpdir(), `pi-pong-${ts}`);
      await fs.promises.mkdir(baseTmp, { recursive: true });

      ctx.ui.notify(
        `🏓 pi-pong starting (vcs=${vcs.kind}, A=${modelA.display}, B=${modelB.display})`,
        "info",
      );
      ctx.ui.setStatus("pi-pong", `setup ${vcs.kind} workspaces…`);

      // ---- live progress widget ----
      type SideState = {
        model: string;
        status: "setup" | "running" | "done" | "failed";
        turns: number;
        usage: UsageStats;
        items: DisplayItem[];
        verdict: Verdict;
        error?: string;
      };
      const initSide = (model: string): SideState => ({
        model,
        status: "setup",
        turns: 0,
        usage: {
          input: 0,
          output: 0,
          cacheRead: 0,
          cacheWrite: 0,
          cost: 0,
          contextTokens: 0,
          turns: 0,
        },
        items: [],
        verdict: "pending",
      });
      const sideState: Record<Side, SideState> = {
        A: initSide(modelA.display),
        B: initSide(modelB.display),
      };
      let phase = "starting";
      const RECENT_ITEMS = 4;
      const truncate = (s: string, n: number) =>
        s.length > n ? `${s.slice(0, n)}…` : s;

      const renderWidget = (
        _tui: any,
        theme: any,
      ): import("@mariozechner/pi-tui").Component => {
        const container = new Container();
        container.addChild(
          new Text(
            theme.bold(theme.fg("accent", `🏓 pi-pong — ${phase}`)),
            0,
            0,
          ),
        );
        for (const side of ["A", "B"] as const) {
          const s = sideState[side];
          const statusIcon =
            s.status === "done"
              ? theme.fg("success", "✅")
              : s.status === "failed"
                ? theme.fg("error", "❌")
                : s.status === "running"
                  ? theme.fg("warning", "🔄")
                  : theme.fg("muted", "⋯");
          const verdictColor =
            s.verdict === "stable"
              ? "success"
              : s.verdict === "revised"
                ? "warning"
                : "muted";
          const usageStr = formatUsageStats(s.usage);
          let header = `${statusIcon} ${theme.bold(theme.fg("toolTitle", side))}: ${theme.fg("accent", s.model)}`;
          if (usageStr) header += ` ${theme.fg("dim", `[${usageStr}]`)}`;
          header += ` ${theme.fg(verdictColor, `verdict:${s.verdict}`)}`;
          container.addChild(new Text(header, 0, 0));

          if (s.error) {
            container.addChild(
              new Text(
                `   ${theme.fg("error", `⚠ ${truncate(s.error, 200)}`)}`,
                0,
                0,
              ),
            );
            continue;
          }

          const recent = s.items.slice(-RECENT_ITEMS);
          for (const item of recent) {
            if (item.type === "toolCall") {
              const formatted = formatToolCall(
                item.name,
                item.args,
                theme.fg.bind(theme),
              );
              container.addChild(
                new Text(`   ${theme.fg("muted", "→")} ${formatted}`, 0, 0),
              );
            } else {
              const preview = truncate(item.text.replace(/\s+/g, " "), 120);
              container.addChild(
                new Text(`   ${theme.fg("dim", preview)}`, 0, 0),
              );
            }
          }
          if (s.items.length > RECENT_ITEMS) {
            container.addChild(
              new Text(
                `   ${theme.fg("dim", `… +${s.items.length - RECENT_ITEMS} earlier`)}`,
                0,
                0,
              ),
            );
          }
        }
        return container;
      };
      const refreshWidget = () => ctx.ui.setWidget("pi-pong", renderWidget);
      refreshWidget();
      const onSideProgress = (side: Side) => (snap: ProgressSnapshot) => {
        const s = sideState[side];
        s.status = "running";
        s.turns = snap.turns;
        s.usage = snap.usage;
        s.items = snap.items;
        refreshWidget();
      };

      let wsARef: Workspace | null = null;
      let wsBRef: Workspace | null = null;
      const signal = ctx.signal;
      let totalCost = 0;

      try {
        wsARef = await createWorkspace("A", ctx.cwd, baseTmp, ts, vcs);
        wsBRef = await createWorkspace("B", ctx.cwd, baseTmp, ts, vcs);
        const wsA: Workspace = wsARef;
        const wsB: Workspace = wsBRef;

        ctx.ui.setStatus("pi-pong", "round 0 — both implementing in parallel…");
        const logA = path.join(baseTmp, "log-A.txt");
        const logB = path.join(baseTmp, "log-B.txt");
        ctx.ui.notify(
          `🏓 round 0 — both models implementing. logs: ${logA} / ${logB}`,
          "info",
        );
        phase = "round 0 — both implementing";
        refreshWidget();
        const clarifications: { question: string; answer: string }[] = [];
        const askUserHelper = async (
          side: Side,
          ask: { question: string; options?: string[] },
        ): Promise<boolean> => {
          ctx.ui.notify(
            `❔ ${side} (${(side === "A" ? modelA : modelB).display}) asks: ${ask.question}`,
            "info",
          );
          let answer: string | undefined;
          if (ask.options && ask.options.length > 0) {
            answer = await ctx.ui.select(
              `🏓 ${side}: ${ask.question}`,
              ask.options,
            );
          } else {
            answer = await ctx.ui.input(`🏓 ${side}: ${ask.question}`, "");
          }
          if (!answer || !answer.trim()) {
            ctx.ui.notify("no answer provided — aborting pi-pong", "warning");
            return false;
          }
          clarifications.push({
            question: ask.question,
            answer: answer.trim(),
          });
          return true;
        };

        const round0Prompt = ROUND0_PROMPT(task, clarifications);
        const finalizeSide = (side: Side, r: PiResult) => {
          sideState[side].status = sideFailed(r) ? "failed" : "done";
          sideState[side].verdict = r.verdict;
          if (r.errorMessage) sideState[side].error = r.errorMessage;
          refreshWidget();
        };
        const [r0A, r0B] = await Promise.all([
          runPi(
            modelSpec(modelA.provider, modelA.id),
            round0Prompt,
            wsA.dir,
            signal,
            onSideProgress("A"),
            logA,
          ).then((r) => {
            finalizeSide("A", r);
            return r;
          }),
          runPi(
            modelSpec(modelB.provider, modelB.id),
            round0Prompt,
            wsB.dir,
            signal,
            onSideProgress("B"),
            logB,
          ).then((r) => {
            finalizeSide("B", r);
            return r;
          }),
        ]);
        totalCost += r0A.cost + r0B.cost;

        if (sideFailed(r0A) || sideFailed(r0B)) {
          if (sideFailed(r0A))
            ctx.ui.notify(
              `❌ A (${modelA.display}) failed: ${r0A.errorMessage ?? r0A.stderr.slice(0, 300) ?? "unknown"}`,
              "error",
            );
          if (sideFailed(r0B))
            ctx.ui.notify(
              `❌ B (${modelB.display}) failed: ${r0B.errorMessage ?? r0B.stderr.slice(0, 300) ?? "unknown"}`,
              "error",
            );
          return;
        }

        const fmtCost = (c: number) => (c > 0 ? ` / $${c.toFixed(4)}` : "");
        ctx.ui.notify(
          `round 0 done. A: ${r0A.turnsUsed} turns${fmtCost(r0A.cost)}; ` +
            `B: ${r0B.turnsUsed} turns${fmtCost(r0B.cost)}`,
          "info",
        );

        // round 0 may also yield ASK_USER — handle before ping-pong loop
        for (const [side, r0, ws] of [
          ["A", r0A, wsA],
          ["B", r0B, wsB],
        ] as const) {
          if (r0.askUser) {
            const ok = await askUserHelper(side, r0.askUser);
            if (!ok) return;
            // re-run that side with clarifications baked in
            ctx.ui.notify(`🏓 re-running ${side} with clarification…`, "info");
            const reLog = path.join(baseTmp, `log-round0-${side}-redo.txt`);
            const rr = await runPi(
              modelSpec(
                (side === "A" ? modelA : modelB).provider,
                (side === "A" ? modelA : modelB).id,
              ),
              ROUND0_PROMPT(task, clarifications),
              ws.dir,
              signal,
              onSideProgress(side as Side),
              reLog,
            );
            totalCost += rr.cost;
            finalizeSide(side as Side, rr);
            if (sideFailed(rr)) {
              ctx.ui.notify(
                `❌ ${side} re-run failed: ${rr.errorMessage ?? "unknown"}`,
                "error",
              );
              return;
            }
          }
        }

        let lastVerdict: Record<Side, Verdict> = { A: "pending", B: "pending" };
        let lastReason: Record<Side, string | undefined> = {
          A: undefined,
          B: undefined,
        };
        let activeSide: Side = "A"; // A starts ping-pong
        let converged = false;
        let turn = 0;
        const MAX_CLARIFICATIONS = 10;

        while (turn < MAX_TURNS) {
          if (signal?.aborted) break;
          if (lastVerdict.A === "stable" && lastVerdict.B === "stable") {
            converged = true;
            break;
          }
          turn++;
          const otherSide: Side = activeSide === "A" ? "B" : "A";
          const activeWs = activeSide === "A" ? wsA : wsB;
          const otherWs = otherSide === "A" ? wsA : wsB;
          const activeModel = activeSide === "A" ? modelA : modelB;

          ctx.ui.setStatus(
            "pi-pong",
            `turn ${turn} — ${activeSide} (${activeModel.display}) reviewing…`,
          );
          phase = `turn ${turn} — ${activeSide} active`;
          sideState[activeSide].status = "running";
          sideState[activeSide].turns = 0;
          refreshWidget();

          const diffSelf = await getDiff(activeWs, ctx.cwd);
          const diffOther = await getDiff(otherWs, ctx.cwd);

          const prompt = PINGPONG_PROMPT(
            task,
            diffSelf,
            diffOther,
            lastReason[otherSide],
            clarifications,
          );
          const turnLog = path.join(
            baseTmp,
            `log-turn-${turn}-${activeSide}.txt`,
          );
          ctx.ui.notify(
            `🏓 turn ${turn} — ${activeSide} (${activeModel.display}). log: ${turnLog}`,
            "info",
          );
          const r = await runPi(
            modelSpec(activeModel.provider, activeModel.id),
            prompt,
            activeWs.dir,
            signal,
            onSideProgress(activeSide),
            turnLog,
          );
          totalCost += r.cost;

          if (sideFailed(r)) {
            sideState[activeSide].status = "failed";
            sideState[activeSide].error = r.errorMessage;
            refreshWidget();
            ctx.ui.notify(
              `❌ turn ${turn} (${activeSide}) failed: ${r.errorMessage ?? r.stderr.slice(0, 300) ?? "unknown"}`,
              "error",
            );
            break;
          }

          // ASK_USER: pause, get answer, re-run same side without flipping
          if (r.askUser) {
            if (clarifications.length >= MAX_CLARIFICATIONS) {
              ctx.ui.notify(
                `⚠ hit ${MAX_CLARIFICATIONS} clarifications cap; ignoring further ASK_USER—treating turn as revised`,
                "warning",
              );
              lastVerdict[activeSide] = "revised";
              lastReason[activeSide] = "clarifications cap reached";
              sideState[activeSide].verdict = "revised";
              refreshWidget();
              activeSide = otherSide;
              continue;
            }
            const ok = await askUserHelper(activeSide, r.askUser);
            if (!ok) return;
            sideState[activeSide].verdict = "ask";
            refreshWidget();
            // do not flip side; re-run same side with new clarification
            turn--; // don't count the asking turn
            continue;
          }

          lastVerdict[activeSide] = r.verdict;
          lastReason[activeSide] = r.verdictReason;
          sideState[activeSide].status = "done";
          sideState[activeSide].verdict = r.verdict;
          refreshWidget();

          ctx.ui.notify(
            `turn ${turn}: ${activeSide} → ${r.verdict}${r.verdictReason ? ` (${r.verdictReason})` : ""}` +
              ` [${r.turnsUsed} turns${fmtCost(r.cost)}]`,
            "info",
          );

          activeSide = otherSide;
        }

        ctx.ui.setStatus("pi-pong", undefined);

        // ---- final selection ----

        const diffA = await getDiff(wsA, ctx.cwd);
        const diffB = await getDiff(wsB, ctx.cwd);
        const diffPathA = await writeDiffToFile(diffA, "A", baseTmp);
        const diffPathB = await writeDiffToFile(diffB, "B", baseTmp);

        let chosen: Workspace = wsA;

        if (converged) {
          ctx.ui.notify(
            `✅ converged after ${turn} turn(s)${totalCost > 0 ? `. total cost: $${totalCost.toFixed(4)}` : ""}`,
            "info",
          );
          // when both consecutive turns are "stable", A's workspace holds the
          // most recently endorsed version (A speaks first; B then sees A's
          // workspace and also says stable → B has implicitly endorsed A's).
          chosen = wsA;
        } else {
          ctx.ui.notify(
            `⚠ no convergence after ${turn} turn(s)${totalCost > 0 ? `. total cost: $${totalCost.toFixed(4)}` : ""}`,
            "warning",
          );
          ctx.ui.notify(`diff A: ${diffPathA}`, "info");
          ctx.ui.notify(`diff B: ${diffPathB}`, "info");

          const picked = await ctx.ui.select("pick final solution:", [
            `A (${modelA.display}) — ${diffA.split("\n").length} diff lines, last: ${lastVerdict.A}`,
            `B (${modelB.display}) — ${diffB.split("\n").length} diff lines, last: ${lastVerdict.B}`,
            "abort (apply nothing)",
          ]);
          if (!picked) return;
          if (picked.startsWith("A ")) chosen = wsA;
          else if (picked.startsWith("B ")) chosen = wsB;
          else return;
        }
        // silence unused warning when convergence path is taken
        void wsB;

        // ---- apply ----

        const chosenSide = chosen.side;
        const chosenDiff = chosenSide === "A" ? diffA : diffB;
        const lineCount = chosenDiff.split("\n").length;

        const apply = await ctx.ui.confirm(
          `apply solution ${chosenSide} to cwd?`,
          `${lineCount} diff lines. workspace: ${chosen.dir}\n` +
            `diff saved at: ${chosenSide === "A" ? diffPathA : diffPathB}\n\n` +
            `this rsyncs ${chosen.dir}/ → ${ctx.cwd}/ (excluding ${RSYNC_EXCLUDES.join(", ")})`,
        );
        if (apply) {
          const ok = await applyWorkspace(chosen, ctx.cwd, ctx);
          if (ok)
            ctx.ui.notify(`✅ applied solution ${chosenSide} to cwd`, "info");
        } else {
          ctx.ui.notify(
            `not applied. workspaces preserved at ${baseTmp}`,
            "info",
          );
        }
      } catch (err) {
        ctx.ui.notify(`pi-pong error: ${(err as Error).message}`, "error");
      } finally {
        ctx.ui.setStatus("pi-pong", undefined);
        ctx.ui.setWidget("pi-pong", undefined);
        const cleanup = await ctx.ui.confirm(
          "cleanup workspaces?",
          `remove ${baseTmp} and any jj/git workspaces created?`,
        );
        if (cleanup) {
          if (wsARef) await wsARef.cleanup().catch(() => {});
          if (wsBRef) await wsBRef.cleanup().catch(() => {});
          await fs.promises
            .rm(baseTmp, { recursive: true, force: true })
            .catch(() => {});
          ctx.ui.notify("cleaned up", "info");
        } else {
          ctx.ui.notify(`workspaces left at ${baseTmp}`, "info");
        }
      }
    },
  });
}
