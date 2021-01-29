function link_epcdata(env,project,activeTiles)

    # Link EPC data
    DataSource = "EPC"
    selected_cols = [:OSG_UPRN,:Dwelling_Type,:Property_Type,:Historical,
        :Total_floor_area_m2_,:Prop_Summ_Total_Floor_Area,:Top_Storey,
        :Habitable_Room_Count,:Heated_Room_Count,
        :Wall_Summary,:Roof_Summary,:Floor_Summary,:Window_Summary,
        :Main_Heating_Summary,:Main_Heating_Controls_Summary,:Secondary_Heating_Summary,
        :Hot_Water_Summary,:Lighting_Summary,:Air_Tightness_Summary,
        :Part_1_Construction_Age_Band,:Multiple_Glazing_Type,
        ]
    project = ExtractData(project,DataSource,activeTiles,selected_cols;method="uprn")

    # Remove historical records (for dwellings with more than one entry)
    project.dat["EPC"] = project.dat["EPC"][project.dat["EPC"].Historical.==false,:]
    epcdata = project.dat["EPC"]

    # Find indices in EPC register that correspond to target UPRNs
    link_uprns(uprns,uprn) = findfirst(uprns.==uprn)
    function avoidmissings(vec)
        vec1 = fill!(Array{Int64}(undef,length(vec)),0)
        i_nonmissing = ismissing.(vec).==false
        vec1[i_nonmissing] .= vec[i_nonmissing]
        return vec1
    end
    epc_uprns = avoidmissings(project.dat["EPC"].OSG_UPRN)
    i_linked_uprns = link_uprns.((epc_uprns,),project.dat["master"].UPRN)

    # Find indices (in master data) which have an EPC
    i_epc = findall(isnothing.(i_linked_uprns).==false)

    # Add 'EPC_' suffix to all EPC column headings, except UPRN (i=1)
    colnames = names(project.dat["EPC"])
    suffix(str) = "EPC_$str"
    newcolnames = suffix.(colnames)

    # Create new EPC cols to append master stock data
    L = length(i_linked_uprns)
    function newcol(project,i_linked_uprns,i_epc,L,colname,newcolname)
        df = DataFrame(Symbol(newcolname) => fill!(Array{Union{Missing,Any}}(undef,L),missing))
        df[!,Symbol(newcolname)][i_epc] .= project.dat["EPC"][!,colname][i_linked_uprns[i_epc]]
        return df
    end
    newcols = newcol.((project,),(i_linked_uprns,),(i_epc,),(L,),colnames,newcolnames)
    newcols = hcat(newcols...)

    # Combine master and EPC data
    project.dat["master"] = hcat(project.dat["master"],newcols)

    # Area ratio, between EPC data and OS-evaluated. 1.0 assumed where EPC missing
    arearatio = project.dat["master"].EPC_Total_floor_area_m2_./project.dat["master"].OS_area_eval
    project.dat["master"][!,:arearatio] = ones(nrow(project.dat["master"]))
    project.dat["master"].arearatio[ismissing.(arearatio).==false] = arearatio[ismissing.(arearatio).==false]

    return project
end
