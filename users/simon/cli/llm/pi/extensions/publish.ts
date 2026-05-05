import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

const remotes = ["origin", "rad"];
const widget = "publish";

class PublishError extends Error {}

function names(output: string): Set<string> {
  return new Set(
    output
      .split("\n")
      .map((l) => l.trim().split(/\s+/, 1)[0])
      .filter(Boolean),
  );
}

export default function (pi: ExtensionAPI) {
  pi.registerCommand("publish", {
    description: "publish current branch/bookmark",
    handler: async (args, ctx) => {
      const ref = args.trim() || undefined;
      const log: string[] = [];
      const show = () =>
        ctx.ui.setWidget(widget, ["publish", ...log.slice(-12)]);

      const run = async (cmd: string, argv: string[]) => {
        const line = [cmd, ...argv].join(" ");
        log.push(`… ${line}`);
        show();
        const result = await pi.exec(cmd, argv, {
          cwd: ctx.cwd,
          timeout: 120000,
        });
        log[log.length - 1] = result.code === 0 ? `✓ ${line}` : `✗ ${line}`;
        if (result.code !== 0 && result.stderr.trim()) {
          log.push(
            ...result.stderr
              .trim()
              .split("\n")
              .slice(-3)
              .map((l) => `  ${l}`),
          );
        }
        show();
        return result;
      };
      const must = async (cmd: string, argv: string[]) => {
        const result = await run(cmd, argv);
        if (result.code !== 0) {
          const tail = (result.stderr.trim() || result.stdout.trim())
            .split("\n")
            .slice(-3)
            .join("\n");
          throw new PublishError(
            `${[cmd, ...argv].join(" ")} failed (${result.code})\n${tail}`,
          );
        }
        return result;
      };

      show();

      try {
        const isJj =
          (await pi.exec("jj", ["root"], { cwd: ctx.cwd, timeout: 5000 }))
            .code === 0;
        const isGit =
          !isJj &&
          (
            await pi.exec("git", ["rev-parse", "--show-toplevel"], {
              cwd: ctx.cwd,
              timeout: 5000,
            })
          ).code === 0;
        if (!isJj && !isGit) throw new PublishError("not a jj or git repo");
        log.push(`backend: ${isJj ? "jj" : "git"}`);
        show();

        if (isJj) {
          const bookmark = ref ?? "main";
          const status = await must("jj", ["status"]);
          if (!status.stdout.includes("The working copy has no changes."))
            throw new PublishError("working copy has uncommitted changes");

          const parent = await must("jj", [
            "log",
            "-r",
            "@- & ~empty()",
            "--no-graph",
            "--limit",
            "1",
          ]);
          if (!parent.stdout.trim())
            throw new PublishError(
              "@- is empty; not moving a bookmark to an empty change",
            );

          const rs = names(
            (await must("jj", ["git", "remote", "list"])).stdout,
          );
          if (!rs.has("origin"))
            throw new PublishError("origin remote is not configured");

          await must("jj", ["git", "fetch", "--remote", "origin"]);

          const remoteBookmark = await run("jj", [
            "log",
            "-r",
            `${bookmark}@origin`,
            "--no-graph",
            "--limit",
            "1",
          ]);
          if (remoteBookmark.code === 0 && remoteBookmark.stdout.trim()) {
            await must("jj", ["rebase", "-d", `${bookmark}@origin`]);
          }

          await must("jj", ["bookmark", "set", bookmark, "-r", "@-"]);
          if (rs.has("rad")) await must("rad", ["node", "start"]);
          for (const remote of remotes.filter((r) => rs.has(r))) {
            await must("jj", [
              "git",
              "push",
              "--remote",
              remote,
              "--bookmark",
              bookmark,
            ]);
          }
          if (rs.has("rad")) await must("rad", ["sync"]);
          await must("jj", ["status"]);
        } else {
          const status = await must("git", ["status", "--porcelain"]);
          if (status.stdout.trim())
            throw new PublishError("working tree has uncommitted changes");

          const rs = names((await must("git", ["remote"])).stdout);
          if (!rs.has("origin"))
            throw new PublishError("origin remote is not configured");

          if (ref) {
            for (const remote of remotes.filter((r) => rs.has(r))) {
              await must("git", ["push", remote, ref]);
            }
          } else {
            await must("git", ["push"]);
          }
          await must("git", ["status", "--short"]);
        }

        ctx.ui.setWidget(widget, undefined);
        ctx.ui.notify(
          `published ${isJj ? "jj" : "git"}${ref ? ` ${ref}` : ""}`,
          "success",
        );
      } catch (err) {
        const message = err instanceof Error ? err.message : String(err);
        log.push(`failed: ${message.split("\n", 1)[0]}`);
        show();
        ctx.ui.notify(message, "error");
      }
    },
  });
}
