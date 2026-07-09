import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

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
    description:
      "publish current branch/bookmark (rad auto-synced when configured; pass 'no-rad' to skip)",
    handler: async (args, ctx) => {
      await ctx.waitForIdle();

      const tokens = args.trim().split(/\s+/).filter(Boolean);
      const noRad = tokens.includes("no-rad");
      const ref = tokens.find((t) => t !== "rad" && t !== "no-rad");
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
      // rad sync can exit 0 while reporting per-seed errors; match
      // line-anchored errors only so commit messages can't false-positive
      const mustRadSync = async (argv: string[]) => {
        const result = await must("rad", ["sync", ...argv]);
        const output = [result.stdout, result.stderr].join("\n");
        if (/^\s*✗?\s*Error:/m.test(output)) {
          const tail = output.trim().split("\n").slice(-3).join("\n");
          throw new PublishError(`rad sync ${argv.join(" ")} failed\n${tail}`);
        }
        return result;
      };
      const startRadNode = async () => {
        const status = await pi.exec("rad", ["node", "status"], {
          cwd: ctx.cwd,
          timeout: 10000,
        });
        if (status.code !== 0) await must("rad", ["node", "start"]);
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
          const wantRad = !noRad && rs.has("rad");
          const remotes = wantRad ? ["origin", "rad"] : ["origin"];

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
            // a hidden remote tip means local history rewrote it; rebasing
            // onto it would resurrect the old commit and hollow out the
            // rewrite into an empty change
            const visible = await run("jj", [
              "log",
              "-r",
              `${bookmark}@origin & all()`,
              "--no-graph",
              "--limit",
              "1",
            ]);
            if (visible.code !== 0 || !visible.stdout.trim())
              throw new PublishError(
                `${bookmark}@origin points at a commit rewritten locally; force-push manually instead of publishing`,
              );
            await must("jj", ["rebase", "-d", `${bookmark}@origin`]);
          }

          await must("jj", ["bookmark", "set", bookmark, "-r", "@-"]);
          if (wantRad) {
            await startRadNode();
            await mustRadSync(["--fetch"]);
          }
          for (const remote of remotes) {
            await must("jj", [
              "git",
              "push",
              "--remote",
              remote,
              "--bookmark",
              bookmark,
            ]);
          }
          if (wantRad) await mustRadSync(["--announce"]);
          await must("jj", ["status"]);
        } else {
          const status = await must("git", ["status", "--porcelain"]);
          if (status.stdout.trim())
            throw new PublishError("working tree has uncommitted changes");

          const rs = names((await must("git", ["remote"])).stdout);
          if (!rs.has("origin"))
            throw new PublishError("origin remote is not configured");
          const wantRad = !noRad && rs.has("rad");
          const remotes = wantRad ? ["origin", "rad"] : ["origin"];

          for (const remote of remotes) {
            await must("git", ["push", remote, ref ?? "HEAD"]);
          }
          await must("git", ["status", "--short"]);
        }

        ctx.ui.setWidget(widget, undefined);
        ctx.ui.notify(
          `published ${isJj ? "jj" : "git"}${ref ? ` ${ref}` : ""}`,
          "info",
        );
      } catch (err) {
        const message = err instanceof Error ? err.message : String(err);
        log.push(`failed: ${message.split("\n", 1)[0]}`);
        show();
        // failure lands in the conversation so the agent can help fix it;
        // success stays out of it
        pi.sendMessage({
          customType: "publish",
          display: true,
          content: ["publish failed", "", ...log].join("\n"),
        });
        ctx.ui.notify(message, "error");
      }
    },
  });
}
