---
name: scope-check
description: >
  Step back when the answer is narrower or more implementation-specific than the
  user's question. Use when the conversation is at a higher layer than the
  assistant's response, or when details obscure the actual decision, goal, or
  scope.
disable-model-invocation: true
---

Pause. The answer is operating at the wrong layer.

Zoom out one level and restate:

- what the user is asking for
- what scope is being answered now
- what scope should be answered instead
- the corrected answer at that scope

Prefer the user's terminology. Do not dive into implementation details unless they are needed to answer the higher-level question.
