function OS_TileSummries(env)
    # Check contents of Ordnance Survey directory
    dirContents = readdir(env.paths[:OS])

    # Retain subdirs only
    checkA = isdir.(joinpath.(env.paths[:OS],dirContents))
    dirContents = dirContents[checkA]

    # Only retain names split by one "_" char
    dirContents = split.(dirContents,"_")
    dirContents = dirContents[length.(dirContents).==2]

    # Extract OS tile refs
    tileRefs = [dirContent[1] for dirContent in dirContents]

    # Check for subfolders that match the OS tile name format (e.g. "HY41SW_1527338") -> "$$##$$_#######"
    checkB = [length(tileRef) for tileRef in tileRefs]
    checkC = [
        sum(isnothing.(
            [tryparse(Int8,string(char)) for char in tileRef[[1,2,5,6]]]
        )) for tileRef in tileRefs]
    checkD = isa.([tryparse(Int32,tileRef[[3,4]]) for tileRef in tileRefs],Int32)

    iChecked = intersect(
        findall(checkB.==6), # Check tile ref has 6 chars in total
        findall(checkC.==4), # Check tile ref has letters as the 1st,2nd,5th and 6th chars
        findall(checkD.==1)  # Check tile ref has numbers as the 3rd and 4th chars
    )


    tileRegister_orig = CSV.read(joinpath(env.paths[:projects],".OS_TileRegister.csv")) |> DataFrame
    newTiles = setdiff(tileRefs[iChecked],tileRegister_orig.tileRefs)
    if !isempty(newTiles)
        iChecked = iChecked[findall(tileRefs[iChecked].==newTiles)]

        tileRegister_new = DataFrame(
            :tileRefDirs => join.(dirContents[iChecked],"_"),
            :tileRefs => tileRefs[iChecked],
            :eastings_max => fill!(Array{Float32}(undef,length(iChecked)),-999.),
            :northings_max => fill!(Array{Float32}(undef,length(iChecked)),-999.),
            :eastings_min => fill!(Array{Float32}(undef,length(iChecked)),-999.),
            :northings_min => fill!(Array{Float32}(undef,length(iChecked)),-999.),
            :northings_mid => fill!(Array{Float32}(undef,length(iChecked)),-999.),
            :eastings_mid => fill!(Array{Float32}(undef,length(iChecked)),-999.),
            :Lat_mid => fill!(Array{Float32}(undef,length(iChecked)),-999.),
            :Lon_mid => fill!(Array{Float32}(undef,length(iChecked)),-999.)
        )

        [tileRegister_new[row,[:eastings_max,:northings_max,:eastings_min,:northings_min,:northings_mid,:eastings_mid]] = MidGridRefs(env,tileRegister_new.tileRefs[row])
            for row in 1:length(iChecked)]

        [tileRegister_new[row,[:Lat_mid,:Lon_mid]] = OSENtoLLA(tileRegister_new.eastings_mid[row],tileRegister_new.northings_mid[row])
            for row in 1:length(iChecked)]

        tileRegister = vcat(tileRegister_orig,tileRegister_new)

        CSV.write(joinpath(env.paths[:projects],".OS_TileRegister.csv"),tileRegister)
    end
end

function MidGridRefs(env,tile)
    gml = ProcessGMLs(env.paths[:OS],tile)

    eastings_mid = floor(mean(vcat(vcat(gml.summary.eastings...)...))/5000)*5000 + 2500
    northings_mid = floor(mean(vcat(vcat(gml.summary.northings...)...))/5000)*5000 + 2500

    eastings_min = eastings_mid - 2500
    northings_min = northings_mid - 2500

    eastings_max = eastings_mid + 2500
    northings_max = northings_mid + 2500

    return eastings_max,northings_max,eastings_min,northings_min,northings_mid,eastings_mid
end
