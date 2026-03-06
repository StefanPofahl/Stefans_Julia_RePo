# ─────────────────────────────────────────────────────────────────────────
#   Plot proprietary Selectron TOP1131-Recorder-File.
# ─────────────────────────────────────────────────────────────────────────
#   Sample recorder file "your_log_file.csv" is located in the same folder.
#   This sample has german localization: 
#   decimal delimiter ",", column delimiter ";"
# ─────────────────────────────────────────────────────────────────────────
#   Installation of necessary packages:
#   julia> import Pkg
#   julia> Pkg.add(["CSV", "DataFrames", "Dates", "PlotlyJS"])
#: ─────────────────────────────────────────────────────────────────────────
#:  Predefined CSS-Color Keywords:
#:  https://www.w3.org/TR/css-color-3/#svg-color
#: ─────────────────────────────────────────────────────────────────────────
#   Author: Stefan Pofahl, Version 0.1, Date: 26-Feb-2026
# ─────────────────────────────────────────────────────────────────────────
# include(raw"C:\temp\data\log\plot_Speed_and_forces.jl")
using CSV
using DataFrames
using PlotlyJS
#: --- Do not show verbose info:
using Logging
old_level = Logging.disable_logging(Logging.Info)

# --- Params: --------------------------------------------------------------------------
xDataRangeSelected = false
iY1AxisSelection = 3 # one of [1, 2, 3], 1= F_traction, 2= Velocity, 3= time over index
xPlotWindow = true   # display in Plot-Window if true, else display in default browser
# --- Recoder File and Plot Path:
data_file_name = raw"C:\your\path\log\your_log_file.csv"
plt_path       = raw"C:\temp\plt"

# --- Search strings to find relevant columns:
time_lbl      = "rTimeElapsed_s" 
speed_lbl     = "rVelocity_km_per_h"
y1_data1_lbl  = "rTractionForceGross_SP_kN"
y1_data2_lbl  = "rTractionForceNet_kN"
y2_data1_lbl  = "rForceAir_kN"
y2_data2_lbl  = "rForceSpeed_kN"
y2_data3_lbl  = "rForceResist_kN"
if xDataRangeSelected
    first_line    = 280
    last_line     = 4280
else
    first_line    = []
    last_line     = []
end
#: --- Preliminaries: ----------------------------------------------------------------------
fn_html          = string(splitext(basename(data_file_name))[1] * ".html")
fn_plt           = joinpath([plt_path, fn_html])
#: --- Functions ---------------------------------------------------------------------------
function string_vec_to_number(_vec::AbstractVector)
    if !all(isa.(_vec, AbstractString))
        println("Some Non-String-Elements! ")
    end
    # ---
    # _out = map(x -> something(tryparse(Float64, x), missing), _vec)
    _out = map(x -> something(tryparse(Float64, replace(x, ',' => '.')), missing), _vec)
    return _out
end

# --- Read the CSV file with German locale settings
function read_german_csv(_filename::String)
    # --- Read all _lines from file
    _lines = readlines(_filename) # data type: Vector{String}
    
    # --- Find the header line (starts with "Nb;Type;Date;Time;...")
    _header_idx = findfirst(line -> startswith(line, "Nb;Type;Date;Time;"), _lines)
    if _header_idx === nothing
        error("Could not find header line starting with 'Nb;Type;Date;Time;'")
        _data_points = nothing
    else
        _data_points = length(_lines) - (_header_idx + 1)
    end
    
    # --- Write header and data to a temporary buffer
    temp_file = tempname()
    open(temp_file, "w") do io
        # --- Write header
        println(io, _lines[_header_idx])
        # --- Write data _lines
        for i in (_header_idx + 1):length(_lines)
            if !isempty(strip(_lines[i]))
                println(io, _lines[i])
            end
        end
    end
    #: --- read in all data
    df = CSV.read(temp_file, DataFrame;
        delim           = ';',
        missingstring   = ["", "NA", "N/A", "#NV"],  # Liste erweitern
        stripwhitespace = true,
        types           = String,)   # ← alles als String einlesen

    #: --- Clean up temp file
    rm(temp_file)
    
    return df
end

