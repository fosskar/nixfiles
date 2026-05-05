import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

type Backend = "jj" | "git";

type ExecResult = Awaited<ReturnType<ExtensionAPI["exec"]>>;

const REMOTES = ["origin", "rad"];

function remoteNames(output: string): Set<string> {
  return new Set(
    output
      .split("\n")
      .map((line) => line.trim().split(/\s+/, 1)[0])
      .filter(Boolean),
  );
}

function isJjClean(output: string): boolean {
  return output.includes("The working copy has no changes.");
}

function formatFailure(command: string, result: ExecResult): string {
  return [
    `${command} failed with exit code ${result.code}`,
    result.stdout.trim() ? `stdout:\n${result.stdout.trim()}` : undefined,
    result.stderr.trim() ? `stderr:\n${result.stderr.trim()}` : undefined,
  ]
    .filter(Boolean)
    .join("\n\n");
}

async function detectBackend(
  pi: ExtensionAPI,
  cwd: string,
): Promise<Backend | undefined> {
  const jj = await pi.exec("jj", ["root"], { cwd, timeout: 5000 });
  if (jj.code === 0) return "jj";

  const git = await pi.exec("git", ["rev-parse", "--show-toplevel"], {
    cwd,
    timeout: 5000,
  });
  if (git.code === 0) return "git";

  return undefined;
}

async function run(
  pi: ExtensionAPI,
  cwd: string,
  command: string,
  args: string[],
): Promise<ExecResult> {
  return pi.exec(command, args, { cwd, timeout: 120000 });
}

async function mustRun(
  pi: ExtensionAPI,
  cwd: string,
  command: string,
  args: string[],
): Promise<string | undefined> {
  const result = await run(pi, cwd, command, args);
  if (result.code === 0) return undefined;
  return formatFailure([command, ...args].join(" "), result);
}

async function publishJj(
  pi: ExtensionAPI,
  cwd: string,
  bookmark: string,
): Promise<string | undefined> {
  const status = await run(pi, cwd, "jj", ["status"]);
  if (status.code !== 0) return formatFailure("jj status", status);
  if (!isJjClean(status.stdout)) return "working copy has uncommitted changes";

  const nonEmptyParent = await run(pi, cwd, "jj", [
    "log",
    "-r",
    "@- & ~empty()",
    "--no-graph",
    "--limit",
    "1",
  ]);
  if (nonEmptyParent.code !== 0 || !nonEmptyParent.stdout.trim()) {
    return "@- is empty; not moving a bookmark to an empty change";
  }

  const remoteList = await run(pi, cwd, "jj", ["git", "remote", "list"]);
  if (remoteList.code !== 0)
    return formatFailure("jj git remote list", remoteList);

  const remotes = remoteNames(remoteList.stdout);
  if (!remotes.has("origin")) return "origin remote is not configured";
  const pushRemotes = REMOTES.filter((remote) => remotes.has(remote));

  let failure = await mustRun(pi, cwd, "jj", [
    "git",
    "fetch",
    "--remote",
    "origin",
  ]);
  if (failure) return failure;

  const remoteBookmark = await run(pi, cwd, "jj", [
    "log",
    "-r",
    `${bookmark}@origin`,
    "--no-graph",
    "--limit",
    "1",
  ]);
  if (remoteBookmark.code === 0 && remoteBookmark.stdout.trim()) {
    failure = await mustRun(pi, cwd, "jj", [
      "rebase",
      "-d",
      `${bookmark}@origin`,
    ]);
    if (failure) return failure;
  }

  failure = await mustRun(pi, cwd, "jj", [
    "bookmark",
    "set",
    bookmark,
    "-r",
    "@-",
  ]);
  if (failure) return failure;

  if (pushRemotes.includes("rad")) {
    failure = await mustRun(pi, cwd, "rad", ["node", "start"]);
    if (failure) return failure;
  }

  for (const remote of pushRemotes) {
    failure = await mustRun(pi, cwd, "jj", [
      "git",
      "push",
      "--remote",
      remote,
      "--bookmark",
      bookmark,
    ]);
    if (failure) return failure;
  }

  if (pushRemotes.includes("rad")) {
    failure = await mustRun(pi, cwd, "rad", ["sync"]);
    if (failure) return failure;
  }

  const verify = await run(pi, cwd, "jj", ["status"]);
  if (verify.code !== 0) return formatFailure("jj status", verify);
  return undefined;
}

async function publishGit(
  pi: ExtensionAPI,
  cwd: string,
  ref: string | undefined,
): Promise<string | undefined> {
  const status = await run(pi, cwd, "git", ["status", "--porcelain"]);
  if (status.code !== 0) return formatFailure("git status --porcelain", status);
  if (status.stdout.trim()) return "working tree has uncommitted changes";

  const remoteList = await run(pi, cwd, "git", ["remote"]);
  if (remoteList.code !== 0) return formatFailure("git remote", remoteList);

  const remotes = remoteNames(remoteList.stdout);
  if (!remotes.has("origin")) return "origin remote is not configured";

  if (!ref) {
    const failure = await mustRun(pi, cwd, "git", ["push"]);
    if (failure) return failure;
  }

  for (const remote of ref
    ? REMOTES.filter((remote) => remotes.has(remote))
    : []) {
    const failure = await mustRun(pi, cwd, "git", ["push", remote, ref]);
    if (failure) return failure;
  }

  const verify = await run(pi, cwd, "git", ["status", "--short"]);
  if (verify.code !== 0) return formatFailure("git status --short", verify);
  return undefined;
}

export default function (pi: ExtensionAPI) {
  pi.registerCommand("publish", {
    description: "publish current branch/bookmark",
    handler: async (args, ctx) => {
      const ref = args.trim() || undefined;
      const backend = await detectBackend(pi, ctx.cwd);
      if (!backend) {
        ctx.ui.notify("not a jj or git repo", "error");
        return;
      }

      const failure =
        backend === "jj"
          ? await publishJj(pi, ctx.cwd, ref ?? "main")
          : await publishGit(pi, ctx.cwd, ref);

      if (failure) {
        ctx.ui.notify(failure, "error");
        return;
      }

      ctx.ui.notify(
        ref ? `published ${backend} ${ref}` : `published ${backend}`,
        "success",
      );
    },
  });
}
