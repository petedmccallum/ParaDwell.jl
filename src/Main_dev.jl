using ParaDwell
using CSSUtil, Interact, Blink, CSV, DataFrames, PlotlyJS, StatsBase, JSON

# Constructor script
env = ParaDwell.loadPaths()

try
    close(ui.mainWindow)
catch
end

ParaDwell.OS_TileSummries(env)
project = ParaDwell.Project()
project.dat = Dict()
project.tileRegister = CSV.read(joinpath(env.paths[:projects],".OS_TileRegister.csv"), DataFrame)

include("UI/MainUI_Launch.jl")
include("Util/DataLinks.jl")
include("Util/JsonHandling.jl")
include("DataMethods/DataLinks.jl")
include("DataMethods/GeoRef.jl")
include("ParametricModel/ParametricModel.jl")

ui = LaunchMainUI(env);
include("UI/ClickTile.jl")
ClickTile(env,project,ui)
project = SelectTile(env,project,ui,"HY40NE")
project = SelectTile(env,project,ui,"HY40NW")
project = SelectTile(env,project,ui,"HY41SW")
project = SelectTile(env,project,ui,"HY41SE")
# project = SelectTile(env,project,ui,"NZ16SE")

@time project = LoadStockData(env,project)
