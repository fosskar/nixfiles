---
name: grilling
description: Grill the user relentlessly about a plan, decision, or idea. Use when the user wants to stress-test their thinking, or uses any 'grill' trigger phrases.
---

Interview the user relentlessly until you reach a shared understanding. Map the subject as a **decision tree**. Each settled decision can expose more decisions.

Work through the tree in **rounds**. The **frontier** contains every question whose prerequisites are settled. Ask the complete frontier in one round.

Use the harness question tool when it is available. Put all questions for the round into one tool call. Give each question concrete options and mark the recommended option. Put reasoning, trade-offs, and evidence in each option description. Use short option labels.

After the user answers, recompute the frontier. Ask the next complete round. Keep a question for a later round when its answer depends on an open question.

Find facts through the environment and tools. Ask the user only for decisions.

The session is complete when the frontier is empty and no assumption remains. Do not act until the user confirms that you reached a shared understanding.
