"""
Used to plot macro geographic map as vector. From the free data source: https://www.diva-gis.org/data

kwarg "adminlevel" refers to the available shape files in the DIVA dataset:
    0... country outlines,
    1... regional (e.g. home nations in uk case),
    2... county
"""

function DIVA(;
    territory::String="GBR",
    exclShapeBelowLen::Int=200,
    adminLevel=0)

    # Paths
    env = loadPaths()
    subDir = "$(territory)_adm"
    shapeFile = "$(territory)_adm$(adminLevel).shp"
    path = joinpath(env.paths[:basemap_DIVA],subDir,shapeFile)

    # Load shapefile
    shapeSource = open(path, "r") do io
        read(io, Shapefile.Handle)
    end

    # Main loop
    traces = [adminLevelTraces(
        shapeSource.shapes[iShape],
        exclShapeBelowLen,
        territory)
    for iShape in 1:length(shapeSource.shapes)]

    # Merge trace vectors
    traces = vcat(traces...)

    # Layout scale ratio constrained based on midLat
    allLat = vcat([trace[:y] for trace in traces]...)
    midLat = (maximum(allLat)+minimum(allLat))/2
    latLonRatio = cos(midLat*π/180)
    layout = Layout(
        showlegend=false,
        xaxis=attr(zeroline=false,
            scaleanchor="y", scaleratio=latLonRatio),
        hovermode="closest"
    )

    # Plot (suppress in application with semi-colon)
    plt = plot(traces,layout);

    return plt
end

function adminLevelTraces(shapeObj,exclShapeBelowLen,territory)
    shape = GeoInterface.coordinates(shapeObj)

    # Remove shapes with boundaries shorter than exclShapeBelowLen::Int
    shape = [shp for shp in shape if length(shp[1]) > exclShapeBelowLen]

    # Set boundary name
    shapeNames = "$(territory) basemap"

    # Build traces of all polygons in shape (i.e. separate islands)
    coordsets = [hcat(shp[1]...) for shp in shape]
    traces = [scatter(
            x=coordset[1,:][:],
            y=coordset[2,:][:],
            name=shapeNames,mode="lines",line=attr(width=0.1,color="#444444BB"),
            fill="tonexty",fillcolor="#58B19F10",
            hoverinfo="skip",hovertemplate=nothing)
    for coordset in coordsets]

    return traces
end
