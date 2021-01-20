
function LayerTrace(gml,target,tileReg;omitThemes::Array=[],colour::String="#aaaaaa",CropOutOfBounds::Bool=false)
    iKeep = findall([length(findall(descr.==target))>0 for descr in gml.summary.descr])
    if !isempty(omitThemes)
        iKeep2 = vcat([findall([length(findall(theme.==omitTheme))==0 for theme in gml.summary.theme]) for omitTheme in omitThemes]...)
        iKeep = intersect(iKeep,iKeep2)
    end

    xs = vcat(gml.summary.eastings[iKeep]...)
    ys = vcat(gml.summary.northings[iKeep]...)

    if CropOutOfBounds == true
        ob_up = findall([sum(y.>tileReg.northings_max)==length(y) for y in ys])
        ob_down = findall([sum(y.<tileReg.northings_min)==length(y) for y in ys])
        ob_left = findall([sum(x.<tileReg.eastings_min)==length(x) for x in xs])
        ob_right = findall([sum(x.>tileReg.eastings_max)==length(x) for x in xs])

        iOB = unique(vcat(ob_up,ob_down,ob_left,ob_right))
        xs = xs[Not(iOB)]
        ys = ys[Not(iOB)]

        ob_up = [findall(y.>tileReg.northings_max) for y in ys]
        ob_down = [findall(y.<tileReg.northings_min) for y in ys]
        ob_left = [findall(x.<tileReg.eastings_min) for x in xs]
        ob_right = [findall(x.>tileReg.eastings_max) for x in xs]

        iRm = [unique(vcat(ob_up[i],ob_down[i],ob_left[i],ob_right[i])) for i in 1:length(xs)]
        [xs[i] = xs[i][Not(iRm[i])] for i in 1:length(xs)]
        [ys[i] = ys[i][Not(iRm[i])] for i in 1:length(xs)]

    end

    xs = vcat([vcat(pts,NaN) for pts in xs]...)
    ys = vcat([vcat(pts,NaN) for pts in ys]...)

    trace = scatter(x=xs,y=ys,name=gml.tile,mode="lines",line=attr(width=0.2,color=colour),hoverinfo="skip",hovertemplate=nothing)
    return trace
end

function SelectTile(env,project,ui,tileRef)
    function writeJSON(json_string,tileRef)
        open(".GmlParsed/$(tileRef).json","w") do f
            write(f,json_string)
        end
    end
    function readJSON(tileRef)
        io = open(".GmlParsed/$(tileRef).json")
        content = readlines(io)
        close(io)
        data_dict = JSON.parse(content[1])
        data = DataFrame(data_dict)
    end


    # Index of current tile in register
    iTile = findfirst(project.tileRegister.tileRefs.==tileRef)

    # "loading" pop-up
    w_popup = Window(Dict(:title=>"Loading...",:width=>500,:height=>150))
    body!(w_popup,"Loading $(tileRef) ...")
    sleep(0.1)

    # Clear blank initialising trace
    iRm = findall([tr[:name] for tr in ui.p0.plot.data].=="blank")
    [deletetraces!(ui.p0,i) for i in iRm]

    # Check for pre-existing parsed GML
    GmlParsedDir = readdir(joinpath(env.paths[:projects],".GmlParsed"))
    if sum(occursin.(tileRef,GmlParsedDir)).==1
        # Load data for new tile
        data_dict = readJSON(tileRef)
        data = DataFrame(data_dict)

        gml = ParaDwell.GML(tileRef,"",[""],[[""]],data)
    else
        # Load data for new tile
        gml = ParaDwell.ProcessGMLs(env.paths[:OS],tileRef)
        json_string = JSON.json(gml.summary)
        writeJSON(json_string,tileRef)
    end


    if !haskey(project.dat,"gml")
        push!(project.dat,"gml"=>[gml])
    else
        push!(project.dat["gml"],gml)
    end

    traces = []

    # Plot tile boundary
    x_boundary_OSEN = [project.tileRegister.eastings_min[iTile];project.tileRegister.eastings_max[iTile];project.tileRegister.eastings_max[iTile];project.tileRegister.eastings_min[iTile];project.tileRegister.eastings_min[iTile]]
    y_boundary_OSEN = [project.tileRegister.northings_min[iTile];project.tileRegister.northings_min[iTile];project.tileRegister.northings_max[iTile];project.tileRegister.northings_max[iTile];project.tileRegister.northings_min[iTile]]
    tmp = [ParaDwell.OSENtoLLA(x_boundary_OSEN[i],y_boundary_OSEN[i]) for i in 1:length(y_boundary_OSEN)]
    x_boundary_LLA = [i[2] for i in tmp]
    y_boundary_LLA = [i[1] for i in tmp]
    push!(traces,scatter(
        x=x_boundary_OSEN,
        y=y_boundary_OSEN,
        mode="lines",
        line=attr(color="#aaaaaaaa",width=1),
        name=tileRef,
        hoverinfo="skip",hovertemplate=nothing
    ))
    traces_boundary_macroLLA = scatter(
        x=x_boundary_LLA,
        y=y_boundary_LLA,
        mode="lines",
        line=attr(color="#aaaaaaaa",width=1),
        name=tileRef,
        hoverinfo="skip",hovertemplate=nothing
    )

    # Plot map layers
    push!(traces,LayerTrace(gml,"Natural Environment",project.tileRegister[iTile,:];colour="#aaaaaa",CropOutOfBounds=true))
    push!(traces,LayerTrace(gml,"Road Or Track",project.tileRegister[iTile,:];colour="#ff9f43",CropOutOfBounds=true))
    push!(traces,LayerTrace(gml,"Building",project.tileRegister[iTile,:];omitThemes=["Land"],colour="#1e3799"))

    # Add all new traces
    [addtraces!(ui.p0,trace) for trace in traces] # Main UI
    addtraces!(ui.plt_macro,traces_boundary_macroLLA) # Macro-map UI
    sleep(0.1)
    close(w_popup)

    return project
end

function ClickTile(env,project,ui)

    on(ui.plt_macro["click"]) do dat

        # Determine selected point
        X = dat["points"][1]["x"]
        Y = dat["points"][1]["y"]

        # Find selected tile
        iTile  = intersect(findall(project.tileRegister.Lon_mid.==X),findall(project.tileRegister.Lat_mid.==Y))[1]
        tileRef = project.tileRegister.tileRefs[iTile]

        # Print to console
        println("TileRef selected: $tileRef")

        # Gather and plot data for selected tile
        project = SelectTile(env,project,ui,tileRef)
    end
end
