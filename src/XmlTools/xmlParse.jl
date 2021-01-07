

function addsubdir(pth,str)
    subdirs = readdir(pth)
    iSubdir = findall(occursin.(str,subdirs))
    pth2 = joinpath.(pth,subdirs[iSubdir])
    return pth2
end

function FindGML(pth,tile,type)
    pth_gml = addsubdir(pth,tile)[1]
    pth_gml = addsubdir(pth_gml,type)[1]
    if type=="vml"
        dir = readdir(pth_gml)
        pth_gml = joinpath(pth_gml,dir[occursin.(".",dir).==false][1])
    end
    pth_gml = addsubdir(pth_gml,"gml")[1]
    return pth_gml
end

function LoadXML(pth_fname)
    io=open(pth_fname)
    gml = readlines(io)
    gml = strip.(gml)
    return gml
end

function ParseXML(gml,parseby)
    iStart = findall(occursin.("<$(parseby)>",gml))
    iEnd = findall(occursin.("</$(parseby)>",gml))
    iTag = [iStart[i]:iEnd[i] for i in 1:length(iStart)]
    tagContents = [gml[i] for i in iTag]

    return tagContents
end

function contentSummary(features,pth)
    children = [
        [split(split(child," ")[1],">")[1]*">"
        for child in feature] for feature in features]
    osgb = map(x->x[occursin.("fid=",x)][1],features)
    osgb = map(x->split.(x,"\"")[2],osgb)
    osgb = replace.(osgb,"osgb"=>"")
    osgb = parse.(Int64,osgb)

    coordStrings = ExtractFeatures(features,children,"<gml:coordinates>")

    # Extract eastings/northings (Float64 necessary here for coord accuracy,
    # Float32 introduced RayTracing errors. Could make eastings/northings with
    # reference to local tile for computations, Float32 for plotting. #CUDA)
    coordStrings = map(coordString->split.(coordString,r"[, ]"),coordStrings)
    eastings = map(featCoordSets->map(featCoordSet->parse.(Float64,featCoordSet[1:2:end]),featCoordSets),coordStrings)
    northings = map(featCoordSets->map(featCoordSet->parse.(Float64,featCoordSet[2:2:end]),featCoordSets),coordStrings)

    # Load Building Height Attribute data
    bha = BHAdata(pth)

    # Find indices in `gml` with `bha` data
    iGml = [findfirst(osgb.==bha_osgb) for bha_osgb in bha.OS_TOPO_TOID]

    # Remove 'nothing's
    bha = bha[isa.(iGml,Int64),:]
    iGml = iGml[isa.(iGml,Int64)]

    # Init Missing arrays
    global L = size(features,1)
    TileRef = fill!(Array{Union{Missing,String}}(undef,L),missing)
    for x = [:AbsHMin,:AbsH2,:AbsHMax,:RelH2,:RelHMax]
        @eval $x = fill!(Array{Union{Missing,Float64}}(undef,L),missing)
    end

    # Fill `bha` data
    TileRef[iGml] .= bha.TileRef
    AbsHMin[iGml] = bha.AbsHMin
    AbsH2[iGml] = bha.AbsH2
    AbsHMax[iGml] = bha.AbsHMax
    RelH2[iGml] = bha.RelH2
    RelHMax[iGml] = bha.RelHMax

    df = DataFrame(
        theme = ExtractFeatures(features,children,"<osgb:theme>"),
        osgb = osgb,
        descr = ExtractFeatures(features,children,"<osgb:descriptiveGroup>"),
        areaOS = ExtractFeatures(features,children,"<osgb:calculatedAreaValue>";T=Float64),
        alt = ExtractFeatures(features,children,"<osgb:physicalLevel>";T=Float64),
        logDate = ExtractFeatures(features,children,"<osgb:changeDate>"),
        logChng = ExtractFeatures(features,children,"<osgb:reasonForChange>"),
        eastings = eastings,
        northings = northings,
        TileRef = TileRef,
        AbsHMin = AbsHMin,
        AbsH2 = AbsH2,
        AbsHMax = AbsHMax,
        RelH2 = RelH2,
        RelHMax = RelHMax,
        children=children)

    return df
end

function ProcessGMLs(pth,tile;savepath::String="")

    pth_topo = FindGML(pth,tile,"topo")

    @time gml_topo = LoadXML(pth_topo)

    @time features_topo = ParseXML(gml_topo,"osgb:topographicMember")

    @time summary_topo = contentSummary(features_topo,pth_topo)

    gml=GML(
        tile,
        pth_topo,
        gml_topo,
        features_topo,
        summary_topo,
    )

    if savepath!=""
        CSV.write(joinpath(savepath,"OrdnanceSurvey_$(gml.tile).csv"),gml.summary) # CSV.jl preserves colums better that CSVFiles.jl, for change/date logs
    end

    return gml
end
