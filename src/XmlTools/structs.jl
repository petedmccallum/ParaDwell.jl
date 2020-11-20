
struct GML
    tile::String
    path::String
    dat::Vector{SubString{String}}
    features::Vector{Array{SubString{String},1}}
    summary::DataFrame
end
