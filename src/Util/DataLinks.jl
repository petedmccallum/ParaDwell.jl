
function InitFileLinks()
    dir = readdir(env.paths[:projects])

    dir = dir[isdir.(dir)]

    if sum(dir.==".DataFileLinks") == 0
        mkdir(".DataFileLinks")
    end
end
InitFileLinks()

function DataFileName(DataSource)
    io = open(joinpath(env.paths[:projects],".DataFileLinks","$DataSource.txt"),"r")
    content = readlines(io)
    close(io)
    paths = Dict()
    [push!(paths, split(cont," => ")[1] => split(cont," => ")[2]) for cont in content]
    return paths
end
