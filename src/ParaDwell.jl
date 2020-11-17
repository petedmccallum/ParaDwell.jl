module ParaDwell

using Shapefile, GeoInterface, PlotlyJS, CSV, DataFrames
using LightXML, Interact, Blink, Images


include("structs.jl")
include("Init.jl")
include("Mapping/Coastline.jl")
include("Mapping/Conversion.jl")
include("Mapping/SummariseOsData.jl")


end
