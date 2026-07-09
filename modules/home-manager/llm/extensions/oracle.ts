/**
 * oracle — second opinion from another AI model
 *
 * Two entry points sharing one core:
 *
 *   second_opinion tool  - agent-callable, non-interactive; lets skills
 *                          (e.g. review-pong) drive cross-model critique
 *   /oracle command      - interactive: model picker, result dialog,
 *                          optional add-to-context
 *
 * /oracle <prompt>              - opens model picker, then queries
 * /oracle -m gpt-4o <prompt>    - direct to specific model
 * /oracle -f file.ts <prompt>   - include file(s) in context
 */

import { Type } from "typebox";
import {
  complete,
  type Api,
  type UserMessage,
  type Model,
} from "@earendil-works/pi-ai";
import type {
  ExtensionAPI,
  ExtensionContext,
  SessionEntry,
} from "@earendil-works/pi-coding-agent";
import {
  BorderedLoader,
  convertToLlm,
  serializeConversation,
} from "@earendil-works/pi-coding-agent";
import { Text, matchesKey, visibleWidth } from "@earendil-works/pi-tui";
import { readFile } from "node:fs/promises";
import * as path from "node:path";

interface AvailableModel {
  provider: string;
  modelId: string;
  name: string;
  model: Model<Api>;
  apiKey: string;
  headers?: Record<string, string>;
}

interface Theme {
  fg(color: string, text: string): string;
  bold(text: string): string;
}

const MAX_CONTEXT_MESSAGES = 40;
const MAX_CONTEXT_CHARS = 100_000;

const SYSTEM_PROMPT = `You are providing a second opinion on a coding conversation.
You may receive the recent conversation context between the user and their primary AI assistant.
Your job is to:
1. Understand what they've been discussing
2. Answer the specific question they're asking you
3. Point out if you disagree with any decisions made
4. Be concise but thorough

Focus on being helpful and providing a fresh perspective.`;

async function getAvailableModels(
  ctx: ExtensionContext,
): Promise<AvailableModel[]> {
  const models: AvailableModel[] = [];
  const available = ctx.modelRegistry.getAvailable();

  for (const model of available) {
    // skip current model — we want a different opinion
    if (ctx.model && model.id === ctx.model.id) continue;

    const auth = await ctx.modelRegistry.getApiKeyAndHeaders(model);
    if (!auth.ok) continue;

    models.push({
      provider: model.provider,
      modelId: model.id,
      name: model.name ?? model.id,
      model,
      apiKey: auth.apiKey ?? "",
      headers: auth.headers,
    });
  }

  return models;
}

function findModel(
  models: AvailableModel[],
  query: string,
): AvailableModel | undefined {
  return models.find(
    (m) =>
      m.modelId === query ||
      m.modelId.includes(query) ||
      m.name.toLowerCase().includes(query.toLowerCase()),
  );
}

/** Recent conversation, capped so a long session can't blow the second model's window. */
function buildConversationContext(ctx: ExtensionContext): string {
  const branch = ctx.sessionManager.getBranch();
  const messages = branch
    .filter(
      (entry): entry is SessionEntry & { type: "message" } =>
        entry.type === "message",
    )
    .map((entry) => entry.message);

  if (messages.length === 0) return "";

  const recent = messages.slice(-MAX_CONTEXT_MESSAGES);
  let context = serializeConversation(convertToLlm(recent));
  if (context.length > MAX_CONTEXT_CHARS) {
    context = "[...truncated...]\n" + context.slice(-MAX_CONTEXT_CHARS);
  }
  if (recent.length < messages.length) {
    context = `[...${messages.length - recent.length} earlier messages omitted...]\n${context}`;
  }
  return context;
}

async function buildFullPrompt(
  ctx: ExtensionContext,
  prompt: string,
  files: string[],
  includeContext: boolean,
): Promise<string> {
  let fileContext = "";
  for (const file of files) {
    try {
      const fullPath = path.resolve(ctx.cwd, file);
      const content = await readFile(fullPath, "utf-8");
      fileContext += `\n\n--- File: ${file} ---\n${content}`;
    } catch (err) {
      fileContext += `\n\n--- File: ${file} ---\n[Error reading file: ${err}]`;
    }
  }

  let fullPrompt = "";
  if (includeContext) {
    const conversationContext = buildConversationContext(ctx);
    if (conversationContext) {
      fullPrompt += `## Current Conversation Context\n\n${conversationContext}\n\n`;
    }
  }
  fullPrompt += `## Question for Second Opinion\n\n${prompt}`;
  if (fileContext) {
    fullPrompt += `\n\n## Additional Files${fileContext}`;
  }
  return fullPrompt;
}

