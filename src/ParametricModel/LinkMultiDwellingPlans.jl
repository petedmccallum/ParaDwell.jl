function multidwellplans(stockdata)
    # Find other dwellings within same footprint
    undersameroof(uprns,osgbs,osgb) = uprns[findall(osgbs.==osgb)]
    uprns_undersameroof = undersameroof.((stockdata.UPRN,),(stockdata.osgb,),stockdata.osgb)

    # Find multi-dwelling buildings only
    i_flats = findall(length.(uprns_undersameroof).>1)

    # Create unique_id from combinations of all UPRNs (including self ref)
    unique_id = join.(uprns_undersameroof[i_flats],"+")

    # Create a template missing/string array
    uprns_undersameroof = fill!(Array{String}(undef,nrow(stockdata)),"")
    uprns_undersameroof[i_flats] .= unique_id
    return uprns_undersameroof
end
