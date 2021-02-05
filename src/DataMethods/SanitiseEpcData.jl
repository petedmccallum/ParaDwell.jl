
function sanitise_epcs(project)
    stockdata = project.dat["master"]

    # Find street names
    parseaddr(str) = split(str,", ")
    findstreet(str_arr) = str_arr[1+minimum([findfirst(length.(str_arr)[2:end].>3),length(str_arr)-3])]
    streetnames = findstreet.(parseaddr.(stockdata.Full_postal_address))
    streetlist = sort(unique(streetnames))

    # Find indices of all dwellings linked to each street in `streetlist`
    findall_arr(arr,val) = findall(arr.==val)
    i = findall_arr.((streetnames,),streetlist)

    # Util functions for propagating most common occurrences from `groupby`
    countoccur(arr,val) = sum(skipmissing(arr).==val)
    mostcommon_occur(arr,groupby) = length(arr)==sum(ismissing.(arr)) ? "tbc" : groupby[findmax(countoccur.((arr,),groupby))[2]]
    # Propagate based on most common occurrence on street
    propagate_mostcommon(newArr,refArr,groupby,i) = newArr[i].=mostcommon_occur(refArr[i],groupby)

    # Apply propagation method: Age bands
    stockdata[!,:ParaDwell_Age_Band] = fill!(Array{String}(undef,nrow(stockdata)),"")
    groupby = ["before 1919","1919-1929","1930-1949","1950-1964","1965-1975","1976-1983","1984-1991","1992-1998","1999-2002","2003-2007","2008 onwards"]
    propagate_mostcommon.((stockdata.ParaDwell_Age_Band,), (stockdata.EPC_Part_1_Construction_Age_Band,), (groupby,), i)

end

@time sanitise_epcs(project)
