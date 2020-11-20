
IncludeDescrIndices(gml,target) = findall([length(findall(descr.==target))>0 for descr in gml.summary.descr])


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

    gml = ParaDwell.ProcessGMLs(env.paths[:OS],tileRegister.tileRefs[iTile])

    iKeep = Dict()
    # iKeep["General"] = IncludeDescrIndices(gml,"General Surface")
    # iKeep["Path"] = IncludeDescrIndices(gml,"Path")
    iKeep["Building"] = IncludeDescrIndices(gml,"Building")
    iKeep["Road"] = IncludeDescrIndices(gml,"Road Or Track")
    # iKeep["Roadside"] = IncludeDescrIndices(gml,"Roadside")
    # iKeep["Structure"] = IncludeDescrIndices(gml,"Structure")
    # iKeep["Landform"] = IncludeDescrIndices(gml,"Landform")
    iKeep["Natural"] = IncludeDescrIndices(gml,"Natural Environment")
    # iKeep["Tidal"] = IncludeDescrIndices(gml,"Tidal Water")
    # iKeep["Inland"] = IncludeDescrIndices(gml,"Inland Water")
    # iKeep["Unclassified"] = IncludeDescrIndices(gml,"Unclassified")
    # iKeep["Historic"] = IncludeDescrIndices(gml,"Historic Interest")
    # iKeep["Network"] = IncludeDescrIndices(gml,"Network Or Polygon Closing Geometry")
    # iKeep["General"] = IncludeDescrIndices(gml,"General Feature")
    # iKeep["Terrain"] = IncludeDescrIndices(gml,"Terrain And Height")

    xs = vcat([vcat(pts,NaN) for pts in vcat(gml.summary.eastings[iKeep["Building"]]...)]...)
    ys = vcat([vcat(pts,NaN) for pts in vcat(gml.summary.northings[iKeep["Building"]]...)]...)
    trace = scatter(x=xs,y=ys,mode="lines",line=attr(width=0.2),hoverinfo="skip",hovertemplate=nothing)
    addtraces!(ui.p0,trace)

    xs = vcat([vcat(pts,NaN) for pts in vcat(gml.summary.eastings[iKeep["Road"]]...)]...)
    ys = vcat([vcat(pts,NaN) for pts in vcat(gml.summary.northings[iKeep["Road"]]...)]...)
    trace = scatter(x=xs,y=ys,mode="lines",line=attr(width=0.2),hoverinfo="skip",hovertemplate=nothing)
    addtraces!(ui.p0,trace)

    xs = vcat([vcat(pts,NaN) for pts in vcat(gml.summary.eastings[iKeep["Natural"]]...)]...)
    ys = vcat([vcat(pts,NaN) for pts in vcat(gml.summary.northings[iKeep["Natural"]]...)]...)
    trace = scatter(x=xs,y=ys,mode="lines",line=attr(width=0.2),hoverinfo="skip",hovertemplate=nothing)
    addtraces!(ui.p0,trace)



    # latLonRatio = cos(midLat*π/180)

    sleep(0.1)
    close(w_popup)
    return gml

end
