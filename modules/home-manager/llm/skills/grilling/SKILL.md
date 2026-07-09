---
name: grilling
description: Grill the user relentlessly about a plan or design. Use when the user wants to stress-test a plan before building, or uses any 'grill' trigger phrases.
---

Interview me relentlessly about every aspect of this plan until we reach a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one-by-one.

**Ask each question through the harness's question tool** (the structured ask/question UI with selectable options) whenever one is available — never as prose the user has to answer by typing. Options are the concrete alternatives (a), (b), …; mark your recommended answer as the default. Reasoning, trade-offs, and evidence go in the message _before_ the tool call; the option labels stay short. Fall back to prose questions only when no such tool exists.

Ask the questions one at a time, waiting for the answer on each before continuing. Asking multiple questions at once is bewildering.

If a _fact_ can be found by exploring the codebase, look it up rather than asking me. The _decisions_, though, are mine — put each one to me and wait for my answer.

Do not enact the plan until I confirm we have reached a shared understanding.
