using ParaDwell
using CSSUtil, Interact, Blink, CSV, DataFrames, PlotlyJS

# Constructor script
env = ParaDwell.loadPaths()
ParaDwell.OS_TileSummries(env)
project = ParaDwell.Project()
project.dat = Dict()
project.tileRegister = CSV.read(joinpath(env.paths[:projects],".OS_TileRegister.csv"), DataFrame)

include("UI/MainUI_Launch.jl")
include("Util/DataLinks.jl")
include("DataMethods/DataLinks.jl")
include("DataMethods/GeoRef.jl")

ui = LaunchMainUI(env);
include("UI/ClickTile.jl")
ClickTile(env,project,ui)
project = SelectTile(env,project,ui,"HY40NE")
# project = SelectTile(env,project,ui,"HY40NW")

# Click tile
project = LinkHaData(env,project)
