---
name: maps
description: Geocode, find places, routes, distances and timezones via OpenStreetMap (no Google, no API key)
---

Location intelligence using free, open data: OpenStreetMap/Nominatim (geocoding), Overpass (places), OSRM (routing). The `osm-maps` command is on your PATH. No API key needed.

For the user's _current_ location, use the **location** skill first (reads their live GPS from Dawarich), then pass the coordinates here.

### Commands

```bash
# Geocode a place name -> coordinates
osm-maps search "Brandenburger Tor"

# Coordinates -> address
osm-maps reverse 52.5163 13.3777

# Nearby places by category (by coords, or --near "<place>")
osm-maps nearby 52.5163 13.3777 restaurant --limit 10
osm-maps nearby --near "Marienplatz München" --category cafe

# Travel distance and time (modes: driving, walking, cycling)
osm-maps distance "München" --to "Berlin"
osm-maps distance "München Hbf" --to "Marienplatz" --mode walking

# Turn-by-turn directions
osm-maps directions "München Hbf" --to "Allianz Arena" --mode driving

# Timezone for coordinates
osm-maps timezone 52.5163 13.3777

# Bounding box for a named area, then search within it
osm-maps area "Schwabing, München"
osm-maps bbox <S> <W> <N> <E> restaurant --limit 20
```

Categories include: restaurant, cafe, bar, hospital, pharmacy, hotel, supermarket, atm, gas_station, parking, museum, park, bank, train_station, bus_stop, and more.

### Chaining

- "weather here" -> location skill for coords -> weather-cli
- "nearest station / cafe" -> location skill for coords -> `osm-maps nearby <lat> <lon> <category>`
- "next train from nearest station" -> nearby train_station -> db-cli with that station name

### Notes

- Nominatim/Overpass are community services with rate limits; the script handles throttling and mirror fallback.
- OSM opening hours are community-maintained — verify "open now?" claims with web_search if it matters.
