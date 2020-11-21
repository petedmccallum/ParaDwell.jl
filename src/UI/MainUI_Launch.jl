using ParaDwell
using CSSUtil, Interact, Blink, CSV, DataFrames, PlotlyJS
global env = ParaDwell.loadPaths()
ParaDwell.OS_TileSummries(env)


function LaunchMainUI(env)

    ## TITLE PANE
    global ui = ParaDwell.UI();
    ui.title = HTML(string("<div style='font-family:consolas; font-size:32px; color:#006266'><U>ParaDwell</u></div>"));
    ui.titlePane = vbox(vskip(20px), hbox(hskip(20px),ui.title));


    ## BUILD WIDGITS
    global wgt = ParaDwell.Wgt(ParaDwell.Toggle(),ParaDwell.Dropdown(),ParaDwell.Radio(),ParaDwell.Button(),ParaDwell.Check(),ParaDwell.Spinbox());
    wgt.dropdown.markerfield = dropdown(OrderedDict("(blank)" => "Value 0", "IMD" => "Value 1", "ACORN type" => "Value 2", "Bldg. density" => "Value 3", "Pop. density" => "Value 4", "Building type" => "Value 5", "SSEN Zone" => "Value 6"));
    wgt.toggle.bldgs = toggle(label = "Show buildings");
    wgt.toggle.roads = toggle(label = "Show roadways");
    wgt.toggle.coast = toggle(label = "Show coastline");
    wgt.toggle.postcodes = toggle(label = "Show postcodes"); wgt.toggle.postcodes[] = true
    # wgt.dropdown.zone = dropdown(project.setViews.SetView); wgt.dropdown.zone[]=project.name
    wgt.button.clr = button(HTML(string("<div style='font-size:14px'>Clear viewports</div>")));
    wgt_tog_diva = toggle(label = "Basemap map"); wgt_tog_diva[]=true
    wgt_tog_datazone = toggle(label = "Datazone map");
    wgt.check.census = checkbox("Census");
    wgt.check.epc = checkbox("EPC");
    wgt.check.homeAnalytics  = checkbox("Home Analytics");
    wgt.check.acorn = checkbox("Acorn");



    ## FORMAT WIDGETS
    wgt.toggle.bldgs.scope.dom.props[:style] = Dict("height"=>18px);
    wgt.toggle.roads.scope.dom.props[:style] = Dict("height"=>18px);
    wgt.toggle.coast.scope.dom.props[:style] = Dict("height"=>18px);
    wgt_tog_diva.scope.dom.props[:style] = Dict("height"=>18px);
    wgt_tog_datazone.scope.dom.props[:style] = Dict("height"=>18px);
    wgt.button.clr.scope.dom.props[:style] = Dict("height"=>36px);


    ## LAUNCH ELECTRON
    ui.subPanelLeft1 = CSSUtil.width(200px,vbox(
        CSSUtil.hline(),
        vskip(20px),
        wgt_tog_diva,
        wgt_tog_datazone,
        CSSUtil.hline(),
        vskip(20px),
        wgt.toggle.postcodes,
        wgt.dropdown.markerfield,
        vskip(10px),
        wgt.toggle.bldgs,
        wgt.toggle.roads,
        wgt.toggle.coast,
        CSSUtil.hline(),
        vskip(20px),
        HTML(string("<div style='font-size:16px'><b><u>Data links:</u></b></div>")),#vskip(10px),
        vbox(wgt.check.census),
        vbox(wgt.check.homeAnalytics),
        vbox(wgt.check.epc),
        vskip(-10px),
        wgt.check.acorn,
        CSSUtil.hline()
    ));
    ui.panelLeft = vbox(CSSUtil.height(650px,vbox(ui.titlePane,"", vskip(30px), hbox(hskip(20px), ui.subPanelLeft1))));


    ## CREATE WIDGETS FOR RHS PANEL
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
        xaxis=attr(zeroline=false,
            scaleanchor="y", scaleratio=1),
        hovermode="closest"
    )


    ui.p0 = plot(scatter(x=[0],y=[0],mode="lines",name="blank"),layout)



    ui.mainWindow = Window(async=false,Dict("width"=>2100,"height"=>1200));
    body!(ui.mainWindow,
        CSSUtil.height(600px,hbox(
        ui.panelLeft,
        vskip(2em),
        CSSUtil.vline(),
        vskip(2em),CSSUtil.width(1400px,vbox(
            vskip(2em),
            hbox(
                hskip(2em),
                "Set view:",
                hskip(2em),
                # wgt.dropdown.zone,
                hskip(2em),
                wgt.button.clr),
            ui.p0)),
        ui.panelRight)));

    # sleep(1)

    ##########################################
    ParaDwell.OS_TileSummries(env)


    tileRegister = CSV.read(joinpath(env.paths[:projects],".OS_TileRegister.csv")) |> DataFrame


    plt_nationwide = ParaDwell.DIVA();
    traces=scatter(
        name="OS 5km Tile",
        text=tileRegister.tileRefs,
        x=tileRegister.Lon_mid,
        y=tileRegister.Lat_mid,
        mode="markers",
        marker=attr(symbol=:square,
            size=5,color="#0652DD80"))

    addtraces!(plt_nationwide,traces)

    w_nationwide = Window(Dict(:width=>1200,:height=>1200))
    body!(w_nationwide,plt_nationwide)

    ##########################################
    return plt_nationwide
end

# LaunchMainUI(env);
