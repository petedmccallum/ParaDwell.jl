
function WidgetBlock(widgets;name::String="",title::String="",subtitle::String="",ddList::OrderedDict)
    push!(widgets["buttons"], name=> button(title,
        style=Dict(:color => "white",:backgroundColor => "#dddddd",:width => "220px",:height => "34px",:fontSize => "0.9em")))
    subtitle = HTML(string("<div style='font-size:14px'><em>$(subtitle)</em></div>"))
    push!(widgets["toggles"], name => toggle(""));
    push!(widgets["dropdowns"], name => dropdown(ddList));
    widgets["dropdowns"][name].scope.dom.props[:style] = Dict(:width => "170px",:height => "20px",:fontSize => "0.7em");
    widgets["toggles"][name].scope.dom.props[:style] = Dict(:height => "18px");
    if name == "Census"
        push!(widgets["toggles"], "$(name)_2" => toggle(""));
        toggle_2_text = HTML(string("<div style='font-size:12px'>OA Boundaries</div>"))
        widgets["toggles"]["$(name)_2"].scope.dom.props[:style] = Dict(:height => "18px",:fontSize=>"0.7em");
        toggles = vbox(vskip(2px),hbox(widgets["toggles"]["$(name)_2"],toggle_2_text),
                  hbox(vbox(vskip(2px),widgets["toggles"][name]),vbox(widgets["dropdowns"][name]
        )))
    elseif name == "OS"
        push!(widgets["toggles"], "$(name)_2" => toggle(""));
        push!(widgets["toggles"], "$(name)_3" => toggle(""));
        push!(widgets["toggles"], "$(name)_4" => toggle(""));
        toggle_2_text = HTML(string("<div style='font-size:12px'>Buildings</div>"))
        toggle_3_text = HTML(string("<div style='font-size:12px'>Roads/Paths</div>"))
        toggle_4_text = HTML(string("<div style='font-size:12px'>Natural Features</div>"))
        widgets["toggles"]["$(name)_2"].scope.dom.props[:style] = Dict(:height => "18px",:fontSize=>"0.7em");
        widgets["toggles"]["$(name)_3"].scope.dom.props[:style] = Dict(:height => "18px",:fontSize=>"0.7em");
        widgets["toggles"]["$(name)_4"].scope.dom.props[:style] = Dict(:height => "18px",:fontSize=>"0.7em");
        toggles = vbox(vskip(2px),
                hbox(widgets["toggles"]["$(name)_2"],toggle_2_text),
                hbox(widgets["toggles"]["$(name)_3"],toggle_3_text),
                hbox(widgets["toggles"]["$(name)_4"],toggle_4_text)
        )
    else
        toggles = hbox(vbox(vskip(2px),widgets["toggles"][name]),vbox(widgets["dropdowns"][name]))
    end

    push!(widgets["Blocks"], name =>
        CSSUtil.vbox(
            hbox(widgets["buttons"][name]),
            vskip(2px),
            subtitle,
            vskip(4px),
            toggles,
            vskip(20px),
        )
    )
    return widgets
end

