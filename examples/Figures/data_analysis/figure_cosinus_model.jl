using PlotlyJS
# --- plot colours: https://community.plotly.com/t/plotly-colours-list/11730/3
# --- common layout parameter:
plt_margin = Dict(:l => 90, :r => 130, :b => 60, :t => 65)
dir_plt = joinpath(homedir(), "tmp/plt")
plt_type = ".svg"
if isdir(dir_plt)
    @info(string("Plotpath is: \"", dir_plt, "\""))
else
    try
        mkpath(dir_plt)        
    catch
        Base.invokelatest(Base.display_error, Base.catch_stack())
        error("\"$dir_plt\" could not be created!")            
    end
end
# ---
function _MyLibPltHalfTxtWidthPlotlyJS(_hdl_plt::PlotlyJS.Plot{Vector{GenericTrace{Dict{Symbol, Any}}}, Layout{Dict{Symbol, Any}}, Vector{PlotlyFrame}}, 
    _fn::AbstractString; istransparent::Bool=true,
    pltmargin::Union{Nothing, Dict{Symbol, Int64}}=nothing, plttitle::Union{Nothing, Dict{Symbol, <:Number}}=nothing)
    _, _fn_ext = splitext(_fn)
    if istransparent
        _bgrdcolor =  "rgba(0,0,0,0)"
    else
        _bgrdcolor =  "white"
    end
    # println("_fn_ext: ", _fn_ext)
    if _fn_ext in [".svg", ".pdf"]
        _layout = PlotlyJS.Layout(;
        template            = PlotlyJS.templates.simple_white,
        height              = 400,
        width               = trunc(Int, sqrt(2) * 400),
        paper_bgcolor       = _bgrdcolor,
        plot_bgcolor        = _bgrdcolor,
        title_font_size     = 28,
        font_size           = 20, 
        legend_font_size    = 20,
        xaxis               = PlotlyJS.attr(; 
            linewidth = 2.0,
            linecolor = "rgb(36,36,36)",
            zeroline  = false,
            showline  = true,
            ),
        yaxis               = PlotlyJS.attr(; 
            linewidth = 2.0,
            linecolor = "rgb(36,36,36)",
            zeroline  = false,
            showline  = true,
            ),
        )
        # ---
        _my_template = PlotlyJS.Template(layout = _layout)
        if (pltmargin===nothing) && (plttitle===nothing)
            PlotlyJS.relayout!(_hdl_plt, template = _my_template)
        elseif ~(pltmargin===nothing) && (plttitle===nothing)
            PlotlyJS.relayout!(_hdl_plt, template = _my_template, margin = pltmargin)
        elseif (pltmargin===nothing) && ~(plttitle===nothing)
            PlotlyJS.relayout!(_hdl_plt, template = _my_template, title = plttitle)
        elseif ~(pltmargin===nothing) && ~(plttitle===nothing)
            PlotlyJS.relayout!(_hdl_plt, template = _my_template, margin = pltmargin, title = plttitle)
        end
    end
    try
        PlotlyJS.savefig(_hdl_plt, _fn)
        @info(string("\"", _fn, "\" plotted!"))
    catch
        Base.invokelatest(Base.display_error, Base.catch_stack())
        @warn("savefig(\"$_fn\") failure!")
    end
    return _hdl_plt
end

function cosinus(;_frequ::Number=1.0, _ampl::Number=1.0, _phase::Number=0.0, _offset::Number=0.0, _n_prds::Int=2, _sampl_rate::Int=100)
    _sz = 1/_sampl_rate
    _n_win = ceil(Int, _n_prds/_frequ/_sz)
    _vec_t = collect(range(0, step = _sz, length = _n_win))
    _signal = _ampl .* cos.(2 * pi * _frequ .* _vec_t .+ deg2rad(_phase)) .+ _offset
    return _vec_t, _signal
end

function plt_cos_phase_shift()
    _x, _yA = cosinus()
    _x, _yB = cosinus(_phase = 15)
    _x, _yC = cosinus(_phase = 45)
    _x, _yD = cosinus(_phase = 90)
    _x, _yE = cosinus(_phase = 180)
    _xF, _yF = cosinus(_sampl_rate = 50)
    _trace_cosA = PlotlyJS.scatter(; x= _x,  y= _yA, line_width = 6.0, name = "<i>Θ</i> =   0°")
    _trace_cosB = PlotlyJS.scatter(; x= _x,  y= _yB, line_width = 4.0, name = "<i>Θ</i> =  15°")
    _trace_cosC = PlotlyJS.scatter(; x= _x,  y= _yC, line_width = 3.0, name = "<i>Θ</i> =  45°")
    _trace_cosD = PlotlyJS.scatter(; x= _x,  y= _yD, line_width = 2.0, name = "<i>Θ</i> =  90°")
    _trace_cosE = PlotlyJS.scatter(; x= _x,  y= _yE, line_width = 2.0, name = "<i>Θ</i> = 180°")
    _trace_cosF = PlotlyJS.scatter(; x= _xF, y= _yF, line_width = 1.0, name = "<i>Θ</i> = 360°", 
                    mode = "markers", 
                    marker = PlotlyJS.attr(
                        symbol  = "circle",
                        color   = "rgba(255,255,255,0)", # no colour
                        size    = 15,
                        line_width = 2,
                        line_color = "cadetblue",
                        ),            
                    )
    _traces = [_trace_cosA, _trace_cosB, _trace_cosC, _trace_cosD, _trace_cosE, _trace_cosF]
    _layout = PlotlyJS.Layout(;
        title_text          = "Cosinus @1.0 Hz: Phase Shift",
        xaxis_title         = "time / s",
        xaxis_mirror        = true,
        xaxis_constrain     = "domain", # enforce the range to the specified range
        xaxis_range         = [minimum(_x), maximum(_x)],
        yaxis_title         = "amplitude / -",
        yaxis_mirror        = true,
        yaxis_constrain     = "domain", # enforce the range to the specified range
    )
    return PlotlyJS.Plot(_traces, _layout)
