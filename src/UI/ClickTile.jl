include("MainUI_Launch.jl")

function LayerTrace(gml,target,tileRegister;omitThemes::Array=[],colour::String="#aaaaaa",CropOutOfBounds::Bool=false)
    iKeep = findall([length(findall(descr.==target))>0 for descr in gml.summary.descr])
    if !isempty(omitThemes)
        iKeep2 = vcat([findall([length(findall(theme.==omitTheme))==0 for theme in gml.summary.theme]) for omitTheme in omitThemes]...)
        iKeep = intersect(iKeep,iKeep2)
    end

    xs = vcat(gml.summary.eastings[iKeep]...)
    ys = vcat(gml.summary.northings[iKeep]...)

    if CropOutOfBounds == true
        ob_up = findall([sum(y.>tileRegister.northings_max)==length(y) for y in ys])
        ob_down = findall([sum(y.<tileRegister.northings_min)==length(y) for y in ys])
        ob_left = findall([sum(x.<tileRegister.eastings_min)==length(x) for x in xs])
        ob_right = findall([sum(x.>tileRegister.eastings_max)==length(x) for x in xs])

        iOB = unique(vcat(ob_up,ob_down,ob_left,ob_right))
        xs = xs[Not(iOB)]
        ys = ys[Not(iOB)]

        ob_up = [findall(y.>tileRegister.northings_max) for y in ys]
        ob_down = [findall(y.<tileRegister.northings_min) for y in ys]
        ob_left = [findall(x.<tileRegister.eastings_min) for x in xs]
        ob_right = [findall(x.>tileRegister.eastings_max) for x in xs]

        iRm = [unique(vcat(ob_up[i],ob_down[i],ob_left[i],ob_right[i])) for i in 1:length(xs)]
        [xs[i] = xs[i][Not(iRm[i])] for i in 1:length(xs)]
        [ys[i] = ys[i][Not(iRm[i])] for i in 1:length(xs)]

    end

    xs = vcat([vcat(pts,NaN) for pts in xs]...)
    ys = vcat([vcat(pts,NaN) for pts in ys]...)

    trace = scatter(x=xs,y=ys,name=gml.tile,mode="lines",line=attr(width=0.2,color=colour),hoverinfo="skip",hovertemplate=nothing)
    return trace
end


function Launch(env,project)
    ui, plt_nationwide = LaunchMainUI(env);

    on(plt_nationwide["click"]) do dat

        # Determine selected point
        X = dat["points"][1]["x"]
        Y = dat["points"][1]["y"]

        # Find selected tile
        tileRegister = CSV.read(joinpath(env.paths[:projects],".OS_TileRegister.csv"), DataFrame)
        iTile  = intersect(findall(tileRegister.Lon_mid.==X),findall(tileRegister.Lat_mid.==Y))[1]

        # "loading" pop-up
        w_popup = Window(Dict(:title=>"Loading...",:width=>500,:height=>150))
        body!(w_popup,"Loading $(tileRegister.tileRefs[iTile]) ...")
        sleep(0.1)

        # Clear blank initialising trace, optionally clear all traces
        iRm = findall([tr[:name] for tr in ui.p0.plot.data].=="blank")
        [deletetraces!(ui.p0,i) for i in iRm]
        # [deletetraces!(ui.p0,i) for i in length(ui.p0.plot.data):-1:1]

        # Load data for new tile
        gml = ParaDwell.ProcessGMLs(env.paths[:OS],tileRegister.tileRefs[iTile])
        if !haskey(project.dat,"gml")
            push!(project.dat,"gml"=>[gml])
        else
            push!(project.dat["gml"],gml)
        end

        # Plot layers
        traces = []
        push!(traces,LayerTrace(gml,"Building",tileRegister[iTile,:];omitThemes=["Land"],colour="#1e3799"))
        push!(traces,LayerTrace(gml,"Road Or Track",tileRegister[iTile,:];colour="#ff9f43",CropOutOfBounds=true))
        push!(traces,LayerTrace(gml,"Natural Environment",tileRegister[iTile,:];colour="#aaaaaa",CropOutOfBounds=true))

        # Plot tile boundary
        x_boundary_OSEN = [tileRegister.eastings_min[iTile];tileRegister.eastings_max[iTile];tileRegister.eastings_max[iTile];tileRegister.eastings_min[iTile];tileRegister.eastings_min[iTile]]
        y_boundary_OSEN = [tileRegister.northings_min[iTile];tileRegister.northings_min[iTile];tileRegister.northings_max[iTile];tileRegister.northings_max[iTile];tileRegister.northings_min[iTile]]
        tmp = [ParaDwell.OSENtoLLA(x_boundary_OSEN[i],y_boundary_OSEN[i]) for i in 1:length(y_boundary_OSEN)]
        x_boundary_LLA = [i[2] for i in tmp]
        y_boundary_LLA = [i[1] for i in tmp]
        push!(traces,scatter(
            x=x_boundary_OSEN,
            y=y_boundary_OSEN,
            mode="lines",
            line=attr(color="#aaaaaaaa",width=1),
            name=tileRegister.tileRefs[iTile],
            hoverinfo="skip",hovertemplate=nothing
        ))
        traces_boundary_macroLLA = scatter(
            x=x_boundary_LLA,
            y=y_boundary_LLA,
            mode="lines",
            line=attr(color="#aaaaaaaa",width=1),
            name=tileRegister.tileRefs[iTile],
            hoverinfo="skip",hovertemplate=nothing
        )
        # Add all new traces
        [addtraces!(ui.p0,trace) for trace in traces] # Main UI
        addtraces!(plt_nationwide,traces_boundary_macroLLA) # Macro-map UI
        sleep(0.1)
        close(w_popup)
    end
end


project = ParaDwell.Project()
project.dat = Dict()
Launch(env,project)