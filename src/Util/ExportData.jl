function exportstockdata(project)
    stockdata = project.dat["master"]
    timestamp = replace(split(string(now()),".")[1],":"=>"")
    CSV.write("StockExtract_$(timestamp).csv",stockdata)

    sum(ismissing.(stockdata[:,4]))
    prep_df(stockdata,col) = stockdata[findall(isnothing.(stockdata[:,col])),col] .= missing
    prep_df.((stockdata,),collect(4:24))
end
