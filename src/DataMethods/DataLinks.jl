#-------------------------------------------------------------------------------
function ExtractData(project,DataSource,activeTiles,selected_cols,gridRefLimits)

	# Find file names (from "<ProjectDir>/.DataFileLinks/<DataSource>.txt")
	fnames = DataFileName(DataSource)
	fnames = unique([fnames[tile] for tile in activeTiles])

	# Extract csv data for all returned files, linked to active tiles
	tmp = [CSV.read(
		joinpath(env.paths[:data_sensitive],string(fname)),
		DataFrame, normalizenames=true)
	for fname in fnames]

	# Merge all returned dataframes
	tmp = vcat(tmp...)

	# Trim data to grid reference limits
	iKeep = intersect(
		findall(tmp.Easting  .>= gridRefLimits["easting_min"]),
		findall(tmp.Easting  .<  gridRefLimits["easting_max"]),
		findall(tmp.Northing .>= gridRefLimits["northing_min"]),
		findall(tmp.Northing .<  gridRefLimits["northing_max"])
	)

	# Push to project struct (selected cols only)
	push!(project.dat,DataSource=>tmp[iKeep,selected_cols])

	return project
end

#-------------------------------------------------------------------------------
"""
`addFields` should be a dictionary, with keys named as target dataframe columns
from GML, values as a Tuple of lenght 2: first value DataType, second value
default placeholders (for `fill!(Array{}...)`).

Example:

```
addFields = Dict(
    "eastings"=>(Float64,[]),
    "northings"=>(Float64,[]),
)
```
"""
function AddFields(project,addFields)
    fields = string.(keys(addFields))

    for i in 1:length(fields)
        # Template array
        tmp = fill!(Array{
            addFields[fields[i]][1]
        }(undef,size(project.dat["master"],1)),
            addFields[fields[i]][2]
        )

        for k in 1:length(project.dat["gml"])
            # Find data rows in master dataframe, relating to current tile
            iTile = project.dat["master"].osgb_tile .== project.dat["gml"][k].tile
            # Find corresponding entries in GML
            iGml = project.dat["master"].iGml[iTile]

            tmp[iTile] .= [arr[1] for arr in project.dat["gml"][k].summary[!,fields[i]][iGml]]
        end

        project.dat["master"][!,"$(fields[i])_GML"] = tmp
    end
end

#-------------------------------------------------------------------------------
function LinkHaData(env,project)
	# Find eastings/northings ranges
	activeTiles = [tile.tile for tile in project.dat["gml"]]
	iActiveTiles = vcat([findall(project.tileRegister.tileRefs.==activeTile) for activeTile in activeTiles]...)

	# Find grid reference limits
	gridRefLimits = Dict(
		"easting_min" => minimum(project.tileRegister.eastings_min[iActiveTiles]),
		"easting_max" => maximum(project.tileRegister.eastings_max[iActiveTiles]),
		"northing_min" => minimum(project.tileRegister.northings_min[iActiveTiles]),
		"northing_max" => maximum(project.tileRegister.northings_max[iActiveTiles]))

	# Link HA data
	DataSource = "HA"
	selected_cols = [:UPRN,:Easting,:Northing,:Full_postal_address]
	project = ExtractData(project,DataSource,activeTiles,selected_cols,gridRefLimits)

	# Create new master dataframe from HA data
	push!(project.dat,"master"=>deepcopy(project.dat["HA"]))
	rename!(project.dat["master"],:Easting=>:Easting_HA)
	rename!(project.dat["master"],:Northing=>:Northing_HA)

	# Geo-reference master data against GIS data
	project.dat["master"][!,"osgb_tile"] = fill!(Array{String}(undef,size(project.dat["master"],1)),"")
	project.dat["master"][!,"iGml"] = fill!(Array{Int64}(undef,size(project.dat["master"],1)),0)
	project.dat["master"][!,"osgb"] = fill!(Array{Int64}(undef,size(project.dat["master"],1)),0)
	[GeoRef(project,k) for k in 1:length(project.dat["gml"])]

	# Introduce other HA data fields (Tuple of (DataType,<placeholder value>))
	addFields = Dict(
	    "eastings"=>(Array{Float64},[]),
	    "northings"=>(Array{Float64},[]),
	)
	AddFields(project,addFields)

	# Remove rows with no osgb (unsuccessful geo-ref)
	delete!(project.dat["master"],ismissing.(project.dat["master"].osgb))

	addtraces!(ui.p0,
	    scatter(
	        x=project.dat["master"].Easting_HA[ismissing.(project.dat["master"].osgb).==false],
	        y=project.dat["master"].Northing_HA[ismissing.(project.dat["master"].osgb).==false],
	        mode="markers",
	        marker=attr(color="#16a085dd",size=4),
	        name="master",
	        text=project.dat["master"].Full_postal_address[ismissing.(project.dat["master"].osgb).==false]
	    )
	)
	addtraces!(ui.p0,
	    scatter(
	        x=project.dat["master"].Easting_HA[ismissing.(project.dat["master"].osgb).==true],
	        y=project.dat["master"].Northing_HA[ismissing.(project.dat["master"].osgb).==true],
	        mode="markers",
	        marker=attr(color="#dd2222dd",size=4),
	        name="HA (no link)"
	    )
	)

	return project
end
