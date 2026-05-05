import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

type Command = {
  command: string;
  args: string[];
  title: string;
};

type Backend = {
  name: "jj" | "git";
  status: Command;
  log: Command;
  mechanics: string;
};

const STYLE = `
style:
- explain why the change exists, not every file touched.
- imperative mood.
- concise, lowercase, no conventional commit prefixes.
- use scope prefixes only when they add clarity, like docs:, vars:, or a component name.
- default to one-line messages; add a body only for useful rationale, caveats, or multi-part changes.

use the provided context. inspect the diff only when status/log is not enough to choose the commit message or split.

split only when the working copy covers clearly unrelated concerns. otherwise keep related multi-file changes together.
`.trim();

const BACKENDS: Backend[] = [
  {
    name: "jj",
    status: { command: "jj", args: ["status"], title: "jj status" },
    log: {
      command: "jj",
      args: ["log", "--limit", "5", "--no-graph"],
      title: "jj log --limit 5 --no-graph",
    },
    mechanics: `
mechanics:
- use jj commands.
- commit with jj commit so the completed change becomes @- and @ is empty.
- do not move bookmarks; /publish handles bookmarks.
- do not push; /publish handles publishing.
- do not use jj restore, git restore, or git checkout --.
- verify with jj status after committing.
`.trim(),
  },
  {
    name: "git",
    status: { command: "git", args: ["status"], title: "git status" },
    log: {
      command: "git",
      args: ["log", "--oneline", "-5"],
      title: "git log --oneline -5",
    },
    mechanics: `
mechanics:
- use git commands.
- commit staged changes if any exist.
- if nothing is staged, stage all changes with git add -A.
- if staged and unstaged changes both exist, preserve staging; include unstaged or untracked files only when they belong to the same change.
- do not push; /publish handles publishing.
- do not use git restore or git checkout --.
- verify with git status after committing.
`.trim(),
  },
];

function prompt(backend: Backend): string {
  return [
    `commit the current ${backend.name} repository.`,
    "",
    STYLE,
    "",
    backend.mechanics,
  ].join("\n");
}

function section(title: string, body: string): string {
  const text = body.trim();
  return [`## ${title}`, "", "```", text || "<empty>", "```"].join("\n");
}

async function detectBackend(
  pi: ExtensionAPI,
  cwd: string,
): Promise<Backend | undefined> {
  const jj = await pi.exec("jj", ["root"], { cwd, timeout: 5000 });
  if (jj.code === 0) return BACKENDS[0];

  const git = await pi.exec("git", ["rev-parse", "--show-toplevel"], {
    cwd,
    timeout: 5000,
  });
  if (git.code === 0) return BACKENDS[1];

  return undefined;
}

export default function (pi: ExtensionAPI) {
  pi.registerCommand("commit", {
    description: "commit with preloaded vcs context",
    handler: async (_args, ctx) => {
      const backend = await detectBackend(pi, ctx.cwd);
      if (!backend) {
        ctx.ui.notify("not a jj or git repo", "error");
        return;
      }

      const [status, log] = await Promise.all([
        pi.exec(backend.status.command, backend.status.args, {
          cwd: ctx.cwd,
          timeout: 5000,
        }),
        pi.exec(backend.log.command, backend.log.args, {
          cwd: ctx.cwd,
          timeout: 5000,
        }),
      ]);

      if (status.code !== 0) {
        ctx.ui.notify(
          `${backend.status.title} failed: ${status.stderr}`,
          "error",
        );
        return;
      }

      const context = [
        section(backend.status.title, status.stdout),
        section(backend.log.title, log.code === 0 ? log.stdout : log.stderr),
      ].join("\n\n");

      pi.sendUserMessage(`${prompt(backend)}\n\n${context}`, {
        deliverAs: "followUp",
      });
    },
  });
}
