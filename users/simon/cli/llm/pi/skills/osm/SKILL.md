---
name: osm
description: Search places, find nearby POIs, get directions context, and locate public transport stops using OpenStreetMap. Replaces Google Maps for place search, nearby lookup, and stop finding. Use when user asks about nearby restaurants, shops, pharmacies, transit stops, or any real-world location query.
---

# osm

query OpenStreetMap via nominatim (geocoding) + overpass API (spatial queries). no API key needed.

## geocoding — resolve address/place to coordinates

```
fetch https://nominatim.openstreetmap.org/search?q=<ADDRESS>&format=json&limit=3
```

header: `User-Agent: osm-skill/1.0` (required by nominatim).

returns `lat`, `lon`, `display_name`. use coordinates for overpass queries.

## reverse geocoding — coordinates to address

```
fetch https://nominatim.openstreetmap.org/reverse?lat=<LAT>&lon=<LON>&format=json
```

header: `User-Agent: osm-skill/1.0`

## overpass — spatial queries

endpoint: `https://overpass-api.de/api/interpreter`

send queries via GET with `data=` parameter (URL-encoded) or POST with body.

### find nearby POIs

```
[out:json];
node["amenity"="<TYPE>"](around:<RADIUS>,<LAT>,<LON>);
out body 10;
```

common amenity types: `restaurant`, `cafe`, `pharmacy`, `hospital`, `atm`, `bank`, `supermarket`, `parking`, `fuel`, `school`, `university`, `library`, `cinema`, `theatre`, `pub`, `bar`, `fast_food`, `dentist`, `doctors`

### find nearby shops

```
[out:json];
node["shop"="<TYPE>"](around:<RADIUS>,<LAT>,<LON>);
out body 10;
```

common shop types: `supermarket`, `bakery`, `butcher`, `convenience`, `clothes`, `hairdresser`, `hardware`, `electronics`, `florist`, `optician`

### find nearby public transport stops

```
[out:json];
node["public_transport"="stop_position"](around:<RADIUS>,<LAT>,<LON>);
out body 10;
```

default radius: 500m. increase to 1000 if too few results.

### find by name

```
[out:json];
node["name"~"<PATTERN>",i](around:<RADIUS>,<LAT>,<LON>);
out body 10;
```

### combine multiple types

```
[out:json];
(
  node["amenity"="restaurant"](around:500,53.55,9.99);
  node["amenity"="cafe"](around:500,53.55,9.99);
);
out body 10;
```

## presenting results

- sort by distance from query point
- show: name, type, approximate distance, address (if available in tags)
- for transport stops: include transport type (bus/tram/subway/train) from tags

## chaining with db-cli

when user wants a route from an address (not a station name):

1. geocode the address
2. overpass: find nearest `public_transport=stop_position` within 500m
3. use stop name as input to `db-cli "<stop>" "<destination>"`

## example queries

**"find italian restaurants near jungfernstieg hamburg"**

1. geocode "Jungfernstieg Hamburg" → lat, lon
2. overpass: `node["amenity"="restaurant"]["cuisine"="italian"](around:500,LAT,LON);`

**"how do i get from moortwiete hamburg to altona?"**

1. geocode "Moortwiete Hamburg" → 53.608, 9.978
2. overpass: find nearest stops → "Groß Borstel (Mitte)"
3. `db-cli "Groß Borstel" "Altona"`

**"pharmacies near me"** (if user location known)

1. overpass: `node["amenity"="pharmacy"](around:1000,LAT,LON);`

## notes

- nominatim: max 1 request/second, requires User-Agent header
- overpass: free, no auth, but avoid excessive queries
- works worldwide
- OSM tag reference: https://wiki.openstreetmap.org/wiki/Map_features
