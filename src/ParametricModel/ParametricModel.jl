# Main archetype function
function buildarchetypes(project)
    d = project.dat["master"]

    L = length.(d.dims)
    vertexcount(L,i) = findall(L.==i)
    ishapes = Dict()
    push!(ishapes,"4vert"=>vertexcount(L,4))
    push!(ishapes,"6vert"=>vertexcount(L,6))
    push!(ishapes,"8vert"=>vertexcount(L,8))

    L = nrow(d)
    d[!,:width] = fill!(Array{Union{Missing,Float64}}(undef,L),missing)
    d[!,:depth] = fill!(Array{Union{Missing,Float64}}(undef,L),missing)
    d[!,:tol] = fill!(Array{Union{Missing,Float64}}(undef,L),missing)
    d[!,:tor] = fill!(Array{Union{Missing,Float64}}(undef,L),missing)
    d[!,:tp] = fill!(Array{Union{Missing,Float64}}(undef,L),missing)
    d[!,:bc1] = fill!(Array{Union{Missing,Float64}}(undef,L),missing)

    d = assess4vertplans(d,ishapes["4vert"])
    return project
end

# 4 vertex dwellings
function assess4vertplans(stockdata,ishapes)
    elevpair(verts) = [round(mean(verts[[1,3]]),digits=3),round(mean(verts[[2,4]]),digits=3)]
    plans_dims = elevpair.(stockdata.dims[ishapes])

    adiab_odd(verts) = sum(iseven.(findall(verts.==true)))<sum(isodd.(findall(verts.==true)))
    adiab_even(verts) = sum(iseven.(findall(verts.==true)))>sum(isodd.(findall(verts.==true)))

    plans = DataFrame(
        :width => maximum.(plans_dims),
        :depth => minimum.(plans_dims)
    )
    dim_i(dims,i) = dims[i]
    i_even = findall(adiab_even.(stockdata.adiabBool[ishapes]))
    i_odd = findall(adiab_odd.(stockdata.adiabBool[ishapes]))
    plans.width[i_even] .= dim_i.(plans_dims[i_even],1)
    plans.width[i_odd] .= dim_i.(plans_dims[i_odd],2)
    plans.depth[i_even] .= dim_i.(plans_dims[i_even],2)
    plans.depth[i_odd] .= dim_i.(plans_dims[i_odd],1)

    stockdata.width[ishapes] .= plans.width
    stockdata.depth[ishapes] .= plans.depth
    stockdata.tol[ishapes] .= 0.
    stockdata.tor[ishapes] .= 0.
    stockdata.tp[ishapes] .= 0.
    return stockdata
end
