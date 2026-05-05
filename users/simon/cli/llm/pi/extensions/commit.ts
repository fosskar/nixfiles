import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

const STYLE = `
create commit(s) for the current work.

rules:
- default to one commit for the current task.
- one logical change per commit, but atomic means coherent and easy to review/revert, not maximal splitting.
- split only when changes are unrelated or would be easier to review/revert separately.
- use the preloaded status, stat, and diff as the primary context. run extra inspection only when it improves the commit split or message.
- commit msg: lowercase, concise, imperative.
- focus msg on why, using the diff for concrete context.
- no conventional commit prefixes.
- keep it KISS.
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
      const statArgs = isJj ? ["diff", "--stat"] : ["diff", "--stat", "HEAD"];
      const diffArgs = isJj ? ["diff", "--git"] : ["diff", "HEAD"];

      const [status, log, stat, diff] = await Promise.all([
        pi.exec(name, statusArgs, { cwd, timeout: 5000 }),
        pi.exec(name, logArgs, { cwd, timeout: 5000 }),
        pi.exec(name, statArgs, { cwd, timeout: 10000 }),
        pi.exec(name, diffArgs, { cwd, timeout: 15000 }),
      ]);

      if (status.code !== 0) {
        ctx.ui.notify(`${name} status failed: ${status.stderr}`, "error");
        return;
      }

      const DIFF_CAP = 200_000;
      const rawDiff = diff.code === 0 ? diff.stdout : diff.stderr;
      const diffBody =
        rawDiff.length > DIFF_CAP
          ? rawDiff.slice(0, DIFF_CAP) +
            `\n\n[truncated: diff was ${rawDiff.length} bytes, showing first ${DIFF_CAP}]`
          : rawDiff;

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
        block(
          `${name} ${statArgs.join(" ")}`,
          stat.code === 0 ? stat.stdout : stat.stderr,
        ),
        block(`${name} ${diffArgs.join(" ")}`, diffBody),
      ].join("\n\n");

      pi.sendUserMessage(`${prompt}\n\n${context}`, { deliverAs: "followUp" });
    },
  });
}
