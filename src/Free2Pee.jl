module Free2Pee
using JSON3, Downloads
using Oxygen, JSON3, Downloads, CSV, DataFrames, JSONTables, PrettyTables, HTTP, URIs, Dates

const LAT = 42.35810736568732
const LON = -71.10592447014132
lat = LAT
lon = LON
const OVERPASS_URL = "https://overpass-api.de/api/interpreter"
const MAPS_URI = URI("https://www.google.com/maps/dir/")

# CODE_DF = DataFrame(
#     id = Int[],
#     code = String[],
#     timestamp = DateTime[],
#     ply_count = Int[]
# )
DATABASE_PATH = joinpath(@__DIR__, "../data/database.csv")
# CSV.write(DATABASE_PATH, CODE_DF)
CODE_DF = CSV.read(DATABASE_PATH, DataFrame)

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

function driving_time_distance(ps, lat_lon)
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


function walking_time_distance(ps, lat_lon)
    lat = lat_lon[1]
    lon = lat_lon[2]
    route_url  = "https://routing.openstreetmap.de/routed-foot/route/v1/driving/"
    # make_coords(my_coords, ps)
    # join("mylat,mylon" * join(ps[1], ",")), ";"
    for p in ps
        lat_dest = p[1]
        lon_dest = p[2]
        route_url = route_url*"$lon,$lat;"
        route_url = route_url*"$lon_dest,$lat_dest;"
    end
    response = HTTP.post(route_url[1:end-1])
    j = JSON3.read(response.body)
    return [j.routes[1].legs[i].duration for i in 1:2:length(j.routes[1].legs)]
end

function to_df(lat, lon; radius=1000)
    query = gen_query(lat, lon; radius)
    response = HTTP.post(OVERPASS_URL, nothing, query)
    j = JSON3.read(response.body)
    es = j.elements
    isempty(es) && error("no results")

    ps = lat_long_pair.(es)
    # distances = haversine.(ps, ((lat, lon),))
    time_distances = walking_time_distance(ps, (lat,lon))
    # sorted_ns = es[sortperm(distances)]
    df = DataFrame(es)
    # df.distance = sort(distances)
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

function make_form_cell(node_id)
    HtmlCell{String}("""<form action="/submit"><label for="code">Code:</label><input type="text" id="code" name="code" value=""><label for="node_id">DONT CHANGE</label><input type="text" id="node_id" name="node_id" value="$node_id"><input type="submit" value="Submit"></form>""")
end

function make_atag(tag, url)
    if haskey(tag, :name)
        name = tag.name
        HtmlCell{String}("<a href=\"$url\">$name</a>")
    else
        HtmlCell{String}("<a href=\"$url\">BingBong</a>")
    end
end

function find_code(node_id)
    codes = sort(CODE_DF[CODE_DF.id .== node_id, :], :timestamp).code
    isempty(codes) ? missing : codes[1]
end

function to_view_df(df)
    atags = []
    node_atags = map(x -> HtmlCell{String}("<a href=\"https://www.openstreetmap.org/node/$x\">$x</a>"), df.id)

    for r in eachrow(df)
        atag = make_atag(r.tags, r.maps_url)
        push!(atags, atag)
    end

    view_df = df[:, [:id, :time_distance, :lat, :lon, :maps_url]]
    view_df.maps_url = atags
    view_df.id = node_atags
    view_df.code = find_code.(df.id)
    view_df.submit_form .= make_form_cell.(df.id)

    sort!(view_df, :time_distance)
    view_df
end

export get_site, get_json, to_df
export CODE_DF, make_form_cell, make_atag, find_code, to_view_df

end # module Free2Pee
