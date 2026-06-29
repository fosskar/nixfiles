---
name: location
description: Get the user's exact current location from their phone via Dawarich
---

The user's live location comes from Dawarich — their phone continuously streams GPS to it. Query the most recent recorded point to get where the user is right now.

### Current location

```bash
curl -s "http://127.0.0.1:17190/api/v1/points?api_key=$DAWARICH_API_KEY&order=desc&per_page=1" \
  | jq '.[0] | {latitude, longitude, accuracy, timestamp}'
```

If the response is wrapped in an object, the points are under `.data` instead — use `.data[0]`.

Each point has:

- `latitude`, `longitude` — coordinates
- `accuracy` — horizontal accuracy in meters
- `timestamp` — unix time of the fix

### Freshness

Check how old the fix is before trusting it:

```bash
date -d @<timestamp>
```

If the latest point is hours old, say so — the user may have moved since.

### Use it for

Location-dependent questions: "what's the weather here", "nearest train station", "how far to X". Chain with the weather, gmaps, and db-cli skills. If the request fails or returns no points, tell the user their location is unavailable.
