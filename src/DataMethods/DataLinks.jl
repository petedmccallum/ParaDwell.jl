function LiesWithin(project,activeTile,e,n)
    iActiveTile = findall(project.tileRegister.tileRefs.==activeTile)
    gridRefLimits = Dict(
        "easting_min" => minimum(project.tileRegister.eastings_min[iActiveTile]),
        "easting_max" => maximum(project.tileRegister.eastings_max[iActiveTile]),
        "northing_min" => minimum(project.tileRegister.northings_min[iActiveTile]),
        "northing_max" => maximum(project.tileRegister.northings_max[iActiveTile]))
    iKeep = intersect(
        findall(e .>= gridRefLimits["easting_min"]),
        findall(e .<  gridRefLimits["easting_max"]),
        findall(n .>= gridRefLimits["northing_min"]),
        findall(n .<  gridRefLimits["northing_max"])
    )
end


#-------------------------------------------------------------------------------
function ExtractData(project,DataSource,activeTiles,selected_cols;method="gridref")

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

	# Find points within active tiles
	if method == "gridref"
		iKeep = sort(vcat(LiesWithin.((project,),activeTiles,(tmp.Easting,),(tmp.Northing,))...))
	elseif method == "uprn"
		iKeep = 1:nrow(tmp)
	end

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
        }(undef,nrow(project.dat["master"])),
            addFields[fields[i]][2]
        )

        for k in 1:length(project.dat["gml"])
            # Find data rows in master dataframe, relating to current tile
            iTile = intersect(
				findall(project.dat["master"].osgb_tile .== project.dat["gml"][k].tile),
				findall(project.dat["master"].iGml.!=0)
			)
            # Find corresponding entries in GML
            iGml = project.dat["master"].iGml[iTile]

			coldata = project.dat["gml"][k].summary[!,fields[i]][iGml]
            if fields[i] == "eastings" || fields[i] == "northings"
				arraypos1(coldata) = coldata[1]
				coldata = arraypos1.(coldata)
			end
			tmp[iTile] .= coldata
        end

        project.dat["master"][!,"$(fields[i])_GML"] = tmp
    end
end

#-------------------------------------------------------------------------------
function LoadStockData(env,project)
	# Send compiled stock data to JSON (by tile)
	function WriteStockJSON(project,tile)
		data_byTile = project.dat["master"][project.dat["master"].osgb_tile.==tile,:]
		json_string = JSON.json(data_byTile)

		writeJSON(json_string,"BuildingStock",tile)
	end

	# List active tiles
	activeTiles = [tile.tile for tile in project.dat["gml"]]

	# List saved stock JSONs
	BuildingStockDir = readdir(joinpath(env.paths[:projects],"BuildingStock"))

	# Find relevant saved JSONs
	ExistingTileJSONs(activeTile,BuildingStockDir) = sum(occursin.(activeTile,BuildingStockDir))>0
	iKeep = findall(vcat(ExistingTileJSONs.(activeTiles,(BuildingStockDir,))...))

	# Restore existing JSONs (if any JSON are found)
	stockData = []
	if !isempty(iKeep)
		# Try/catch rejects the saved JSONs when multiple tiles are used AND the
		# ... DataFrame columns don't match. Rebuild carried out at next step
		try
			push!(stockData,vcat(readJSON.("BuildingStock",activeTiles[iKeep])...))
		catch
			iKeep = []
		end
	end

	# Evaluate new stock data, where existing JSONs are not found/don't match
	if length(iKeep)!=length(activeTiles)
		project = LinkHaData(env,project,activeTiles[Not(iKeep)])
		project = link_epcdata(env,project,activeTiles[Not(iKeep)])
		push!(stockData,project.dat["master"])
		WriteStockJSON.((project,),activeTiles[Not(iKeep)])
	end

	# Check that column names match, rerun if necessary, then merge all stock data
	if length(stockData).==2
		MatchingDfCols(col₁,cols₂) = sum(cols₂.==col₁)
		cols = sort.(names.(stockData))
		if sum(MatchingDfCols.(cols[1],(cols[2],)))!=length(cols[1])
			project = LinkHaData(env,project,activeTiles[iKeep])
			project = link_epcdata(env,project,activeTiles[iKeep])
			stockData[1] = deepcopy(project.dat["master"])
			project.dat["master"] = vcat(stockData...)
			WriteStockJSON.((project,),activeTiles[iKeep])
		end
	end

	project.dat["master"] = vcat(stockData...)


	return project
end

#-------------------------------------------------------------------------------
function LinkHaData(env,project,activeTiles)

	# Link HA data
	DataSource = "HA"
	selected_cols = [:UPRN,:Easting,:Northing,:Full_postal_address,
		:Building_block_ID,:Data_zone_code,:Data_zone,:Property_type,]
	project = ExtractData(project,DataSource,activeTiles,selected_cols;method="gridref")

	# Create new master dataframe from HA data
	push!(project.dat,"master"=>deepcopy(project.dat["HA"]))
	rename!(project.dat["master"],:Easting=>:Easting_HA)
	rename!(project.dat["master"],:Northing=>:Northing_HA)

	# Geo-reference master data against GIS data
	project.dat["master"][!,"osgb_tile"] = fill!(Array{String}(undef,size(project.dat["master"],1)),"")
	iTiles = LiesWithin.((project,),activeTiles,(project.dat["HA"].Easting,),(project.dat["HA"].Northing,))
	IMap(iTile,activeTile) = project.dat["master"].osgb_tile[iTile].=activeTile
	IMap.(iTiles,activeTiles)
	project.dat["master"][!,"iGml"] = fill!(Array{Int64}(undef,size(project.dat["master"],1)),0)
	project.dat["master"][!,"osgb"] = fill!(Array{Int64}(undef,size(project.dat["master"],1)),0)
	[GeoRef(project,k) for k in 1:length(project.dat["gml"])]

	# Introduce other HA data fields (Tuple of (DataType,<placeholder value>))
	addFields = Dict(
	    "eastings"=>(Array{Float64},[]),
	    "northings"=>(Array{Float64},[]),
	)
	AddFields(project,addFields)

	# Remove redunant vertices and scan for adjacencies
	project = ProcessGeom(project)

	# Find plans that have more than one UPRN under same roof, generate unique string of all UPRNs
	n_uprns_undersameroof, uprns_undersameroof = multidwellplans(project.dat["master"][:,[:UPRN,:osgb,:iGml]])
	project.dat["master"][!,:nUPRNs_undersameroof] = n_uprns_undersameroof
	project.dat["master"][!,:UPRNs_undersameroof] = uprns_undersameroof

	return project
end
