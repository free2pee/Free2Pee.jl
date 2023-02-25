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
fn = to_df("mapcomplete_toilets.json")
jt = JSON3.read(read(fn))
ts = jt.tags

# println.("node(around:1000, $lat, $lon)" .* node_string.(ts))

# try this not haversine
# curl 'http://router.project-osrm.org/route/v1/driving/13.388860,52.517037;13.397634,52.529407;13.428555,52.523219?overview=false'


# /{service}/{version}/{profile}/{coordinates}[.{format}]?option=value&option=value

"""
# https://project-osrm.org/docs/v5.24.0/api/ # this is the osrm api docs

https://www.openstreetmap.org/directions?engine=fossgis_osrm_foot&route=42.36370%2C-71.10560%3B42.35810%2C-71.10610#map=16/42.3610/-71.1049
this service makes calls to https://routing.openstreetmap.de/routed-foot/route/v1/driving/-71.1056,42.3637;-71.1061,42.3581;-71.1056,42.3637;-71.091430,42.359760;-71.1056,42.3637;-71.104770,42.369880
which reports correct walking times 

however, the latest osrm docs have a nice matrix/table interface that seems to not make a difference between walking and driving

"""
route_url = "http://router.project-osrm.org/table/v1/driving/-71.105650,42.363740;-71.106120,42.358030"
response = HTTP.post(route_url)
j = JSON3.read(response.body)
j.routes[1].duration #this is the time (in seconds) it takes to go from the first lat/long pair to the second lat/long pair



