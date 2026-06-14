---
name: grill-me
description: Interview the user relentlessly about a plan or design until reaching shared understanding, resolving each branch of the decision tree. Use when user wants to stress-test a plan, get grilled on their design, or mentions "grill me".
---

Interview me relentlessly about every aspect of this plan until we reach a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one-by-one. Make sure our wording refers to the same concepts. Prefer official terminology when it exists, and correct ambiguous or non-standard terms before continuing. Before asking terminology questions, inspect existing code/docs/commit history for names of the concepts under discussion. Treat paths, module names, option names, docs, and recent commit messages as terminology evidence. Challenge synonyms and ask the user to pick one canonical term. For each question, provide your recommended answer.

Ask the questions one at a time using the questionnaire extension.

If a question can be answered by exploring the codebase, explore the codebase instead.
