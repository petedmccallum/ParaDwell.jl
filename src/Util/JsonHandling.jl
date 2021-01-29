function writeJSON(json_string,directory,tileRef)
    open("$(directory)/$(tileRef).json","w") do f
        write(f,json_string)
    end
end
function readJSON(directory,tileRef)
    io = open("$(directory)/$(tileRef).json")
    content = readlines(io)
    close(io)
    data_dict = JSON.parse(content[1])
    data = DataFrame(data_dict)
    # As 'Missing's come back as 'Nothing's from JSON, this is corrected below
    prep_df(data,col) = data[findall(isnothing.(data[:,col])),col] .= missing
    prep_df.((data,),collect(1:ncol(data)))
    return data
end
