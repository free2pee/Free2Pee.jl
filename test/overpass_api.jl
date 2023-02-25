using Free2Pee
using Oxygen, JSON3, Downloads, CSV, DataFrames, JSONTables, PrettyTables, HTTP, URIs, Distances, Dates
@info "usings"

const LAT = 42.35810736568732
const LON = -71.10592447014132

function make_form_cell(node_id)
    HtmlCell{String}("""<form action="/submit">
    <label for="code">Code:</label>
    <input type="text" id="code" name="code" value="">
    <label for="node_id">DONT CHANGE</label>
    <input type="text" id="node_id" name="node_id" value="$node_id">
    <input type="submit" value="Submit">
    </form>""")
end

function make_atag(tag, url)
    if haskey(tag, :name)
        name = tag.name
        HtmlCell{String}("<a href=\"$url\">$name</a>")
    else
        HtmlCell{String}("<a href=\"$url\">BingBong</a>")
    end
end

@get "/{lat}/{lon}" function foo(req::HTTP.Request, lat, lon)
    qps = Oxygen.queryparams(req)

    if haskey(qps, "radius")
        radius = parse(Int, qps["radius"])
    else
        radius = 1000
    end

    lat = parse(Float64, lat)
    lon = parse(Float64, lon)
    df = Free2Pee.to_df(lat, lon; radius)
    atags = []
    node_atags = map(x -> HtmlCell{String}("<a href=\"https://www.openstreetmap.org/node/$x\">$x</a>"), df.id)

    for r in eachrow(df)
        atag = make_atag(r.tags, r.maps_url)
        push!(atags, atag)
    end

    view_df = df[:, [:id, :distance, :time_distance, :lat, :lon, :maps_url]]
    view_df.maps_url = atags
    view_df.id = node_atags
    view_df.submit_form .= make_form_cell.(df.id)

    sort!(view_df, :time_distance)
    io = IOBuffer()
    pretty_table(io, view_df, nosubheader=true, backend=Val(:html); allow_html_in_cells=true)

    HTTP.Response(200, ["Content-Type" => "text/html"]; body=take!(io))
end

@get "/submit" function (req::HTTP.Request)
    qps = Oxygen.queryparams(req)
    node_id = qps["node_id"]
    code = qps["code"]

    row = (;
        id = parse(Int, node_id),
        code = code,
        timestamp = now(),
        ply_count = 1
    )

    push!(CODE_DF, row)
    CSV.write(Free2Pee.DATABASE_PATH, CODE_DF)
    io = IOBuffer()
    pretty_table(io, CODE_DF, nosubheader=true, backend=Val(:html); allow_html_in_cells=true)
    HTTP.Response(200, ["Content-Type" => "text/html"]; body=take!(io))
end

# just for testing, remove this endpoint 
# @get "/" function (req::HTTP.Request)
#     df = Free2Pee.to_df(LAT, LON)
#     atags = []
#     node_atags = map(x -> HtmlCell{String}("<a href=\"https://www.openstreetmap.org/node/$x\">$x</a>"), df.id)

#     for r in eachrow(df)
#         atag = make_atag(r.tags, r.maps_url)
#         push!(atags, atag)
#     end

#     view_df = df[:, [:id, :distance, :time_distance, :lat, :lon, :maps_url]]
#     view_df.maps_url = atags
#     view_df.id = node_atags
#     view_df.code = find_code.(df.id)
#     view_df.submit_form .= make_form_cell.(df.id)
#     sort!(view_df, :time_distance)
#     io = IOBuffer()
#     pretty_table(io, view_df, nosubheader=true, backend=Val(:html); allow_html_in_cells=true)

#     HTTP.Response(200, ["Content-Type" => "text/html"]; body=take!(io))
# end

function find_code(node_id)
    codes = sort(CODE_DF[CODE_DF.id .== node_id, :], :timestamp).code
    isempty(codes) ? missing : codes[1]
end

# "using window.location.replace might not be the best"
@get "/" function (req::HTTP.Request)
    HTTP.Response(200, ["Content-Type" => "text/html"]; body="""
<!DOCTYPE html>
<html>
<body>

<p id="demo">Click the button to get your coordinates:</p>

<button onclick="getLocation()">Try It</button>

<script>
var x = document.getElementById("demo");

function getLocation() {
    if (navigator.geolocation) {
        navigator.geolocation.getCurrentPosition(
            // Success function
            showPosition, 
            // Error function
            null, 
            // Options. See MDN for details.
            {
               enableHighAccuracy: true,
               timeout: 5000,
               maximumAge: 0
            });
    } else { 
        x.innerHTML = "Geolocation is not supported by this browser.";
    }
}

function showPosition(position) {
    href = "/" + position.coords.latitude + "/" + position.coords.longitude
    window.location.replace(href);
}
</script>

</body>
</html>
    """)
end

# CORS headers that show what kinds of complex requests are allowed to API
headers = [
    "Access-Control-Allow-Origin" => "*",
    "Access-Control-Allow-Headers" => "*",
    "Access-Control-Allow-Methods" => "GET, POST"
]

function CorsHandler(handle)
    return function (req::HTTP.Request)
        # return headers on OPTIONS request
        if HTTP.method(req) == "OPTIONS"
            return HTTP.Response(200, headers)
        else
            return handle(req)
        end
    end
end

# start the web server
# serve(host="0.0.0.0", middleware=[CorsHandler])
serve(; port=8001, middleware=[CorsHandler])

# serve(;host="10.0.0.224")
# serve(;port=8080)

# try this not haversine
# curl 'http://router.project-osrm.org/route/v1/driving/13.388860,52.517037;13.397634,52.529407;13.428555,52.523219?overview=false'
