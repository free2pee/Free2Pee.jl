using Oxygen
using JSON3, Downloads, CSV, DataFrames, JSONTables, PrettyTables
using HTTP, URIs
using Distances

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


# response = HTTP.post(url, nothing, query)
# j = JSON3.read(response.body)
# es = j.elements
# @info length(es)
# fn = _data("mapcomplete_toilets.json")
# jt = JSON3.read(read(fn))
# ts = jt.tags



# println.("node(around:1000, $lat, $lon)" .* node_string.(ts))
