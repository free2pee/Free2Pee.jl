using Free2Pee
using Oxygen, JSON3, Downloads, CSV, DataFrames, JSONTables, PrettyTables, HTTP, URIs, Distances

df = Free2Pee.to_df(Free2Pee.LAT, Free2Pee.LON)

"http://router.project-osrm.org/route/v1/driving/13.388860,52.517037;13.397634,52.529407;13.428555,52.523219?overview=false"