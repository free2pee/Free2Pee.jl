using Oxygen
using JSON3, Downloads, CSV, DataFrames, JSONTables, PrettyTables
using HTTP, URIs
using Distances

using Free2Pee

# lat = 42.3640906
# lon = -71.1018806
const LAT = 42.35810736568732
const LON = -71.10592447014132
url = "https://overpass-api.de/api/interpreter"
lat = LAT
lon = LON
df = to_df(lat, lon)
@info df 
# we actually want to use the query that this taginfo project represents
# https://raw.githubusercontent.com/pietervdvn/MapComplete/develop/Docs/TagInfo/mapcomplete_toilets.json
query = """
[out:json];
(
node(around:1000, $lat, $lon)["amenity"="toilets"];
node(around:1000, $lat, $lon)["toilets"="yes"];
);
out;
"""
query = """
[out:json];
node(around:1000, 42.35810736568732, -71.10592447014132);
out;
"""


response = HTTP.post(url, nothing, query)
j = JSON3.read(response.body)
es = j.elements
@info length(es)
fn = _data("mapcomplete_toilets.json")
jt = JSON3.read(read(fn))
ts = jt.tags

# println.("node(around:1000, $lat, $lon)" .* node_string.(ts))

# try this not haversine
# curl 'http://router.project-osrm.org/route/v1/driving/13.388860,52.517037;13.397634,52.529407;13.428555,52.523219?overview=false'

route_url = "http://router.project-osrm.org/table/v1/foot/-71.105650,42.363740;-71.106120,42.358030"
response = HTTP.post(route_url)
j = JSON3.read(response.body)
j.durations[1][2] #this is the time (in seconds) it takes to go from the first lat/long pair to the second lat/long pair