/** One query. Throws on failure — callers surface the message. */
async function queryModel(
  model: AvailableModel,
  fullPrompt: string,
  signal?: AbortSignal,
): Promise<string | null> {
  const userMessage: UserMessage = {
    role: "user",
    content: [{ type: "text", text: fullPrompt }],
    timestamp: Date.now(),
  };

  const response = await complete(
    model.model,
    { systemPrompt: SYSTEM_PROMPT, messages: [userMessage] },
    { apiKey: model.apiKey, headers: model.headers, signal },
  );

  if (response.stopReason === "aborted") return null;

  return response.content
    .filter((c): c is { type: "text"; text: string } => c.type === "text")
    .map((c) => c.text)
    .join("\n");
}

export default function (pi: ExtensionAPI) {
  pi.registerTool({
    name: "second_opinion",
    label: "Second Opinion",
    description:
      "Ask a different AI model for a second opinion, critique, or adversarial review. " +
      "Use when the user wants another model's view, when a skill needs a cross-model " +
      "critic (e.g. review-pong), or to challenge a conclusion with a fresh prior. " +
      "Runs non-interactively and returns the other model's answer as text.",
    parameters: Type.Object({
      prompt: Type.String({
        description:
          "The full question or brief for the other model. Include everything it needs — it does not see this conversation unless include_context is true.",
      }),
      model: Type.Optional(
        Type.String({
          description:
            "Substring matching the desired model id or name. Omit to use the first available model that differs from the current one.",
        }),
      ),
      files: Type.Optional(
        Type.Array(Type.String(), {
          description: "Repo-relative file paths to include in the prompt.",
        }),
      ),
      include_context: Type.Optional(
        Type.Boolean({
          description:
            "Include recent conversation context (capped). Default false — prefer a self-contained prompt.",
        }),
      ),
    }),
    async execute(_toolCallId, params, signal, _onUpdate, ctx) {
      const {
        prompt,
        model: modelQuery,
        files = [],
        include_context: includeContext = false,
      } = params as {
        prompt: string;
        model?: string;
        files?: string[];
        include_context?: boolean;
      };

      const availableModels = await getAvailableModels(ctx);
      if (availableModels.length === 0) {
        return {
          content: [
            {
              type: "text",
              text: "error: no alternative models available (check API keys). A second opinion from the same model is pointless.",
            },
          ],
          details: {},
        };
      }

      const model = modelQuery
        ? findModel(availableModels, modelQuery)
        : availableModels[0];
      if (!model) {
        const names = availableModels.map((m) => m.modelId).join(", ");
        return {
          content: [
            {
              type: "text",
              text: `error: model "${modelQuery}" not available. Available: ${names}`,
            },
          ],
          details: {},
        };
      }

      const fullPrompt = await buildFullPrompt(
        ctx,
        prompt,
        files,
        includeContext,
      );

      try {
        const result = await queryModel(model, fullPrompt, signal);
        if (result === null) {
          return {
            content: [{ type: "text", text: "aborted" }],
            details: {},
          };
        }
        return {
          content: [{ type: "text", text: `[${model.name}]\n\n${result}` }],
          details: { model: model.modelId, modelName: model.name, files },
        };
      } catch (err) {
        return {
          content: [
            {
              type: "text",
              text: `error querying ${model.name}: ${err instanceof Error ? err.message : String(err)}`,
            },
          ],
          details: {},
        };
      }
    },
  });

  pi.registerCommand("oracle", {
    description: "Get a second opinion from another AI model",
    handler: async (args, ctx) => {
      await ctx.waitForIdle();

      if (!ctx.hasUI) {
        ctx.ui.notify("oracle requires interactive mode", "error");
        return;
      }

      const availableModels = await getAvailableModels(ctx);

      if (availableModels.length === 0) {
        ctx.ui.notify(
          "no alternative models available. check API keys.",
          "error",
        );
        return;
      }

      // parse args
      const trimmedArgs = args?.trim() || "";
      if (!trimmedArgs) {
        ctx.ui.notify(
          "usage: /oracle <prompt> or /oracle -f file.ts <prompt>",
          "error",
        );
        return;
      }

      let modelArg: string | undefined;
      const files: string[] = [];
      const promptParts: string[] = [];

      const tokens = trimmedArgs.split(/\s+/);
      let i = 0;
      while (i < tokens.length) {
        const token = tokens[i];
        if (token === "-m" || token === "--model") {
          i++;
          if (i < tokens.length) modelArg = tokens[i];
        } else if (token === "-f" || token === "--file") {
          i++;
          if (i < tokens.length) files.push(tokens[i]);
        } else {
          promptParts.push(...tokens.slice(i));
          break;
        }
        i++;
      }

      const prompt = promptParts.join(" ");
      if (!prompt) {
        ctx.ui.notify("no prompt provided", "error");
        return;
      }

      // if model specified directly, skip picker
      let selected: AvailableModel | undefined;
      if (modelArg) {
        selected = findModel(availableModels, modelArg);
        if (!selected) {
          ctx.ui.notify(`model "${modelArg}" not available`, "error");
          return;
        }
      } else {
        const choices = availableModels.map((m) => `${m.name} (${m.provider})`);
        const picked = await ctx.ui.select(
          "🔮 Oracle — pick a model:",
          choices,
        );
        if (picked === undefined) {
          ctx.ui.notify("cancelled", "info");
          return;
        }
        const selectedIdx = choices.indexOf(picked);
        if (selectedIdx === -1) return;
        selected = availableModels[selectedIdx];
      }

      await executeOracleCommand(pi, ctx, prompt, files, selected);
    },
  });

  // custom renderer for oracle responses
  pi.registerMessageRenderer("oracle-response", (message, options, theme) => {
    const { expanded } = options;
    const details = (message.details || {}) as {
      modelName?: string;
      files?: string[];
    };

    let text = theme.fg(
      "accent",
      `🔮 Oracle (${details.modelName || "unknown"}):\n\n`,
    );
    text += message.content;

    if (expanded && details.files?.length > 0) {
      text += "\n\n" + theme.fg("dim", `Files: ${details.files.join(", ")}`);
    }

    return new Text(text, 0, 0);
  });
}

