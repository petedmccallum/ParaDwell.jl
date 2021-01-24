# Main archetype function
function buildarchetypes(project)
    stockdata = project.dat["master"]

    # Find plans that have more than one UPRN under same roof, generate unique string of all UPRNs
    stockdata[!,:UPRNs_undersameroof] = findflats(stockdata[:,[:UPRN,:osgb]])

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
    stockdata[!,:bc] = fill!(Array{Union{Missing,String}}(undef,L),missing)

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
            adjacencies = "EEEE??"
        elseif length(i_all) == 1
            adjacencies = "EEEA??"
        elseif length(i_all) == 2
            if diff(i_all) == [2]
                adjacencies = "EEAA??"
            else
                adjacencies = "EAEA??"
            end
        elseif length(i_all) == 3
            adjacencies = "EAAA??"
        end
        return adjacencies
    end
    stockdata.bc[ishape] = findadjacencies.(stockdata.adiabBool[ishape])

    return stockdata
end
