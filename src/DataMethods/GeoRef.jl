
function RayTrace(project,itarget,m,c,e)
    # Set (gradient, c0 and x0) of ray
    # m0 = 0
    x0 = project.dat["master"].Easting_HA[itarget]
    c0 = project.dat["master"].Northing_HA[itarget]

    # Find x-crossing of ray and each boundary -> m*x + c = m0*x0 + c0
    x = (c0 .- c)./m

    # Set bounds on x-crossing for earch boundary
    limits = Dict(
        "upper" => maximum([e[1:end-1] e[2:end]],dims=2),
        "lower" => minimum([e[1:end-1] e[2:end]],dims=2),
    )

    # Count number of boundary crossings
    count = sum(intersect(
        findall([x[i].<limits["upper"][i] for i in 1:size(limits["upper"],1)]),
        findall([x[i].>maximum([x0 limits["lower"][i]]) for i in 1:size(limits["lower"],1)]),
    ).>0)

    # Set interior/exterior (odd/even) condition
    interior = isodd(count)

    return interior
end

function GeoRef(project,k)
    # Identify features labelled as "Building" in "descr" column, but also
    # ... exclude "Land" and "Roads Tracks And Paths" in "theme col")
    f = project.dat["gml"][k].summary
    iKeep = intersect(
        findall([length(findall(descr.=="Building"))>0 for descr in f.descr]),
        findall([length(findall(theme.=="Land"))==0 for theme in f.theme]),
        findall([length(findall(descr.=="Roads Tracks And Paths"))==0 for descr in f.theme])
    )
    # Remove all geom with length <4 (adiabatic boundaries - no-rigorous method)
    f = project.dat["gml"][k].summary[iKeep,:]
    iKeep = iKeep[findall(length.([eastings[1] for eastings in f.eastings]).>=5)]

    for j in iKeep
        # Eastings/Northings vectors for current feature
        e = project.dat["gml"][k].summary.eastings[j][1]
        n = project.dat["gml"][k].summary.northings[j][1]

        # Gradients and zero-offsets for each boundary (linear eqn)
        m = diff(n)./diff(e)
        c = n[2:end] - m.*e[2:end]

        # HA Eastings/Northings matches (can be more than one)
        iTarget = intersect(
            findall(project.dat["master"].Easting_HA.>=minimum(e)),
            findall(project.dat["master"].Easting_HA.<=maximum(e)),
            findall(project.dat["master"].Northing_HA.>=minimum(n)),
            findall(project.dat["master"].Northing_HA.<=maximum(n)),
        )

        interior_bool = [RayTrace(project,itarget,m,c,e) for itarget in iTarget]

        interior_pts = iTarget[interior_bool]

        project.dat["master"].osgb_tile[interior_pts] .= project.dat["gml"][k].tile
        project.dat["master"].iGml[interior_pts] .= j
        project.dat["master"].osgb[interior_pts] .= project.dat["gml"][k].summary.osgb[j]
    end

    return project
end
