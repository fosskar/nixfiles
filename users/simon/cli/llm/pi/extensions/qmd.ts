import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import {
  DEFAULT_MAX_BYTES,
  DEFAULT_MAX_LINES,
  truncateHead,
} from "@mariozechner/pi-coding-agent";
import { Type } from "@sinclair/typebox";

export default function (pi: ExtensionAPI) {
  async function runQmd(args: string[], signal?: AbortSignal) {
    const res = await pi.exec("qmd", args, { signal, timeout: 120 });
    const output =
      [res.stdout, res.stderr].filter(Boolean).join("\n").trim() ||
      "(no output)";
    const trunc = truncateHead(output, {
      maxBytes: DEFAULT_MAX_BYTES,
      maxLines: DEFAULT_MAX_LINES,
    });

    const suffix = trunc.truncated
      ? `\n\n[truncated: ${trunc.outputLines}/${trunc.totalLines} lines, ${trunc.outputBytes}/${trunc.totalBytes} bytes]`
      : "";

    return {
      content: [{ type: "text" as const, text: `${trunc.content}${suffix}` }],
      details: {
        args,
        code: res.code,
        truncated: trunc.truncated,
      },
      isError: res.code !== 0,
    };
  }

  pi.registerTool({
    name: "qmd_query",
    label: "qmd query",
    description: "search qmd index with search|vsearch|query and json output",
    parameters: Type.Object({
      query: Type.String(),
      mode: Type.Optional(Type.String({ default: "query" })),
      collection: Type.Optional(Type.String()),
      n: Type.Optional(Type.Number({ default: 8 })),
      minScore: Type.Optional(Type.Number({ default: 0.25 })),
    }),
    async execute(_toolCallId, params, signal) {
      const mode = ["search", "vsearch", "query"].includes(params.mode ?? "")
        ? (params.mode as string)
        : "query";
      const args = [
        mode,
        params.query,
        "--json",
        "-n",
        String(params.n ?? 8),
        "--min-score",
        String(params.minScore ?? 0.25),
      ];
      if (params.collection) args.push("-c", params.collection);
      return runQmd(args, signal);
    },
  });

  pi.registerTool({
    name: "qmd_get",
    label: "qmd get",
    description: "get qmd doc by path or #docid",
    parameters: Type.Object({
      ref: Type.String({ description: "path or #docid" }),
      full: Type.Optional(Type.Boolean({ default: false })),
    }),
    async execute(_toolCallId, params, signal) {
      const ref = params.ref.startsWith("@") ? params.ref.slice(1) : params.ref;
      const args = ["get", ref];
      if (params.full) args.push("--full");
      return runQmd(args, signal);
    },
  });

  pi.registerTool({
    name: "qmd_update",
    label: "qmd update",
    description: "run qmd update, optional embed",
    parameters: Type.Object({
      embed: Type.Optional(Type.Boolean({ default: false })),
    }),
    async execute(_toolCallId, params, signal) {
      const update = await runQmd(["update"], signal);
      if (!params.embed) return update;

      const embed = await runQmd(["embed"], signal);
      return {
        content: [
          {
            type: "text" as const,
            text: `${update.content?.[0]?.text ?? ""}\n\n${embed.content?.[0]?.text ?? ""}`.trim(),
          },
        ],
        details: {
          update: update.details,
          embed: embed.details,
        },
        isError: Boolean(update.isError || embed.isError),
      };
    },
  });
}