async function executeOracleCommand(
  pi: ExtensionAPI,
  ctx: ExtensionContext,
  prompt: string,
  files: string[],
  model: AvailableModel,
): Promise<void> {
  const fullPrompt = await buildFullPrompt(ctx, prompt, files, true);

  // call the model; keep the failure reason so the user sees why
  let failure: string | undefined;
  const result = await ctx.ui.custom<string | null>((tui, theme, _kb, done) => {
    const loader = new BorderedLoader(tui, theme, `🔮 Asking ${model.name}...`);
    loader.onAbort = () => done(null);

    queryModel(model, fullPrompt, loader.signal)
      .then(done)
      .catch((err) => {
        failure = err instanceof Error ? err.message : String(err);
        done(null);
      });

    return loader;
  });

  if (result === null) {
    ctx.ui.notify(
      failure ? `oracle failed: ${failure}` : "cancelled",
      failure ? "error" : "warning",
    );
    return;
  }

  // show result and ask if user wants to add to context
  const addToContext = await ctx.ui.custom<boolean>((tui, theme, _kb, done) => {
    const component = new OracleResultComponent(
      result,
      model.name,
      prompt,
      tui,
      theme as Theme,
      (add) => done(add),
    );

    return {
      render: (w) => component.render(w),
      invalidate: () => component.invalidate(),
      handleInput: (data) => component.handleInput(data),
    };
  });

  if (addToContext) {
    pi.sendMessage({
      customType: "oracle-response",
      content: result,
      display: true,
      details: {
        model: model.modelId,
        modelName: model.name,
        files,
        prompt,
      },
    });
    ctx.ui.notify("oracle response added to context", "success");
  } else {
    ctx.ui.notify("oracle response discarded", "info");
  }
}

/**
 * oracle result display with add-to-context option
 */
class OracleResultComponent {
  private result: string;
  private modelName: string;
  private prompt: string;
  private selected: number = 0; // 0 = yes, 1 = no
  private scrollOffset: number = 0;
  private onDone: (addToContext: boolean) => void;
  private tui: { requestRender: () => void };
  private theme: Theme;
  private cachedLines: string[] = [];
  private cachedWidth = 0;

  constructor(
    result: string,
    modelName: string,
    prompt: string,
    tui: { requestRender: () => void },
    theme: Theme,
    onDone: (addToContext: boolean) => void,
  ) {
    this.result = result;
    this.modelName = modelName;
    this.prompt = prompt;
    this.tui = tui;
    this.theme = theme;
    this.onDone = onDone;
  }

  handleInput(data: string): void {
    if (matchesKey(data, "escape") || data === "n" || data === "N") {
      this.onDone(false);
      return;
    }

    if (matchesKey(data, "return") || matchesKey(data, "enter")) {
      this.onDone(this.selected === 0);
      return;
    }

    if (data === "y" || data === "Y") {
      this.onDone(true);
      return;
    }

    if (
      matchesKey(data, "left") ||
      matchesKey(data, "right") ||
      data === "h" ||
      data === "l" ||
      matchesKey(data, "tab")
    ) {
      this.selected = this.selected === 0 ? 1 : 0;
      this.cachedWidth = 0;
      this.tui.requestRender();
    }

    if (matchesKey(data, "up") || data === "k") {
      this.scrollOffset = Math.max(0, this.scrollOffset - 1);
      this.cachedWidth = 0;
      this.tui.requestRender();
    } else if (matchesKey(data, "down") || data === "j") {
      this.scrollOffset++;
      this.cachedWidth = 0;
      this.tui.requestRender();
    }
  }

