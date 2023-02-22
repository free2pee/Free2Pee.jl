module Free2Pee
using JSON3, Downloads
using Oxygen, JSON3, Downloads, CSV, DataFrames, JSONTables, PrettyTables, HTTP, URIs, Distances

const LAT = 42.35810736568732
const LON = -71.10592447014132
lat = LAT
lon = LON
const OVERPASS_URL = "https://overpass-api.de/api/interpreter"
const MAPS_URI = URI("https://www.google.com/maps/dir/")

get_site(url) = take!(Downloads.download(url, IOBuffer()))
get_json(url) = JSON3.read(get_site(url))

DATADIR = joinpath(@__DIR__, "../data/")
# DATADIR2 = joinpath(@__DIR__, "../data/cambridge_redline_places_json/")
data(x) = joinpath(DATADIR, x)

"actually place is result to search"
place_to_latlong(placej) = (placej.geometry.location.lat, placej.geometry.location.lng)
get_geo(x) = x.geometry
get_loc(x) = get_geo(x).location

function lat_long_pair(n)
    return (n["lat"], n["lon"])
end

function gen_query(lat, lon; radius=1000)
    """
    [out:json];
    (
        node(around:$radius, $lat, $lon)["amenity"="toilets"];
        node(around:$radius, $lat, $lon)["toilets:position"="seated"];
        node(around:$radius, $lat, $lon)["toilets:position"="urinal"];
        node(around:$radius, $lat, $lon)["toilets:position"="squat"];
        node(around:$radius, $lat, $lon)["toilets:position"="seated;urinal"];
        node(around:$radius, $lat, $lon)["changing_table"="yes"];
        node(around:$radius, $lat, $lon)["changing_table"="no"];
        node(around:$radius, $lat, $lon)["changing_table:location"];
        node(around:$radius, $lat, $lon)["changing_table:location"="female_toilet"];
        node(around:$radius, $lat, $lon)["changing_table:location"="male_toilet"];
        node(around:$radius, $lat, $lon)["changing_table:location"="wheelchair_toilet"];
        node(around:$radius, $lat, $lon)["changing_table:location"="dedicated_room"];
        node(around:$radius, $lat, $lon)["toilets:handwashing"="yes"];
        node(around:$radius, $lat, $lon)["toilets:handwashing"="no"];
        node(around:$radius, $lat, $lon)["toilets:paper_supplied"="yes"];
        node(around:$radius, $lat, $lon)["toilets:paper_supplied"="no"];
        node(around:$radius, $lat, $lon)["toilets"="yes"];
        node(around:$radius, $lat, $lon)["toilets:access"];
        node(around:$radius, $lat, $lon)["toilets:fee"="yes"];
        node(around:$radius, $lat, $lon)["toilets:fee"="no"];
        node(around:$radius, $lat, $lon)["toilets:charge"];
        node(around:$radius, $lat, $lon)["toilets:wheelchair"="yes"];
        node(around:$radius, $lat, $lon)["toilets:wheelchair"="no"];
        node(around:$radius, $lat, $lon)["toilets:wheelchair"="designated"];
        node(around:$radius, $lat, $lon)["toilets:door:width"];
        node(around:$radius, $lat, $lon)["toilets:position"="seated"];
        node(around:$radius, $lat, $lon)["toilets:position"="urinal"];
        node(around:$radius, $lat, $lon)["toilets:position"="squat"];
        node(around:$radius, $lat, $lon)["toilets:position"="seated;urinal"];
        node(around:$radius, $lat, $lon)["changing_table"="yes"];
        node(around:$radius, $lat, $lon)["changing_table"="no"];
        node(around:$radius, $lat, $lon)["changing_table:location"];
        node(around:$radius, $lat, $lon)["changing_table:location"="female_toilet"];
        node(around:$radius, $lat, $lon)["changing_table:location"="male_toilet"];
        node(around:$radius, $lat, $lon)["changing_table:location"="wheelchair_toilet"];
        node(around:$radius, $lat, $lon)["changing_table:location"="dedicated_room"];
        node(around:$radius, $lat, $lon)["toilets:handwashing"="yes"];
        node(around:$radius, $lat, $lon)["toilets:handwashing"="no"];
        node(around:$radius, $lat, $lon)["toilets:paper_supplied"="yes"];
        node(around:$radius, $lat, $lon)["toilets:paper_supplied"="no"];
        node(around:$radius, $lat, $lon)["toilets:description"];
    );
    out;
    """
end


function walking_time_distance(ps, lat_lon)
    lat = lat_lon[1]
    lon = lat_lon[2]
    route_url = "http://router.project-osrm.org/table/v1/foot/$lon,$lat"
    for p in ps
        lat_dest = p[1]
        lon_dest = p[2]
        route_url = route_url*";$lon_dest,$lat_dest"
    end
    response = HTTP.post(route_url)
    j = JSON3.read(response.body)
    return j.durations[1][2:end]
end

function to_df(lat, lon; radius=1000)
    query = gen_query(lat, lon; radius)
    response = HTTP.post(OVERPASS_URL, nothing, query)
    j = JSON3.read(response.body)
    es = j.elements
    isempty(es) && error("no results")

    ps = lat_long_pair.(es)
    distances = haversine.(ps, ((lat, lon),))
    time_distances = walking_time_distance(ps, (lat,lon))
    # sorted_ns = es[sortperm(distances)]
    df = DataFrame(es)
    df.distance = sort(distances)
    df.time_distance = time_distances
    urls = map(x -> generate_google_api_url(lat, lon, x...), ps)
    df.maps_url = urls
    df
end

function node_string(tag)
    if haskey(tag, :value)
        """[\"$(tag.key)\"=\"$(tag.value)\"];"""
    else
        """[\"$(tag.key)\"];"""
    end
end

function generate_google_api_url(origin_lat, origin_long, dest_lat, dest_long)
    URI(MAPS_URI; query=Dict("api" => 1, "origin" => "$origin_lat,$origin_long", "destination" => "$dest_lat,$dest_long", "dir_action" => "navigate", "travelmode" => "walking"))
end

export get_site, get_json, to_df

end # module Free2Pee
