using Free2Pee
using Oxygen, JSON3, Downloads, CSV, DataFrames, JSONTables, PrettyTables, HTTP, URIs, Distances
@info "usings"

const LAT = 42.35810736568732
const LON = -71.10592447014132

function foo(tag, url)
    if haskey(tag, :name) 
        name = tag.name
        HtmlCell{String}("<a href=\"$url\">$name</a>")
    else 
        HtmlCell{String}("<a href=\"$url\">BingBong</a>")
    end
end

@get "/{lat}/{lon}" function foo(req::HTTP.Request, lat, lon)
    lat = parse(Float64, lat)
    lon = parse(Float64, lon)
    df = Free2Pee.to_df(lat, lon)
    view_df = df[:, [:id, :distance, :lat, :lon, :maps_url]]
    atags = []
    for r in eachrow(df)
        atag = foo(r.tags, r.maps_url)
        push!(atags, atag)
    end

    view_df.maps_url = atags
    sort!(view_df, :distance)
    io = IOBuffer()
    pretty_table(io, view_df, nosubheader=true, backend=Val(:html); allow_html_in_cells=true)
    
    HTTP.Response(200, ["Content-Type" => "text/html"]; body=take!(io))
end

@get "/" function (req::HTTP.Request)
    HTTP.Response(200, ["Content-Type" => "text/html"]; body="""
    <html>
    <head>
    <title>Free2Pee</title>
    </head>
    <body>
    <h1>Free2Pee</h1>
    <p>Find the nearest public toilets</p>
    <form action="/$LAT/$LON">
    <input type="submit" value="Submit">
    </form>
    </body>
    </html>
    """)
end

@get "/loc" function (req::HTTP.Request)
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
    x.innerHTML="Latitude: " + position.coords.latitude + 
    "<br>Longitude: " + position.coords.longitude;  
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
    return function(req::HTTP.Request)
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
serve(;middleware=[CorsHandler])

    # serve(;host="10.0.0.224")
# serve(;port=8080)

# try this not haversine
# curl 'http://router.project-osrm.org/route/v1/driving/13.388860,52.517037;13.397634,52.529407;13.428555,52.523219?overview=false'