  invalidate(): void {
    this.cachedWidth = 0;
  }

  render(width: number): string[] {
    if (this.cachedWidth === width) return this.cachedLines;

    const t = this.theme;
    const lines: string[] = [];
    const boxWidth = Math.min(80, width - 4);
    const contentWidth = boxWidth - 4;
    const maxResultLines = 15;

    const padLine = (line: string): string => {
      const len = visibleWidth(line);
      return line + " ".repeat(Math.max(0, width - len));
    };

    const boxLine = (content: string): string => {
      const len = visibleWidth(content);
      const padding = Math.max(0, boxWidth - 2 - len);
      return (
        t.fg("dim", "│ ") + content + " ".repeat(padding) + t.fg("dim", " │")
      );
    };

    const wrapText = (text: string, maxWidth: number): string[] => {
      const wrapped: string[] = [];
      for (const paragraph of text.split("\n")) {
        if (paragraph.length <= maxWidth) {
          wrapped.push(paragraph);
        } else {
          let remaining = paragraph;
          while (remaining.length > maxWidth) {
            let breakPoint = remaining.lastIndexOf(" ", maxWidth);
            if (breakPoint === -1) breakPoint = maxWidth;
            wrapped.push(remaining.slice(0, breakPoint));
            remaining = remaining.slice(breakPoint + 1);
          }
          if (remaining) wrapped.push(remaining);
        }
      }
      return wrapped;
    };

    lines.push("");
    lines.push(padLine(t.fg("dim", "╭" + "─".repeat(boxWidth) + "╮")));
    lines.push(
      padLine(
        boxLine(
          t.bold(t.fg("accent", `🔮 Oracle Response (${this.modelName})`)),
        ),
      ),
    );
    lines.push(padLine(t.fg("dim", "├" + "─".repeat(boxWidth) + "┤")));

    const promptPreview =
      this.prompt.length > contentWidth - 10
        ? this.prompt.slice(0, contentWidth - 13) + "..."
        : this.prompt;
    lines.push(padLine(boxLine(t.fg("dim", "Q: ") + promptPreview)));
    lines.push(padLine(t.fg("dim", "├" + "─".repeat(boxWidth) + "┤")));

    const resultLines = wrapText(this.result, contentWidth);
    const visibleLines = resultLines.slice(
      this.scrollOffset,
      this.scrollOffset + maxResultLines,
    );

    for (const line of visibleLines) {
      lines.push(padLine(boxLine(line)));
    }

    for (let i = visibleLines.length; i < Math.min(maxResultLines, 5); i++) {
      lines.push(padLine(boxLine("")));
    }

    if (resultLines.length > maxResultLines) {
      const scrollInfo = t.fg(
        "dim",
        ` ↑↓ scroll (${this.scrollOffset + 1}-${Math.min(this.scrollOffset + maxResultLines, resultLines.length)}/${resultLines.length})`,
      );
      lines.push(padLine(boxLine(scrollInfo)));
    }

    lines.push(padLine(t.fg("dim", "├" + "─".repeat(boxWidth) + "┤")));
    lines.push(
      padLine(boxLine(t.bold("Add to current conversation context?"))),
    );
    lines.push(padLine(boxLine("")));

    const yesBtn =
      this.selected === 0
        ? t.fg("success", t.bold(" [ YES ] "))
        : t.fg("dim", "   YES   ");
    const noBtn =
      this.selected === 1
        ? t.fg("warning", t.bold(" [ NO ] "))
        : t.fg("dim", "   NO   ");

    lines.push(padLine(boxLine(`       ${yesBtn}          ${noBtn}`)));
    lines.push(padLine(boxLine("")));

    lines.push(padLine(t.fg("dim", "├" + "─".repeat(boxWidth) + "┤")));
    lines.push(
      padLine(
        boxLine(
          t.fg("dim", "←→/Tab") +
            " switch  " +
            t.fg("dim", "Enter") +
            " confirm  " +
            t.fg("dim", "Y/N") +
            " quick",
        ),
      ),
    );
    lines.push(padLine(t.fg("dim", "╰" + "─".repeat(boxWidth) + "╯")));
    lines.push("");

    this.cachedLines = lines;
    this.cachedWidth = width;
    return lines;
  }
}
