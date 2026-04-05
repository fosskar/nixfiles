---
name: osm
description: search places, find nearby POIs, and locate public transport stops using OpenStreetMap. use when user asks about nearby restaurants, shops, pharmacies, transit stops, or any real-world location query.
---

# osm

query OpenStreetMap via nominatim (geocoding) + overpass API (spatial queries). no API key needed.

## rules

- **read-only.** never edit or upload anything to OSM.

## geocoding — resolve address/place to coordinates

```
curl -s -H "User-Agent: opencrow/1.0" "https://nominatim.openstreetmap.org/search?q=<ADDRESS>&format=json&limit=3"
```

returns `lat`, `lon`, `display_name`. use coordinates for overpass queries.

## reverse geocoding — coordinates to address

```
curl -s -H "User-Agent: opencrow/1.0" "https://nominatim.openstreetmap.org/reverse?lat=<LAT>&lon=<LON>&format=json"
```

## overpass — spatial queries

endpoint: `https://overpass-api.de/api/interpreter`

### find nearby POIs

```
[out:json];
node["amenity"="<TYPE>"](around:<RADIUS>,<LAT>,<LON>);
out body 10;
```

common amenity values: `restaurant`, `cafe`, `pharmacy`, `hospital`, `atm`, `supermarket`, `parking`, `fuel`, `pub`, `bar`, `fast_food`, `dentist`, `doctors`

### find nearby shops

```
[out:json];
node["shop"="<TYPE>"](around:<RADIUS>,<LAT>,<LON>);
out body 10;
```

common shop values: `supermarket`, `bakery`, `butcher`, `convenience`, `clothes`, `hairdresser`, `hardware`, `electronics`

### find nearby public transport stops

```
[out:json];
node["public_transport"="stop_position"](around:<RADIUS>,<LAT>,<LON>);
out body 10;
```

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
  node["amenity"="restaurant"](around:500,<LAT>,<LON>);
  node["amenity"="cafe"](around:500,<LAT>,<LON>);
);
out body 10;
```

default radius: 500m. increase to 1000 if too few results.

## presenting results

- sort by distance from query point
- show: name, type, approximate distance, address (if in tags)
- for transport stops: include transport type from tags

## notes

- nominatim: max 1 req/s, User-Agent header required
- overpass: free, no auth
- works worldwide