function LaunchMainUI(env)

    ## TITLE PANE
    global ui = ParaDwell.UI();
    ui.title = HTML(string("<div style='font-family:consolas; font-size:32px; color:#006266'><U>ParaDwell</u></div>"));
    ui.titlePane = vbox(vskip(20px), hbox(hskip(20px),ui.title));


    ## BUILD WIDGETS
    widgets = Dict("buttons"=>Dict(),"toggles"=>Dict(),"dropdowns"=>Dict(),"Blocks"=>Dict())
    widgets = WidgetBlock(widgets;name="OS",title="Ordnance Survey",subtitle="",ddList=OrderedDict("(blank)" => "Value 0", "Pop. density" => "Value 1"))
    widgets = WidgetBlock(widgets;name="Census",title="Census 2011",subtitle="By Output Area",ddList=OrderedDict("(blank)             " => "Value 0", "Pop. density" => "Value 1"))
    widgets = WidgetBlock(widgets;name="HomeAnalytics",title="Home Analytics",subtitle="By Dwelling (all)",ddList=OrderedDict("(blank)" => "Value 0", "Pop. density" => "Value 1"))
    widgets = WidgetBlock(widgets;name="EPC",title="EPC",subtitle="By Dwelling (partial)",ddList=OrderedDict("(blank)" => "Value 0", "Pop. density" => "Value 1"))
    widgets = WidgetBlock(widgets;name="IMD",title="Deprivation Indicies",subtitle="By LSOA",ddList=OrderedDict("(blank)" => "Value 0", "Pop. density" => "Value 1"))
    widgets = WidgetBlock(widgets;name="Acorn",title="Acorn (CACI)",subtitle="By Dwelling",ddList=OrderedDict("(blank)" => "Value 0", "Pop. density" => "Value 1"))
    widgets = WidgetBlock(widgets;name="Census",title="Census 2011",subtitle="By Output Area",ddList=OrderedDict("(blank)" => "Value 0", "Pop. density" => "Value 1"))
    widgets = WidgetBlock(widgets;name="Archetypes",title="Archetypes",subtitle="By Dwelling",ddList=OrderedDict("(blank)" => "Value 0", "Pop. density" => "Value 1"))


    ## LAUNCH ELECTRON
    ui.subPanelLeft1 = CSSUtil.width(250px,
        vbox(
        widgets["Blocks"]["OS"],
        widgets["Blocks"]["Census"],
        widgets["Blocks"]["HomeAnalytics"],
        widgets["Blocks"]["EPC"],
        widgets["Blocks"]["Acorn"],
        widgets["Blocks"]["IMD"],
        vskip(10px),
        CSSUtil.hline(),
        vskip(10px),
        widgets["Blocks"]["Archetypes"],
        )
    );
    ui.panelLeft = vbox(CSSUtil.height(1000px,vbox(ui.titlePane,vskip(20px),CSSUtil.hline(), vskip(30px), hbox(hskip(20px), ui.subPanelLeft1))));


    ## CREATE WIDGETS FOR RHS PANEL
    global wgt = ParaDwell.Wgt(ParaDwell.Toggle(),ParaDwell.Dropdown(),ParaDwell.Radio(),ParaDwell.Button(),ParaDwell.Check(),ParaDwell.Spinbox());
    wgt.spinbox.dimensionalRounding = spinbox(1:1:5,value=2);
    wgt.spinbox.maxPlanDepth = spinbox(7:1:15,value=12);
    wgt.dropdown.orient = dropdown(["(ignore)", "nearest 180°", "nearest 90°", "nearest 45°", "nearest 22.5°"]);
    wgt.button.generateArch = button(HTML(string("<div style='font-size:14px'>Generate archetypes</div>")));
    # wgt.dropdown.selectArch = dropdown([])
    wgt.button.generateIdf = button(HTML(string("<div style='font-size:14px'>Generate EnergyPlus files (.idf)</div>")));


    ## FORMAT WIDGETS FOR RHS PANEL
    wgt.button.generateArch.scope.dom.props[:style] = Dict("height"=>36px, "width"=>260px);
    wgt.button.generateIdf.scope.dom.props[:style] = Dict("height"=>36px, "width"=>260px);
    wgt.spinbox.dimensionalRounding.scope.dom.props[:style] = Dict("width"=>60px);
    wgt.spinbox.maxPlanDepth.scope.dom.props[:style] = Dict("width"=>60px);
    wgt.dropdown.orient.scope.dom.props[:style] = Dict("width"=>140px);
    # wgt.dropdown.selectArch.scope.dom.props[:style] = Dict("width"=>260px);



    ui.panelRight = vbox(vskip(2em),
        HTML(string("<div style='font-size:20px'><u><b>Archetype constraints:</b></u></div>")),
        vskip(10px),
        hbox(CSSUtil.width(200px,hbox(vbox(vskip(8px),
        HTML(string("<div style='font-size:14px'>Round plan to nearest (m):</div>"))))),
        wgt.spinbox.dimensionalRounding),
        vskip(10px),
        hbox(CSSUtil.width(120px,hbox(vbox(vskip(8px),
        HTML(string("<div style='font-size:14px'>Bldg orientation:</div>"))))),
        wgt.dropdown.orient),
        vskip(10px),
        hbox(CSSUtil.width(200px,hbox(vbox(vskip(8px),
        HTML(string("<div style='font-size:14px'>Max. bldg plan depth (m):</div>"))))),
        wgt.spinbox.maxPlanDepth),
        vskip(10px),
        wgt.button.generateArch,
        #CSSUtil.width(300px,hbox(wgt.button.selectArch)),
        vskip(10px),
        wgt.button.generateIdf
        )


    layout = Layout(
        showlegend=false,
        xaxis=attr(title="Easting",zeroline=false,tickformat=".0f",scaleanchor="y", scaleratio=1),
        yaxis=attr(title="Northing",zeroline=false,tickformat=".0d"),
        hovermode="closest",
        margin=attr(l=100,b=60)
    )


    ui.p0 = plot(scatter(x=[0],y=[0],mode="lines",name="blank"),layout)



    ui.mainWindow = Window(async=false,Dict(:title=>"ParaDwell","width"=>2100,"height"=>1200,:x=>0,:y=>0));
    body!(ui.mainWindow,
        CSSUtil.height(1000px,hbox(
        ui.panelLeft,
        vskip(2em),
        CSSUtil.vline(),
        vskip(2em),CSSUtil.width(1350px,vbox(
            vskip(2em),
            ui.p0)),
        ui.panelRight)));

    # sleep(1)

    ##########################################


    # ui.plt_macro = ParaDwell.DIVA(adminLevel=2,exclShapeBelowLen=20);
    ui.plt_macro = ParaDwell.DIVA(adminLevel=0,exclShapeBelowLen=200);
    traces=scatter(
        name="OS 5km Tile",
        text=project.tileRegister.tileRefs,
        x=project.tileRegister.Lon_mid,
        y=project.tileRegister.Lat_mid,
        mode="markers",
        marker=attr(symbol=:square,
            size=5,color="#0652DD80"))

    addtraces!(ui.plt_macro,traces)

    w_nationwide = Window(Dict(:title=>"Macro-map",:width=>500,:height=>700,:x=>1430,:y=>360))
    body!(w_nationwide,ui.plt_macro)

    ##########################################
    return ui
end
