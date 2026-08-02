---
name: datetime
description: Get the current date and time to answer time-related questions
---

You can check the current date and time using the `date` command.

### Current date and time

```bash
date
```

### Specific formats

ISO 8601:

```bash
date --iso-8601=seconds
```

UTC:

```bash
date -u
```

### Tips

- Use this skill when the user asks about the current time, date, or day of the week.
- Use this to calculate durations, e.g. "how long until Friday?" or "what day is Christmas?".
- Combine with `date -d` for date arithmetic, e.g. `date -d "next Friday"` or `date -d "2025-12-25"`.
