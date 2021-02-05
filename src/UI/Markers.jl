
function addmarkers(project;name,i=[],filt=Dict(),colour=:red,markers=:zzz,size=4,label="address")
    # List all existing traces
    tracenames(trace) = trace["name"]
    tracelist = tracenames.(ui.p0.plot.data)
    # Find if called trace exists - if so delete and return, otherwise plot
    i_found = findfirst(tracelist.==name)
    if !isnothing(i_found)
        deletetraces!(ui.p0,i_found)
    else
        if i==[]
            i=1:nrow(project.dat["master"])
        end
        if !isempty(filt)
            findvalue(col,val) = findall(ismissing.(col).==false)[skipmissing(col).==val]
            i = findvalue(project.dat["master"][!,filt["column"]],filt["value"])
        end
        if label=="address"
            labels = project.dat["master"].Full_postal_address[i]
        end

        addtraces!(ui.p0,
            scatter(
                x=project.dat["master"].Easting_HA[i],
                y=project.dat["master"].Northing_HA[i],
                mode="markers",
                marker=attr(color=colour,symbol=markers,size=size),
                line_width=0.1,
                name=name,
                text=labels
            )
        )
    end
end


addmarkers(project;
    name="all",
    colour=:black,
    size=2,
    markers=:O
)



name="before 1919";     addmarkers(project; name=name, filt=Dict("column"=>:EPC_Part_1_Construction_Age_Band,"value"=>name),  colour = "#1B1464",   size = 7)
name="1919-1929";       addmarkers(project; name=name, filt=Dict("column"=>:EPC_Part_1_Construction_Age_Band,"value"=>name),  colour = "#9980FA",   size = 7)
name="1930-1949";       addmarkers(project; name=name, filt=Dict("column"=>:EPC_Part_1_Construction_Age_Band,"value"=>name),  colour = "#C4E538",   size = 7)
name="1950-1964";       addmarkers(project; name=name, filt=Dict("column"=>:EPC_Part_1_Construction_Age_Band,"value"=>name),  colour = "#EE5A24",   size = 7)
name="1965-1975";       addmarkers(project; name=name, filt=Dict("column"=>:EPC_Part_1_Construction_Age_Band,"value"=>name),  colour = "#e1b12c",   size = 7)
name="1976-1983";       addmarkers(project; name=name, filt=Dict("column"=>:EPC_Part_1_Construction_Age_Band,"value"=>name),  colour = "#f78fb3",   size = 7)
name="1984-1991";       addmarkers(project; name=name, filt=Dict("column"=>:EPC_Part_1_Construction_Age_Band,"value"=>name),  colour = "#3dc1d3",   size = 7)
name="1992-1998";       addmarkers(project; name=name, filt=Dict("column"=>:EPC_Part_1_Construction_Age_Band,"value"=>name),  colour = "#5758BB",   size = 7)
name="1999-2002";       addmarkers(project; name=name, filt=Dict("column"=>:EPC_Part_1_Construction_Age_Band,"value"=>name),  colour = "#f19066",   size = 7)
name="2003-2007";       addmarkers(project; name=name, filt=Dict("column"=>:EPC_Part_1_Construction_Age_Band,"value"=>name),  colour = "#c44569",   size = 7)
name="2008 onwards";    addmarkers(project; name=name, filt=Dict("column"=>:EPC_Part_1_Construction_Age_Band,"value"=>name),  colour = "#fed330",   size = 7)
