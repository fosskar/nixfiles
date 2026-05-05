import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

const STYLE = `
style:
- explain why the change exists, not every file touched.
- imperative mood.
- concise, lowercase, no conventional commit prefixes.
- use scope prefixes only when they add clarity, like docs:, vars:, or a component name.
- subject: imperative summary. body: short paragraph explaining why and any non-obvious tradeoffs. omit body for trivial mechanical changes (typo fixes, formatting, lockfile bumps).

use the provided context. inspect the diff only when status/log is not enough to choose the commit message or split.

split only when the working copy covers clearly unrelated concerns. otherwise keep related multi-file changes together.
`.trim();

const JJ_MECHANICS = `
mechanics:
- use jj commands.
- commit with jj commit so the completed change becomes @- and @ is empty.
- do not move bookmarks; /publish handles bookmarks.
- do not push; /publish handles publishing.
- do not use jj restore, git restore, or git checkout --.
- verify with jj status after committing.
`.trim();

const GIT_MECHANICS = `
mechanics:
- use git commands.
- commit staged changes if any exist.
- if nothing is staged, stage all changes with git add -A.
- if staged and unstaged changes both exist, preserve staging; include unstaged or untracked files only when they belong to the same change.
- do not push; /publish handles publishing.
- do not use git restore or git checkout --.
- verify with git status after committing.
`.trim();

function block(title: string, body: string): string {
  return `## ${title}\n\n\`\`\`\n${body.trim() || "<empty>"}\n\`\`\``;
}

export default function (pi: ExtensionAPI) {
  pi.registerCommand("commit", {
    description: "commit with preloaded vcs context",
    handler: async (_args, ctx) => {
      const cwd = ctx.cwd;
      const isJj =
        (await pi.exec("jj", ["root"], { cwd, timeout: 5000 })).code === 0;
      const isGit =
        !isJj &&
        (
          await pi.exec("git", ["rev-parse", "--show-toplevel"], {
            cwd,
            timeout: 5000,
          })
        ).code === 0;
      if (!isJj && !isGit) {
        ctx.ui.notify("not a jj or git repo", "error");
        return;
      }

      const name = isJj ? "jj" : "git";
      const statusArgs = isJj ? ["status"] : ["status"];
      const logArgs = isJj
        ? ["log", "--limit", "5", "--no-graph"]
        : ["log", "--oneline", "-5"];

      const [status, log] = await Promise.all([
        pi.exec(name, statusArgs, { cwd, timeout: 5000 }),
        pi.exec(name, logArgs, { cwd, timeout: 5000 }),
      ]);

      if (status.code !== 0) {
        ctx.ui.notify(`${name} status failed: ${status.stderr}`, "error");
        return;
      }

      const prompt = [
        `commit the current ${name} repository.`,
        "",
        STYLE,
        "",
        isJj ? JJ_MECHANICS : GIT_MECHANICS,
      ].join("\n");

      const context = [
        block(`${name} ${statusArgs.join(" ")}`, status.stdout),
        block(
          `${name} ${logArgs.join(" ")}`,
          log.code === 0 ? log.stdout : log.stderr,
        ),
      ].join("\n\n");

      pi.sendUserMessage(`${prompt}\n\n${context}`, { deliverAs: "followUp" });
    },
  });
}
