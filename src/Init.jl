## SET/LOAD PATHS ##############################################################
function loadPaths()
	checkdir = readdir(homedir())

    if sum(checkdir.==".paradwellconfig")==1
		io = open(joinpath(homedir(),".paradwellconfig"),"r")
		config = readlines(io)
    	close(io)
		paths = Dict()
		[push!(paths, Symbol(split(conf," => ")[1]) => split(conf," => ")[2]) for conf in config]
		cd(paths[:projects])
		env = Env(paths)
	else
		env = Env(Dict())
	end
	return env
end

function init()
    checkdir = readdir(homedir())

    if sum(checkdir.==".paradwellconfig")==0
        print("Select directory for user projects (create new folder if required): ")
        ui_response1 = readline()
        print("Select directory for basemap data (create new folder if required): ")
        ui_response2 = readline()
    	open(joinpath(homedir(),".paradwellconfig"),"w") do io
			write(io, "projects => " * ui_response1 * "\n")
			write(io, "basemap => " * ui_response2)
    	end

    	println()
    	println("These paths are saved at $(joinpath(pwd(),".paradwellconfig")), and can be changed in future if required.")
    	println("Ensure that the actual directories exist (this is not automatic).")
    	println()
    	println("A useful open source data resource for lightweight basemaps can be found here:\t https://www.diva-gis.org/gdata")
		println("If using this data, select \"Administration areas\" from the \"Subject\" dropdown menu.")
    	println("Move basemap downloads to your designated directory; remember to extract zip files.")
    	println()
	end



end

init()
