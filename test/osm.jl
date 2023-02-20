using Free2Pee, EzXML, XMLDict, CSV, DataFrames, JSON3, JSONTables
_fn = "osmmap_central.osm"
fn = Free2Pee.data(_fn)
# x = get_map_data(fn)
# y = OpenStreetMapX.parseOSM(fn)

z = readxml(fn)
z.node
n = z.node
d = XMLDict.xml_dict(z)
ns = d["osm"]["node"]

lol = Dict(map(x -> x[:id], ns) .=> ns)
target = "4817053508"
tar = lol[target]["tag"]

tns = ns[haskey.(ns, "tag")]
collect(skipmissing(get_tag.(tns)))

ts = map(x->x["tag"], tns)

function tags_to_dict(tags)
    if tags isa AbstractVector
        return Dict(tag[:k] => tag[:v] for tag in tags)
    else
        # xmldict doesn't always return vec so we special case the single tag case
        return Dict(tags[:k] => tags[:v])
    end
end
toilets_idxs = findall(x->haskey(x, "toilets"), tags_to_dict.(ts))
tls = tns[toilets_idxs]

latitude = 42.3640906
longitude = -71.1018806

"the alg"
dist(x, y) = sqrt((x[1] - y[1])^2 + (x[2] - y[2])^2)

j = JSON3.read(read("sample.json"))
ns = j.elements

function lat_long_pair(n)
    return (n["lat"], n["lon"])
end

ps = lat_long_pair.(ns)
distances = dist.(ps, Ref((latitude, longitude)))
sorted_ns = ns[sortperm(distances)]
DataFrame(sorted_ns)


fn = _data("luxembourg.osm")
z = readxml(fn)
z.node
n = z.node
d = XMLDict.xml_dict(z)
