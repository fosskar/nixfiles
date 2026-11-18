import { execFile } from "node:child_process";

// pi and omp have no command hooks, so this extension runs the recall hook that claude-code and codex call
export default function (pi: any) {
  pi.on("before_agent_start", async (event: any, ctx: any) => {
    if (!event.prompt) return;
    const input = JSON.stringify({
      prompt: event.prompt,
      cwd: ctx.sessionManager.getCwd(),
      session_id: ctx.sessionManager.getSessionId(),
    });
    const content = await new Promise<string>((resolve, reject) => {
      const child = execFile(
        "@recallHook@",
        { timeout: 10_000 },
        (error, stdout) => (error ? reject(error) : resolve(stdout)),
      );
      child.stdin!.end(input);
    });
    if (!content.trim()) return;
    return {
      message: { customType: "sediment-recall", content, display: false },
    };
  });
}
