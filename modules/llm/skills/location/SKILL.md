---
name: location
description: Determine the user's current location from GeoClue data
---

The user's current location is available as a JSON file, updated every 10 minutes via GeoClue (WiFi/GPS positioning).

### Read current location

```bash
cat "$XDG_RUNTIME_DIR/spaces/location.json"
```

This returns a JSON object with `latitude`, `longitude`, `accuracy_meters`, `description`, and `updated` fields.

Use this whenever the user asks location-dependent questions like:

- "Where is the nearest train station?"
- "What's the weather like here?"
- "How far is it to ...?"

### Tips

- The file is updated every 10 minutes. Check the `updated` timestamp if freshness matters.
- Accuracy depends on available positioning sources (GPS, WiFi). The `accuracy_meters` field tells you how precise the fix is.
- Combine with the maps skill to reverse-geocode or find nearby places (train stations, bus stops, etc.).
- If the file does not exist, GeoClue may not have reported a position yet. Tell the user location is unavailable.

### Chaining with other skills

For travel questions like "find the next train to Berlin":

1. Read location from this file to get coordinates.
2. Use the datetime skill to know the current time.
3. Use the maps skill to find the nearest train station.
4. Use the db-cli skill (if available) to search for connections from that station.
