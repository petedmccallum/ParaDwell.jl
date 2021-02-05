using ParaDwell
using CSSUtil, Interact, Blink, CSV, DataFrames, PlotlyJS, StatsBase, JSON
using Dates

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
include("Util/ExportData.jl")
include("Util/GeomOperations.jl")
include("DataMethods/DataLinks.jl")
include("DataMethods/LinkEpcData.jl")
include("DataMethods/LinkOsBhaData.jl")
include("DataMethods/GeoRef.jl")
include("ParametricModel/ProcessGeom.jl")
include("ParametricModel/LinkMultiDwellingPlans.jl")
include("ParametricModel/ParametricModel.jl")
include("ParametricModel/ExtrapolateEpc.jl")

ui = LaunchMainUI(env);
include("UI/ClickTile.jl")
ClickTile(env,project,ui)
project = SelectTile(env,project,ui,"HY40NE")
project = SelectTile(env,project,ui,"HY40NW")
project = SelectTile(env,project,ui,"HY41SW")
project = SelectTile(env,project,ui,"HY41SE")
# project = SelectTile(env,project,ui,"NZ16SE")

@time project = LoadStockData(env,project)

@time project = buildarchetypes(project)

@time fillblockconfig.((project.dat["master"],),2:4)

@time abovebelowadj(project.dat["master"])

@time gen_archcode(project.dat["master"],1.)

# exportstockdata(project)
