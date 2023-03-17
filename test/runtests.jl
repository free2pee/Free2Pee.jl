using Free2Pee
using Oxygen, JSON3, Downloads, CSV, DataFrames, JSONTables, PrettyTables, HTTP, URIs
using Test

include("overpass_api.jl")

df = Free2Pee.to_df(Free2Pee.LAT, Free2Pee.LON)
view_df = to_view_df(df)
@test names(view_df) == ["id", "time_distance", "lat", "lon", "maps_url", "code", "submit_form"]

# r = internalrequest(HTTP.Request("GET", "/42.3581539/-71.1059027"))
# @test r.status == 200
# s = String(r.body)

# todo https://discourse.julialang.org/t/is-there-a-ready-made-function-to-convert-a-gumbo-jl-parsed-html-table-into-a-table-like-dataframes-dataframe/55973/3 
# parse to dataframe and add tests on the result