# --- Main plotting function
function plot_log_data(_filename::String, _first_line::Union{Integer, Nothing, AbstractVector}=nothing, _last_line::Union{Integer, Nothing, AbstractVector}=nothing, 
    _time_lbl::String="rTimeElapsed", _velocity_lbl::String="rVelocity_km_per_h", 
    _y1_data1_lbl::String="rF_Traction_kN", _y1_data2_lbl::String="rForceNet_kN", 
    _y2_data1_lbl::String="rF_Air_kN",      _y2_data2_lbl::String="rF_Speed_kN",  _y2_data3_lbl::String="rForceNet_kN")
    # Read the data
    println("Reading data from: ", _filename)
    df = read_german_csv(_filename)
        
    # Rename columns to simpler names for easier handling
    # We need to find the exact column names as they appear in the file
    col_names = names(df)
    
    # Find the relevant columns (using partial matching)
    # time_col = findfirst(name -> occursin("rTimeElapsed", name), col_names)
    _time_col            = findfirst(name -> occursin(_time_lbl,     name), col_names)
    _velocity_col        = findfirst(name -> occursin(_velocity_lbl, name), col_names) 
    _y1t1_F_tract_col    = findfirst(name -> occursin(_y1_data1_lbl, name), col_names)
    _y1t2_F_trac_net_col = findfirst(name -> occursin(_y1_data2_lbl, name), col_names)   
    _y2t1_F_Air_col      = findfirst(name -> occursin(_y2_data1_lbl, name), col_names)
    _y2t2_F_Speed_col    = findfirst(name -> occursin(_y2_data2_lbl, name), col_names)
    _y2t3_F_resist_col   = findfirst(name -> occursin(_y2_data3_lbl, name), col_names)
    
    # println("-"^120, "Available columns: \n", names(df), "\n", "-"^120, "\n")
    #: --- Show available column headers, if specification given is not correct.    
    if any(isnothing, [_time_col, _velocity_col, _y1t1_F_tract_col, _y2t1_F_Air_col, _y2t2_F_Speed_col, _y2t3_F_resist_col])
        #: --- Extract column names (they might have quotes or special characters)
        println("\n", "*"^100)
        println("\nAvailable columns: ", names(df))
        println("*"^100, "\n")
        error("Could not find all required columns")
    end
    
    #: --- Extract all data
    _time_vec   = string_vec_to_number(df[!, col_names[_time_col]])
    _Speed      = string_vec_to_number(df[!, col_names[_velocity_col]])
    _F_traction = string_vec_to_number(df[!, col_names[_y1t1_F_tract_col]])
    _F_trac_net = string_vec_to_number(df[!, col_names[_y1t2_F_trac_net_col]])
    _F_air      = string_vec_to_number(df[!, col_names[_y2t1_F_Air_col]])
    _F_speed    = string_vec_to_number(df[!, col_names[_y2t2_F_Speed_col]]) 
    _F_resist   = string_vec_to_number(df[!, col_names[_y2t3_F_resist_col]]) 
    
    # ---
    _data_pts   = length(_time_vec)

    flush(stdout)
    #: ---
    _indx_t_min = findfirst(isequal(minimum(skipmissing(_time_vec))), _time_vec)
    _indx_t_max_first = findfirst(isequal(maximum(skipmissing(_time_vec))), _time_vec)
    _indx_t_max_after = findfirst(isequal(maximum((_time_vec[_indx_t_min:end]))), _time_vec[_indx_t_min:end]) + _indx_t_min - 1
    #: --- Statistiken
    println("\n", "─"^100)
    println("  Statistics:")
    println("  Time domain: {t = $(minimum(skipmissing(_time_vec))) | $(maximum(skipmissing(_time_vec)))} s")
    println("  F_Speed:     {F_Speed = $(round(minimum(skipmissing(_F_air)), digits=1)) | $(round(maximum(skipmissing(_F_air)), digits=1))} km/h")
    println("  F_Air:       {F_Air = $(round(minimum(skipmissing(_F_speed)), digits=1)) | $(round(maximum(skipmissing(_F_speed)), digits=1))} kN")
    println("  Net Force:   {F_net = $(round(minimum(skipmissing(_F_resist)), digits=1)) | $(round(maximum(skipmissing(_F_resist)), digits=1))} kN")
    println("  Data points: n = $_data_pts, Index numbers, t_min@ $_indx_t_min, first t_max@ $_indx_t_max_first, 1st t_max after t_min@ $_indx_t_max_after")
    println("  t_min =  $(_time_vec[_indx_t_min]) s @($_indx_t_min), t_max_after: $(_time_vec[_indx_t_max_after]) s @($_indx_t_max_after), first t_max = $(_time_vec[_indx_t_max_first]) s @($_indx_t_max_first)")
    println("─"^100, "\n")
    
    #: --- check if start- and end-line are suitable:
    if _first_line isa AbstractVector || isnothing(_first_line); _first_line= 1;          end
    if _last_line  isa AbstractVector || isnothing(_last_line);  _last_line = _data_pts;  end
    if _last_line > _data_pts
        println("Last line: $_last_line greater than number of data point: $_data_pts, value correted to last point.")
        _last_line = _data_pts
    end 
    if _last_line < _first_line 
        println("Last line: $_last_line smaller than First line: $_first_line, value correted to last point.")
        _last_line = _data_pts
    end
    if _first_line >= _last_line
        println("First line: $_first_line above Last line: $_first_line, first lien corrected to: 1")
        _first_line = 1
    else
        _first_line = max(_first_line, 1)
    end
    #: --- read again but only selection:
    if iY1AxisSelection != 3  
        _x_vec = _time_vec[_first_line:_last_line]
        _x_axis_label = "time / s"
    else
        _x_vec = collect(range(_first_line, _last_line))
        _x_axis_label = "index / -"
    end
    if iY1AxisSelection == 1
        _y1_vec1 = _F_traction[_first_line:_last_line]
        _y1_axis_label = "F_trac / kN"
        _y1_trace_lbl  = "F_traction"
    elseif iY1AxisSelection == 2
        _y1_vec1 = _Speed[_first_line:_last_line]
        _y1_axis_label = "Speed / km/h"
        _y1_trace_lbl  = "Speed"
    elseif iY1AxisSelection == 3
        _y1_vec1 = _time_vec[_first_line:_last_line]
        _y1_axis_label = "time / s"
        _y1_trace_lbl  = "time"
    else
        error("\niY1AxisSelection = $iY1AxisSelection out of scope, which is [1 .. 3].\n", "*"^100, "\n")
    end
    _F_trac_net = _F_trac_net[_first_line:_last_line]
    _F_air      = _F_air[_first_line:_last_line]
    _F_speed    = _F_speed[_first_line:_last_line]
    _F_resist   = _F_resist[_first_line:_last_line] 

    _Speed_max  = maximum(_Speed);
    println("Max _F_speed: $_Speed_max km/h")
    println("─"^100)

    #: --- Create PlotlyJS plot with dual y-axes
    #: --- y1-axis:
    trace1_Y1 = PlotlyJS.scatter(
        x = _x_vec,
        y = _y1_vec1,
        name = _y1_trace_lbl,
        mode = "_lines",
        yaxis = "y1",
        line = PlotlyJS.attr(color = "orange", width = 3)
    );

    if iY1AxisSelection == 1
        trace_F_trac_net = PlotlyJS.scatter(
            x = _x_vec,
            y = _F_trac_net,
            name = "F_trac_net",
            mode = "_lines",
            yaxis = "y1",
            line = PlotlyJS.attr(color = "darkgoldenrod", width = 3)
        );
    end

    #: --- y2-axis:
    trace_F_air = PlotlyJS.scatter(
        x = _x_vec,
        y = _F_air,
        name = "F_air",
        mode = "_lines",
        yaxis = "y2",
        line = PlotlyJS.attr(color = "blue", width = 2)
    );
    
    trace_F_speed = PlotlyJS.scatter(
        x = _x_vec,
        y = _F_speed,
        name = "F_speed",
        mode = "_lines",
        yaxis = "y2",
        line = attr(color = "red", width = 2)
    );
    
    trace_F_net = PlotlyJS.scatter(
        x = _x_vec,
        y = _F_resist,
        name = "F_net",
        mode = "_lines",
        yaxis = "y2",
        line = attr(color = "green", width = 2, dash = "dash")
    );
    
    layout = PlotlyJS.Layout(
        title = "Log Data Analysis - $(basename(_filename))",
        xaxis_title = _x_axis_label,
        yaxis = PlotlyJS.attr(
            title = _y1_axis_label,
            side  = "left",
            color = "blue",
        ),
        yaxis2 = PlotlyJS.attr(
            title = "forces F / kN",
            side  = "right",
            showgrid = false,           # No grid for secondary axes
            overlaying = "y",
            color = "red",
            xaxis = "x",                # use same x-axis
        ),
        legend = PlotlyJS.attr(x = 0.01, y = 0.99),
        width  = 1000,
        height = 600
    );
    if iY1AxisSelection == 1
        plot_traces = [trace1_Y1, trace_F_trac_net, trace_F_air, trace_F_speed, trace_F_net]
    else
        plot_traces = [trace1_Y1, trace_F_air, trace_F_speed, trace_F_net]
    end
    p = PlotlyJS.plot(plot_traces, layout);
    
    return p;
