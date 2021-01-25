function multidwellplans(stockdata)
    # Find other dwellings within same footprint
    undersameroof(uprns,osgbs,osgb) = uprns[findall(osgbs.==osgb)]
    uprns_undersameroof = undersameroof.((stockdata.UPRN,),(stockdata.osgb,),stockdata.osgb) # <- WARNING: SLOW OPERATION

    # Find multi-dwelling buildings only
    n_uprns_undersameroof = length.(uprns_undersameroof)
    i_flats = findall(n_uprns_undersameroof.>1)

    # Create unique_id from combinations of all UPRNs (including self ref)
    unique_id = join.(uprns_undersameroof[i_flats],"+")

    # Create a template missing/string array
    uprns_undersameroof = fill!(Array{String}(undef,nrow(stockdata)),"")
    uprns_undersameroof[i_flats] .= unique_id
    return n_uprns_undersameroof, uprns_undersameroof
end
