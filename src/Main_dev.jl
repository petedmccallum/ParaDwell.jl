using ParaDwell
using CSSUtil, Interact, Blink, CSV, DataFrames, PlotlyJS

# Constructor script
global env = ParaDwell.loadPaths()
ParaDwell.OS_TileSummries(env)
project = ParaDwell.Project()
project.dat = Dict()

include("UI/MainUI_Launch.jl")
include("UI/ClickTile.jl")
include("Util/DataLinks.jl")
include("DataMethods/DataLinks.jl")
include("DataMethods/GeoRef.jl")

Launch(env,project)

# Click
project = LinkHaData(project)
