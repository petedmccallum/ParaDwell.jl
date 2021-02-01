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
