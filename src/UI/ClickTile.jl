include("MainUI_Launch.jl")

function LayerTrace(gml,target;colour::String="#aaaaaa",CropOutOfBounds::Bool=false)
    iKeep = findall([length(findall(descr.==target))>0 for descr in gml.summary.descr])

    xs = vcat(gml.summary.eastings[iKeep]...)
    ys = vcat(gml.summary.northings[iKeep]...)

    if CropOutOfBounds == true
        ob_up = findall([sum(y.>tileRegister.northings_max[iTile])==length(y) for y in ys])
        ob_down = findall([sum(y.<tileRegister.northings_min[iTile])==length(y) for y in ys])
        ob_left = findall([sum(x.<tileRegister.eastings_min[iTile])==length(x) for x in xs])
        ob_right = findall([sum(x.>tileRegister.eastings_max[iTile])==length(x) for x in xs])

        iOB = unique(vcat(ob_up,ob_down,ob_left,ob_right))
        xs = xs[Not(iOB)]
        ys = ys[Not(iOB)]
    end

    xs = vcat([vcat(pts,NaN) for pts in xs]...)
    ys = vcat([vcat(pts,NaN) for pts in ys]...)

    trace = scatter(x=xs,y=ys,name=gml.tile,mode="lines",line=attr(width=0.2,color=colour),hoverinfo="skip",hovertemplate=nothing)
    return trace
end

plt_nationwide = LaunchMainUI(env);

on(plt_nationwide["click"]) do dat

    # Determine selected point
    X = dat["points"][1]["x"]
    Y = dat["points"][1]["y"]

    # Find selected tile
    tileRegister = CSV.read(joinpath(env.paths[:projects],".OS_TileRegister.csv")) |> DataFrame
    iTile  = intersect(findall(tileRegister.Lon_mid.==X),findall(tileRegister.Lat_mid.==Y))[1]

    # "loading" pop-up
    w_popup = Window(Dict(:width=>500,:height=>150))
    body!(w_popup,"Loading $(tileRegister.tileRefs[iTile]) ...")
    sleep(0.1)

    # Clear blank initialising trace, optionally clear all traces
    iRm = findall([tr[:name] for tr in ui.p0.plot.data].=="blank")
    [deletetraces!(ui.p0,i) for i in iRm]
    [deletetraces!(ui.p0,i) for i in length(ui.p0.plot.data):-1:1]

    # Load data for new tile
    gml = ParaDwell.ProcessGMLs(env.paths[:OS],tileRegister.tileRefs[iTile])

    # Plot layers
    traces = []
    # push!(traces,LayerTrace(gml,"General Surface",colour="#aaaaaa"))
    # push!(traces,LayerTrace(gml,"Path",colour="#aaaaaa"))
    push!(traces,LayerTrace(gml,"Building",colour="#0984e3"))
    push!(traces,LayerTrace(gml,"Road Or Track",colour="#ff9f43",CropOutOfBounds=true))
    # push!(traces,LayerTrace(gml,"Roadside",colour="#aaaaaa"))
    # push!(traces,LayerTrace(gml,"Structure",colour="#aaaaaa"))
    # push!(traces,LayerTrace(gml,"Landform",colour="#aaaaaa"))
    push!(traces,LayerTrace(gml,"Natural Environment",colour="#aaaaaa",CropOutOfBounds=false))
    # push!(traces,LayerTrace(gml,"Tidal Water",colour="#aaaaaa"))
    # push!(traces,LayerTrace(gml,"Inland Water",colour="#aaaaaa"))
    # push!(traces,LayerTrace(gml,"Unclassified",colour="#aaaaaa"))
    # push!(traces,LayerTrace(gml,"Historic Interest",colour="#aaaaaa"))
    # push!(traces,LayerTrace(gml,"Network Or Polygon Closing Geometry",colour="#aaaaaa"))
    # push!(traces,LayerTrace(gml,"General Feature",colour="#aaaaaa"))
    # push!(traces,LayerTrace(gml,"Terrain And Height",colour="#aaaaaa"))

    # Plot tile boundary
    push!(traces,scatter(
        x=[tileRegister.eastings_min[iTile];tileRegister.eastings_max[iTile];tileRegister.eastings_max[iTile];tileRegister.eastings_min[iTile];tileRegister.eastings_min[iTile]],
        y=[tileRegister.northings_min[iTile];tileRegister.northings_min[iTile];tileRegister.northings_max[iTile];tileRegister.northings_max[iTile];tileRegister.northings_min[iTile]],
        mode="lines",
        line_color="#333333",
        name=tileRegister.tileRefs[iTile]
    ))

    # Add all new traces
    [addtraces!(ui.p0,trace) for trace in traces]

    sleep(0.1)
    close(w_popup)
    return gml

end
