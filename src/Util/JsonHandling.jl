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
end
