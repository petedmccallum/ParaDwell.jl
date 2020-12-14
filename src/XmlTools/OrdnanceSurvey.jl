function BHAdata(pth_gml::String)
    pth_tile = split(pth_gml,"mastermap-topo")[1]

    dir = readdir(pth_tile)
    pth_bha = joinpath(pth_tile,dir[occursin.("building_heights",dir)][1])
    dir = readdir(pth_bha)

    iDocs = findall(dir.=="docs")[1]
    iBha = intersect(findall(dir.!="docs"),findall(occursin.(".pdf",dir).==false))[1]
    pth_bha_docs = joinpath(pth_bha,dir[iDocs])
    pth_bha = joinpath(pth_bha,dir[iBha])

    fname = readdir(pth_bha)[1]

    df_headers = DataFrame(load(joinpath(pth_bha_docs,"BHA_Header.csv"),header_exists=false))
    df = DataFrame(load(joinpath(pth_bha,fname),header_exists=false))

    colnames = [Symbol(str) for str in df_headers[1,:]]

    rename!(df,colnames)

    df.OS_TOPO_TOID = parse.(Int64,replace.(df.OS_TOPO_TOID,"osgb"=>""))

    return df
end


function ExtractFeatures(features,children,tag::String;T::Type=String)
    # Init
    lTag = length(tag)+1
    # Find feature
    tagContents = [features[i][children[i].==tag] for i in 1:length(features)]
    # Remove tags
    tagContents = map(tagContent->map(tc->tc[lTag:(end-lTag)],tagContent),tagContents)
    # Change type if specified
    if T!=String
        tagContents = map(tc->parse.(T,tc),tagContents)
    end
    # Convert to Vector if single valued results throughout
    if length(tagContents) == sum(length.(tagContents))
        tagContents = vcat(tagContents...)
    end
    return tagContents
end
