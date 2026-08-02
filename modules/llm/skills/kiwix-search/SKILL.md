---
name: kiwix-search
description: Search the offline wiki archives (ArchWiki) served by Kiwix at kiwix.nx3.eu. Use for Arch/Linux system administration lookups, or when web search is unavailable or rate-limited.
---

Kiwix serves offline wiki snapshots at `https://kiwix.nx3.eu`. Loaded books: `archwiki`.

1. Search — results are HTML with `href="/content/BOOK/Title"` links; non-English translations appear as `Title_(Language)`, prefer the plain English title:

   ```
   curl -s 'https://kiwix.nx3.eu/search?books.name=archwiki&pattern=QUERY&pageLength=10'
   ```

2. Fetch the article (titles use underscores for spaces) and extract the section you need instead of dumping it whole:

   ```
   curl -s 'https://kiwix.nx3.eu/content/archwiki/Title'
   ```

More books later get their `books.name` key from `curl -s 'https://kiwix.nx3.eu/search'` result hrefs.
