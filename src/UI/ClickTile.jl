include("MainUI_Launch.jl")

function PlotLayer(gml,target;colour::String="#aaaaaa")
    iKeep = findall([length(findall(descr.==target))>0 for descr in gml.summary.descr])

    xs = vcat([vcat(pts,NaN) for pts in vcat(gml.summary.eastings[iKeep]...)]...)
    ys = vcat([vcat(pts,NaN) for pts in vcat(gml.summary.northings[iKeep]...)]...)
    trace = scatter(x=xs,y=ys,name=gml.tile,mode="lines",line=attr(width=0.2,color=colour),hoverinfo="skip",hovertemplate=nothing)
    addtraces!(ui.p0,trace)
end

plt_nationwide = LaunchMainUI(env);
on(plt_nationwide["click"]) do dat
    # Determine selected point
    X = dat["points"][1]["x"]
    Y = dat["points"][1]["y"]

    # DEBUG
    println("X → $(X) \tY → $(Y)")

    # Find selected tile
    tileRegister = CSV.read(joinpath(env.paths[:projects],".OS_TileRegister.csv")) |> DataFrame
    iTile  = intersect(findall(tileRegister.Lon_mid.==X),findall(tileRegister.Lat_mid.==Y))[1]



    w_popup = Window(Dict(:width=>500,:height=>150))
    body!(w_popup,"Loading $(tileRegister.tileRefs[iTile]) ...")
    sleep(0.1)
    iRm = findall([tr[:name] for tr in ui.p0.plot.data].=="blank")
    [deletetraces!(ui.p0,i) for i in iRm]
    [deletetraces!(ui.p0,i) for i in length(ui.p0.plot.data):-1:1]

    gml = ParaDwell.ProcessGMLs(env.paths[:OS],tileRegister.tileRefs[iTile])

    # PlotLayer(gml,"General Surface",colour="#aaaaaa")
    # PlotLayer(gml,"Path",colour="#aaaaaa")
    PlotLayer(gml,"Building",colour="#0984e3")
    PlotLayer(gml,"Road Or Track",colour="#ff9f43")
    # PlotLayer(gml,"Roadside",colour="#aaaaaa")
    # PlotLayer(gml,"Structure",colour="#aaaaaa")
    # PlotLayer(gml,"Landform",colour="#aaaaaa")
    PlotLayer(gml,"Natural Environment",colour="#aaaaaa")
    # PlotLayer(gml,"Tidal Water",colour="#aaaaaa")
    # PlotLayer(gml,"Inland Water",colour="#aaaaaa")
    # PlotLayer(gml,"Unclassified",colour="#aaaaaa")
    # PlotLayer(gml,"Historic Interest",colour="#aaaaaa")
    # PlotLayer(gml,"Network Or Polygon Closing Geometry",colour="#aaaaaa")
    # PlotLayer(gml,"General Feature",colour="#aaaaaa")
    # PlotLayer(gml,"Terrain And Height",colour="#aaaaaa")

    # latLonRatio = cos(midLat*π/180)

    sleep(0.1)
    close(w_popup)
    return gml

end
