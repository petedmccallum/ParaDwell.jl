
function RayTrace(project,itarget,m,c,e)
    # Set (gradient, c0 and x0) of ray
    # m0 = 0
    x0 = project.dat["HA"].Easting[itarget]
    c0 = project.dat["HA"].Northing[itarget]

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
    # Identify buildings only (excluding features that include 'Land')
    iKeep = intersect(
        findall([length(findall(descr.=="Building"))>0 for descr in project.dat["gml"][k].summary.descr]),
        findall([length(findall(descr.=="Land"))==0 for descr in project.dat["gml"][k].summary.theme])
    )

    for j in iKeep
        # Eastings/Northings vectors for current feature
        e = project.dat["gml"][k].summary.eastings[j][1]
        n = project.dat["gml"][k].summary.northings[j][1]

        # Gradients and zero-offsets for each boundary (linear eqn)
        m = diff(n)./diff(e)
        c = n[2:end] - m.*e[2:end]

        # HA Eastings/Northings matches (can be more than one)
        iTarget = intersect(
            findall(project.dat["HA"].Easting.>=minimum(e)),
            findall(project.dat["HA"].Easting.<=maximum(e)),
            findall(project.dat["HA"].Northing.>=minimum(n)),
            findall(project.dat["HA"].Northing.<=maximum(n)),
        )

        interior_bool = [RayTrace(project,itarget,m,c,e) for itarget in iTarget]

        interior_pts = iTarget[interior_bool]

        project.dat["HA"].osgb[interior_pts] .= project.dat["gml"][k].summary.osgb[j]
    end

    return project
end
