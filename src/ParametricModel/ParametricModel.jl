# Main archetype function
function buildarchetypes(project)
    stockdata = project.dat["master"]

    # Identify different plan shapes, based on vertex count
    L = length.(stockdata.dims)
    vertexcount(L,i) = findall(L.==i)
    ishapes = Dict()
    push!(ishapes,"4vert"=>vertexcount(L,4))
    push!(ishapes,"6vert"=>vertexcount(L,6))
    push!(ishapes,"8vert"=>vertexcount(L,8))

    # Prepare new columns for archetype fields
    L = nrow(stockdata)
    stockdata[!,:width] = fill!(Array{Union{Missing,Float64}}(undef,L),missing)
    stockdata[!,:depth] = fill!(Array{Union{Missing,Float64}}(undef,L),missing)
    stockdata[!,:tol] = fill!(Array{Union{Missing,Float64}}(undef,L),missing)
    stockdata[!,:tor] = fill!(Array{Union{Missing,Float64}}(undef,L),missing)
    stockdata[!,:tp] = fill!(Array{Union{Missing,Float64}}(undef,L),missing)
    stockdata[!,:bc1] = fill!(Array{Union{Missing,String}}(undef,L),missing)

    stockdata = assess4vertplans(stockdata,ishapes["4vert"])
    return project
end

# 4 vertex dwellings
function assess4vertplans(stockdata,ishape)
    elevpair(verts) = [round(mean(verts[[1,3]]),digits=3),round(mean(verts[[2,4]]),digits=3)]
    plans_dims = elevpair.(stockdata.dims[ishape])

    plans = DataFrame(
        :width => maximum.(plans_dims),
        :depth => minimum.(plans_dims)
    )

    adiab_odd(verts) = sum(iseven.(findall(verts.==true)))<sum(isodd.(findall(verts.==true)))
    adiab_even(verts) = sum(iseven.(findall(verts.==true)))>sum(isodd.(findall(verts.==true)))

    i_even = findall(adiab_even.(stockdata.adiabBool[ishape]))
    i_odd = findall(adiab_odd.(stockdata.adiabBool[ishape]))

    dim_i(dims,i) = dims[i]
    plans.width[i_even] .= dim_i.(plans_dims[i_even],1)
    plans.width[i_odd] .= dim_i.(plans_dims[i_odd],2)
    plans.depth[i_even] .= dim_i.(plans_dims[i_even],2)
    plans.depth[i_odd] .= dim_i.(plans_dims[i_odd],1)

    stockdata.width[ishape] .= plans.width
    stockdata.depth[ishape] .= plans.depth
    stockdata.tol[ishape] .= 0.
    stockdata.tor[ishape] .= 0.
    stockdata.tp[ishape] .= 0.

    function findadjacencies(adiab_array)
        i_all = findall(adiab_array)
        adjacencies = missing
        if isempty(i_all)
            adjacencies = "EEEE"
        elseif length(i_all) == 1
            adjacencies = "EEEA"
        elseif length(i_all) == 2
            if diff(i_all) == [2]
                adjacencies = "EEAA"
            else
                adjacencies = "EAEA"
            end
        elseif length(i_all) == 3
            adjacencies = "EAAA"
        end
        return adjacencies
    end
    stockdata.bc1[ishape] = findadjacencies.(stockdata.adiabBool[ishape])

    return stockdata
end

function abovebelowadj(stockdata)
    # Prep array
    stockdata[!,:bc2] = fill!(Array{Union{Missing,String}}(undef,nrow(stockdata)),missing)
    # Apply External (E) roof and Ground (G) adjacencies to all single-UPRN footprints
    # ... THIS OVERLOOKS FLATS ABOVE NON-RES,BUT THESE ARE PICKED UP BELOW
    stockdata.bc2[stockdata.nUPRNs_undersameroof.==1] .= "EG"


    findall_arr(val,arr) = findall(arr.==val)
    i_1to4UPRN = vcat(findall_arr.((stockdata.nUPRNs_undersameroof,),1:4)...)
    i_nonmissing = findall(ismissing.(stockdata.EPC_Dwelling_Type).==false)
    findoccursin_arr(val,arr) = i_nonmissing[findall(occursin.(val,arr))]
    j = findoccursin_arr.(("ground-floor ","mid-floor ","top-floor ","basement "),(lowercase.(stockdata.EPC_Dwelling_Type[i_nonmissing]),))
    stockdata.bc2[intersect(i_1to4UPRN,j[1])] .= "AG"
    stockdata.bc2[intersect(i_1to4UPRN,j[2])] .= "AA"
    stockdata.bc2[intersect(i_1to4UPRN,j[3])] .= "EA"
    stockdata.bc2[intersect(i_1to4UPRN,j[4])] .= "AG"
    return stockdata
end

function gen_archcode(stockdata,tol_geom)
    # Find intersecting non-missing rows (all data present in geom cols)
    ismissing_col(data,col) = findall(ismissing.(data[:,col]).==false)
    i_nonmisisngs = intersect(vcat(
        intersect(ismissing_col.((stockdata,),[:width,:depth,:tol,:tor,:tp]))...),
        intersect(vcat(ismissing_col.((stockdata,),[:RelH2,:RelHMax]))
    ...))
    stockdata_exrp = deepcopy(stockdata[i_nonmisisngs,:])

    # Apply archetyping geometry tolerence (arg, in metres)
    apply_geomtol(arr,tol,factor) = lpad(string(Int(factor*round(arr./tol).*tol)),3,"0")
    w = apply_geomtol.(stockdata_exrp.width,tol_geom,10)
    d = apply_geomtol.(stockdata_exrp.depth,tol_geom,10)
    tol = apply_geomtol.(stockdata_exrp.tol,tol_geom,10)
    tor = apply_geomtol.(stockdata_exrp.tor,tol_geom,10)
    tp = apply_geomtol.(stockdata_exrp.tp,tol_geom,10)
    he = apply_geomtol.(stockdata_exrp.RelH2,tol_geom/2,100)
    ha = apply_geomtol.(stockdata_exrp.RelHMax,tol_geom/2,100)

    # Compile archetypes
    compilearchetype(w,d,tol,tor,tp,he,ha,bc1,bc2) =
        "w$w-d$d-tol$tol-tor$tor-tp$tp-he$he-ha$ha-adj$bc1$bc2"
    archcode = compilearchetype.(w,d,tol,tor,tp,he,ha,
        stockdata_exrp.bc1,stockdata_exrp.bc2)

    return archcode
end