end

# --- execution staarts here: -----------------------------------------------------------------------------------
println("="^100)
println(" Recorder File Plotter (Plotly Interactive)")
println("="^100)
#: --------------------------------------------------------------------------------------------------------------
path_name = dirname(fn_plt)
if ! ispath(path_name)
    println("Folder created: $path_name")
    mkpath(path_name)
end

if isfile(data_file_name)
    p = plot_log_data(data_file_name, first_line, last_line, 
              time_lbl, speed_lbl, y1_data1_lbl, y1_data2_lbl, 
              y2_data1_lbl, y2_data2_lbl, y2_data3_lbl);
    PlotlyJS.relayout!(p);
    # --- Save the plot:
    PlotlyJS.savefig(p, fn_plt);
    if xPlotWindow
        PlotlyJS.display(p);
    else
        temp_html_file = joinpath(tempdir(), "temp.html")
        PlotlyJS.savefig(p, temp_html_file);
        if Sys.iswindows()
            run(`cmd /c start $temp_html_file`)
        elseif Sys.isapple()
            run(`open $temp_html_file`)
        elseif Sys.islinux()
            run(`xdg-open $temp_html_file`)
        end
    end
else
    println("File: \"", data_file_name, "\" not found!")
end

#: --- restore previous Info-Setting:
Logging.disable_logging(old_level);