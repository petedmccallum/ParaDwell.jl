module ParaDwell

using Shapefile, GeoInterface, PlotlyJS, CSV, DataFrames
using LightXML, Interact, Blink, Images, CSVFiles, StatsBase


include("structs.jl")
include("Init.jl")
include("Mapping/Coastline.jl")
include("Mapping/Conversion.jl")
include("Mapping/SummariseOsData.jl")
include("XmlTools/OrdnanceSurvey.jl")
include("XmlTools/structs.jl")
include("XmlTools/xmlParse.jl")
# include("UI/MainUI_Launch.jl")
# include("UI/ClickTile.jl")


end
