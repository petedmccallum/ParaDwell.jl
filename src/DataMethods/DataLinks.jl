
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

	# Geo-reference HA data against GIS data
	project.dat["HA"][!,"osgb"] = fill!(Array{Union{Missing,Int64}}(undef,size(project.dat["HA"],1)),missing)
	[GeoRef(project,k) for k in 1:length(project.dat["gml"])]

	addtraces!(ui.p0,
	    scatter(
	        x=project.dat["HA"].Easting[ismissing.(project.dat["HA"].osgb).==false],
	        y=project.dat["HA"].Northing[ismissing.(project.dat["HA"].osgb).==false],
	        mode="markers",
	        marker=attr(color="#16a085dd",size=4),
	        name="HA",
	        text=project.dat["HA"].Full_postal_address[ismissing.(project.dat["HA"].osgb).==false]
	    )
	)
	addtraces!(ui.p0,
	    scatter(
	        x=project.dat["HA"].Easting[ismissing.(project.dat["HA"].osgb).==true],
	        y=project.dat["HA"].Northing[ismissing.(project.dat["HA"].osgb).==true],
	        mode="markers",
	        marker=attr(color="#dd2222dd",size=4),
	        name="HA (no link)"
	    )
	)

	return project
end
