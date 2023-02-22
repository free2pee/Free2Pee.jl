using Free2Pee
using Oxygen, JSON3, Downloads, CSV, DataFrames, JSONTables, PrettyTables, HTTP, URIs, Distances

# lat = 42.3640906
# lon = -71.1018806

# h = HTTP.get(test_uri)
# 4360543295
example_query = "https://www.google.com/maps/dir/?api=1&origin=<lat, long>&destination=<lat, long>"


@get "/{lat}/{lon}" function foo(req::HTTP.Request, lat, lon)
    lat = parse(Float64, lat)
    lon = parse(Float64, lon)
    df = to_df(lat, lon)
    view_df = df[:, [:id, :distance, :time_distance, :lat, :lon, :maps_url]]
    sort!(view_df, :time_distance)
    io = IOBuffer()
    pretty_table(io, view_df, nosubheader=true, backend=Val(:html))
    
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

# serve(;host="10.0.0.224")
serve()

# try this not haversine
# curl 'http://router.project-osrm.org/route/v1/driving/13.388860,52.517037;13.397634,52.529407;13.428555,52.523219?overview=false'
