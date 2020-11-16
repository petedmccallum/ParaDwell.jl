struct Env
    paths::Dict
end

mutable struct Project
    name::String
    paths::Dict
    setViews::DataFrame
    dat::Dict{String,Any}
    Project() = new()
end

mutable struct OsmFeatures
    OsmId::Int64
    OSG_UPRNs::Array{Int64}
    BlockId_HA::String
    featureType::String
    nodes::Array{Int64}
    LatLon::Array{Float64}
    centre::Array{Float64}
    Orientation::Float64
    w::Float16
    d::Float16
    tp::Float16
    tol::Float16
    tor::Float16
    area::Float16
    flag::String
    arch::String
    shape::String
end

mutable struct Osm
    region::String
    ways
    nodeList::Array{Int64}
    nodes::Array{XMLElement,1}
    ind::Array{Int64}
    frame::Array{Float64}
    Osm() = new()
end


mutable struct Toggle
    bldgs::Widget{:toggle,Bool}
    roads::Widget{:toggle,Bool}
    coast::Widget{:toggle,Bool}
    postcodes::Widget{:toggle,Bool}
    Toggle() = new()
end
mutable struct Dropdown
    markerfield::Widget{:dropdown,Any}
    zone::Widget{:dropdown,Any}
    orient::Widget{:dropdown,Any}
    Dropdown() = new()
end
mutable struct Radio
    spare1::Widget{:radiobuttons,Any}
    Radio() = new()
end
mutable struct Button
    clr::Widget{:button,Int64}
    generateArch::Widget{:button,Int64}
    #selectArch::Widget{:button,Int64}
    generateIdf::Widget{:button,Int64}
    Button() = new()
end
mutable struct Spinbox
    dimensionalRounding::Widget{:spinbox,Union{Nothing, Int64}}
    maxPlanDepth::Widget{:spinbox,Union{Nothing, Int64}}
    Spinbox() = new()
end
mutable struct Check
    census::Widget{:checkbox,Bool}
    epc::Widget{:checkbox,Bool}
    homeAnalytics::Widget{:checkbox,Bool}
    acorn::Widget{:checkbox,Bool}
    Check() = new()
end

mutable struct Wgt
    toggle::Toggle
    dropdown::Dropdown
    radio::Radio
    button::Button
    check::Check
    spinbox::Spinbox
end

mutable struct UI
    title::HTML{String}
    subtitle::HTML{String}
    titlePane::Node{WebIO.DOM}
    pathLogos::String
    logo1::Array{RGBA{Normed{UInt8,8}},2}
    kmPerDegLat::Float64
    mainWindow::Window
    logoPanel::Node{WebIO.DOM}
    subPanelLeft1::Node{WebIO.DOM}
    panelLeft::Node{WebIO.DOM}
    panelRight::Node{WebIO.DOM}
    p0::PlotlyJS.SyncPlot
    ns_bounds::Tuple{Float64,Float64}
    previousView::String
    wgt::Wgt
    UI() = new()
end

struct UI_launch
    title::HTML{String}
    window::Window
    wgt_dropdown::Widget{:dropdown,Any}
    wgt_button_go::Widget{:button,Int64}
    wgt_button_newProject::Widget{:button,Int64}
    wgt_textbox_newProject::Widget{:textbox,String}
end
mutable struct GIS
    datum
    origin
    transf_LLAfromENU
    transf_ENUfromLLA
    GIS() = new()
end


mutable struct Data
    Census::DataFrame
    EST::DataFrame
    ByBlock::DataFrame
    OSM::DataFrame
    Acorn::DataFrame
    Data() = new()
end

mutable struct Recentre2
    fix
    tmp_PostcodeGroups
    yscale
    xscale
    iOsmLLA
    BlockId
    focalPt
    refocusId
    frame
    angleSetEST
    angleSetOSM
    BlockSubsetEST
    BlockSubsetOSM
    iNearestOSM
    refocusNudge
    frameExpansion
    refocusLLA
    iOsmFocus
    Recentre2() = new()
end
