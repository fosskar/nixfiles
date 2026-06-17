---
name: teach-me
description: >
  Teach the user a code area, concept, file, or unfamiliar system. Use when the
  user asks to learn something, says "teach me this", wants a walkthrough, or
  asks how an area works rather than asking for a direct change.
disable-model-invocation: true
argument-hint: "What should be taught?"
---

Teach the topic, not a full course.

First, anchor the lesson:

- what the user wants to understand
- what source material you will inspect or use
- what level the user seems to be at

Then teach in a tight loop:

1. give the smallest useful map of the area
2. explain the core idea in the user's terminology
3. show one concrete example from the actual source or context
4. ask one check question or give one small exercise
5. adapt based on the user's answer

Prefer real files, configs, docs, commands, or examples over generic explanation. If the topic is in a repo, inspect it before teaching. Do not create lesson files, workspaces, notes, or long curricula unless the user asks.
