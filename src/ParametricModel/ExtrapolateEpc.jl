function fillblockconfig(stockdata,n)
    i = findall(stockdata.nUPRNs_undersameroof.==n)

    # Find UPRN groups for N-dwellings per footprint
    UPRN_groups = unique(stockdata.UPRNs_undersameroof[i,:])

    # Find arrays of indices representing each UPRN groups
    findall_arr(arr,val) = findall(arr.==val)
    j = findall_arr.((stockdata.UPRNs_undersameroof,),UPRN_groups)
    # Find dwelling types for each group (if available)
    index_arr(arr,j) = arr[j]
    all_dwellingtypes = index_arr.((stockdata.EPC_Dwelling_Type,),j)

    # Find if dwellings are either flats or missings
    isflat(dwlgtypes) = isempty(findall((occursin.("flat",skipmissing(dwlgtypes)).+occursin.("maisonette",skipmissing(dwlgtypes))).==false))
    simpleflats = DataFrame(:i_block => findall(isflat.(all_dwellingtypes)))

    # Check area tolerence
    simpleflats[!,:arearatio] = index_arr.((stockdata.arearatio,),j)[simpleflats.i_block]
    simpleflats[!,:EPC_area] = index_arr.((stockdata.EPC_Total_floor_area_m2_,),j)[simpleflats.i_block]
    # Keep flats with areas in tolerence
    function areatol(simpleflats)
        i_keep = intersect(
            findall(minimum.(simpleflats.arearatio) .> 0.5),
            findall(maximum.(simpleflats.arearatio) .< 1.2),
        )
        simpleflats = simpleflats[i_keep,:]
    end
    simpleflats = areatol(simpleflats)

    # Add EPC_Dwelling_Type
    simpleflats[!,:EPC_Dwelling_Type] = index_arr.((stockdata.EPC_Dwelling_Type,),j)[simpleflats.i_block]

    # Estimate Dwelling_Type where EPCs are missing
    function eval_dwellingtypes(block,n)
        # Prep block composition "Top" comes before "Ground" to ensure every block
        # ... has a roof (mid-floor can exist in 2-UPRN blocks, possible mixed-use)
        eval_blocktemplate(n) = vcat([["Top-floor ","Ground-floor "],repeat(["Mid-floor "],maximum([0,n-2]))]...)
        block_template = eval_blocktemplate(n)

        # Find any flats in block with missing EPC
        i_missing = findall(ismissing.(block))

        # Remove already occurring flat type(s) from template
        occursin_arr(val,arr) = occursin.(val,arr)
        if isempty(i_missing)
            block_template = []
        elseif !isempty(block[Not(i_missing)])
            i_rm = vcat(collect(1:sum(occursin.("Top-floor ",block[Not(i_missing)])).+0),
                collect(2:sum(occursin.("Ground-floor ",block[Not(i_missing)])).+1),
                collect(3:sum(occursin.("Mid-floor ",block[Not(i_missing)])).+2),
            )
            # `i_rm[findall(i_rm.<=n)]` necessary, as mid-floor can exist in 2-UPRN blocks
            block_template = block_template[Not(i_rm[findall(i_rm.<=n)])]
        end
        [block[i_missing[i]]="$(block_template[i])flat (ParaDwell:ASSUMED)" for i in 1:length(i_missing)]

        # Apply assumptions from block_template for missing dwelling types
        return block
    end
    assumed_dwellingtypes = eval_dwellingtypes.(simpleflats.EPC_Dwelling_Type,n)

    # Map back to master dataframe
    i_master = vcat(j[simpleflats.i_block]...)
    stockdata.EPC_Dwelling_Type[i_master] .= vcat(assumed_dwellingtypes...)
    return stockdata
end
