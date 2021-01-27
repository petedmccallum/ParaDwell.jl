function linkbuildingheights(env,project,activetiles)
    # Find active tile data paths
    activetilespaths(pth,tileReg,tile) = joinpath(pth,tileReg.tileRefDirs[tileReg.tileRefs.==tile][1])
    tilepaths = activetilespaths.((string(env.paths[:OS]),),(project.tileRegister,),activetiles)


    function loadbha(tilepath,tile)
        # Identify subdir
        dirs = readdir(tilepath)
        dir = dirs[occursin.("building_heights",dirs)][1]
        # Identify lower subdir
        pth = joinpath(tilepath,dir,lowercase(tile[1:2]))
        fname = readdir(pth)
        # Identify full path
        fullpath = joinpath(pth,fname[1])
        # Load
        bha = CSV.read(fullpath,header=false,DataFrame)
    end
    bha = loadbha.(tilepaths,activetiles)
    bha = vcat(bha...)

    # Parse OSGB as int
    parsereplace(str,str_rm,T) = parse(T,replace(str,str_rm=>""))
    bha[!,:osgb] = parsereplace.(bha.Column1,"osgb",Int64)
    # Find indices in BHA data, for all master data (based on OSGB)
    findfirst_arr(arr,val) = findfirst(arr.==val)
    i = findfirst_arr.((bha.osgb,),project.dat["master"].osgb)

    # For non-missing entries in master stock data, fill BHA data
    i_linked = findall(isnothing.(i).==false)
    L = nrow(project.dat["master"])
    project.dat["master"][!,:AbsHMin] = fill!(Array{Union{Missing,Float32}}(undef,L),missing)
    project.dat["master"][!,:AbsH2] = fill!(Array{Union{Missing,Float32}}(undef,L),missing)
    project.dat["master"][!,:AbsHMax] = fill!(Array{Union{Missing,Float32}}(undef,L),missing)
    project.dat["master"][!,:RelH2] = fill!(Array{Union{Missing,Float32}}(undef,L),missing)
    project.dat["master"][!,:RelHMax] = fill!(Array{Union{Missing,Float32}}(undef,L),missing)

    project.dat["master"].AbsHMin[i_linked] .= bha.Column5[i[i_linked]]
    project.dat["master"].AbsH2[i_linked] .= bha.Column6[i[i_linked]]
    project.dat["master"].AbsHMax[i_linked] .= bha.Column7[i[i_linked]]
    project.dat["master"].RelH2[i_linked] .= bha.Column8[i[i_linked]]
    project.dat["master"].RelHMax[i_linked] .= bha.Column9[i[i_linked]]

    return project
end