end

plt_title  = Dict(:x => 0.73)
fn_plt = joinpath(dir_plt, string("cos_phase_shift", plt_type))
hdl_plt = _MyLibPltHalfTxtWidthPlotlyJS(plt_cos_phase_shift(), fn_plt, pltmargin = plt_margin, plttitle = plt_title)

function cosinus_ampl_shift()
    _x, _yA = cosinus()
    _x, _yB = cosinus(_ampl = 0.8)
    _x, _yC = cosinus(_ampl = 1.3)
    _trace_cosA = PlotlyJS.scatter(; x= _x, y= _yA, line_width = 6.0, name = "<i>A</i> = 1.0")
    _trace_cosB = PlotlyJS.scatter(; x= _x, y= _yB, line_width = 2.0, name = "<i>A</i> = 0.8")
    _trace_cosC = PlotlyJS.scatter(; x= _x, y= _yC, line_width = 3.0, name = "<i>A</i> = 1.3")
    _traces = [_trace_cosA, _trace_cosB, _trace_cosC]
    _layout = PlotlyJS.Layout(;
        title_text          = "Cosinus @1.0 Hz: Amplitude Variation",
        xaxis_title         = "time / s",
        xaxis_mirror        = true,
        yaxis_title         = "amplitude / -",
        yaxis_mirror        = true,
    )
    return PlotlyJS.Plot(_traces, _layout)
    
end
plt_title  = Dict(:x => 0.45)
fn_plt = joinpath(dir_plt, string("cos_ampl_variation", plt_type))
hdl_plt = _MyLibPltHalfTxtWidthPlotlyJS(plt_cos_phase_shift(), fn_plt, pltmargin = plt_margin, plttitle = plt_title)

# println(plt_.layout.margin)

function cosinus_frequ_shift()
    _x, _yA = cosinus()
    _x, _yB = cosinus(_frequ = 0.8)
    _x, _yC = cosinus(_frequ = 1.3)
    _trace_cosA = PlotlyJS.scatter(; x= _x, y= _yA, line_width = 6.0, name = "ν = 1.0Hz")
    _trace_cosB = PlotlyJS.scatter(; x= _x, y= _yB, line_width = 2.0, name = "ν = 0.8Hz")
    _trace_cosC = PlotlyJS.scatter(; x= _x, y= _yC, line_width = 3.0, name = "ν = 1.3Hz")
    _traces = [_trace_cosA, _trace_cosB, _trace_cosC]
    _layout = PlotlyJS.Layout(;
        title_x             = 0.5,
        title_text          = "Cosinus: Frequency Variation",
        xaxis_title         = "time / s",
        xaxis_mirror        = true,
        yaxis_title         = "amplitude / -",
        yaxis_mirror        = true,
    )
    return PlotlyJS.Plot(_traces, _layout)
    
end
plt_title  = Dict(:x => 0.45)
fn_plt = joinpath(dir_plt, string("cos_frequ_variation", plt_type))
hdl_plt = _MyLibPltHalfTxtWidthPlotlyJS(plt_cos_phase_shift(), fn_plt, pltmargin = plt_margin, plttitle = plt_title)

function cosinus_offset_variation()
    _x, _yA = cosinus()
    _x, _yB = cosinus(_offset = -0.2)
    _x, _yC = cosinus(_offset = 0.4)
    _trace_cosA = PlotlyJS.scatter(; x= _x, y= _yA, line_width = 6.0, name = "Δ<i>Α</i> =   0.0")
    _trace_cosB = PlotlyJS.scatter(; x= _x, y= _yB, line_width = 2.0, name = "Δ<i>Α</i> = - 0.2")
    _trace_cosC = PlotlyJS.scatter(; x= _x, y= _yC, line_width = 3.0, name = "Δ<i>Α</i> = + 0.3")
    _traces = [_trace_cosA, _trace_cosB, _trace_cosC]
    _layout = PlotlyJS.Layout(;
        title_x             = 0.5,
        title_text          = "Cosinus: Offset Variation",
        xaxis_title         = "time / s",
        xaxis_mirror        = true,
        yaxis_title         = "amplitude / -",
        yaxis_mirror        = true,
    )
    return PlotlyJS.Plot(_traces, _layout)
    
end
plt_title  = Dict(:x => 0.45)
fn_plt = joinpath(dir_plt, string("cos_offset_variation", plt_type))
hdl_plt = _MyLibPltHalfTxtWidthPlotlyJS(plt_cos_phase_shift(), fn_plt, pltmargin = plt_margin, plttitle = plt_title)
