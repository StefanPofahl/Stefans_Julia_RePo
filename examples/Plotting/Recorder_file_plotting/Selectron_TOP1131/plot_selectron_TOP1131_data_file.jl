# ─────────────────────────────────────────────────────────────────────────
#   Plot proprietary Selectron TOP1131-Recorder-File.
# ─────────────────────────────────────────────────────────────────────────
#   Sample recorder file "your_log_file.csv" is located in the same folder.
#   This sample has german localization: 
#   decimal delimiter ",", column delimiter ";"
# ─────────────────────────────────────────────────────────────────────────
#   Installation of necessary packages:
#   julia> import Pkg
#   julia> Pkg.add(["CSV", "DataFrames", "Plots", "Dates"])
# ─────────────────────────────────────────────────────────────────────────
#   remark: early draft state
# ─────────────────────────────────────────────────────────────────────────
#   Author: Stefan Pofahl, Version 0.1, Date: 26-Feb-2026
# ─────────────────────────────────────────────────────────────────────────

using CSV
using DataFrames
using Plots
using Dates


# --- Params: ------------------------------------------------------------
# filename = raw"your_log_file.csv"  # Replace with your actual filename
filename = raw"C:\temp\data\log\simulate_locomotive.csv" 
# plt_filename = raw"C:\temp\data\log\plt\log_plot.png"
plt_filename = raw"C:\temp\data\log\plt\log_plot.svg"
plt_filename = raw"C:\temp\data\log\plt\log_plot_Plots.html"
# --- Search strings to find relevant columns:
time_lbl  = "rTimeElapsed_s" 
data1_lbl = "rVelocity_km_per_h"
data2_lbl = "rTractionForceGross_SP_kN"
data3_lbl = "rTractionForceNet_kN"

# --- Function to parse German locale numbers (comma as decimal separator)
function parse_german_number(str::String)
    # Replace comma with dot and parse
    str = replace(str, "," => ".")
    return parse(Float64, str)
end

# --- Read the CSV file with German locale settings
function read_german_csv(filename::String)
    # Read all lines from file
    lines = readlines(filename)
    
    # Find the header line (starts with "Nb;Type;Date;Time;...")
    header_idx = findfirst(line -> startswith(line, "Nb;Type;Date;Time;"), lines)
    
    if header_idx === nothing
        error("Could not find header line starting with 'Nb;Type;Date;Time;'")
    end
    
    # Write header and data to a temporary buffer
    temp_file = tempname()
    open(temp_file, "w") do io
        # Write header
        println(io, lines[header_idx])
        # Write data lines
        for i in (header_idx + 1):length(lines)
            if !isempty(strip(lines[i]))
                println(io, lines[i])
            end
        end
    end
    
    # Read the data with custom parsing for German numbers
    df = CSV.read(temp_file, DataFrame;
                  delim=';',
                  decimal=',',
                  missingstrings=[""],
                  stripwhitespace=true)
    
    # Clean up temp file
    rm(temp_file)
    
    return df
end

# --- Main plotting function
function plot_log_data(_filename::String, _time_lbl::String="rTimeElapsed", 
    _data1_lbl::String="rVelocity", _data2_lbl::String="rTractionForce", _data3_lbl::String="rDBGrForceNet_kN")
    # Read the data
    println("Reading data from: ", _filename)
    df = read_german_csv(_filename)
    
    # Extract column names (they might have quotes or special characters)
    println("Available columns: ", names(df))
    
    # Rename columns to simpler names for easier handling
    # We need to find the exact column names as they appear in the file
    col_names = names(df)
    
    # Find the relevant columns (using partial matching)
    # time_col = findfirst(name -> occursin("rTimeElapsed", name), col_names)
    time_col      = findfirst(name -> occursin(_time_lbl, name),  col_names)
    velocity_col  = findfirst(name -> occursin(_data1_lbl, name), col_names)
    traction_col  = findfirst(name -> occursin(_data2_lbl, name), col_names)
    force_net_col = findfirst(name -> occursin(_data3_lbl, name), col_names)
    
    if any(isnothing, [time_col, velocity_col, traction_col, force_net_col])
        error("Could not find all required columns")
    end
    
    # Extract data
    time = df[!, col_names[time_col]]
    velocity = df[!, col_names[velocity_col]]
    traction_force = df[!, col_names[traction_col]]  
    force_net = df[!, col_names[force_net_col]]      
    
    # Create the plot
    p = Plots.plot(time, velocity,
             label="speed",
             xlabel="time / s",
             ylabel="v / km/h",
             color=:blue,
             linewidth=2,
             legend=:topleft)
    
    # Add secondary y-axis
    p_twin = Plots.twinx()
    Plots.plot!(p_twin, time, traction_force,
          label="F_traction",
          ylabel="force / kN",
          color=:red,
          linewidth=2,
          linestyle=:solid)
    
    Plots.plot!(p_twin, time, force_net,
          label="F_net",
          color=:green,
          linewidth=2,
          linestyle=:dash)
    
    # Add title
    Plots.title!("Log Data Analysis - $(basename(_filename))")
    # Optional:
    # Plots.ylims!(p_twin, (0, 500))        # Grenzen anpassen
    
    return p
end

# --- Function to process multiple files
function plot_multiple_files(filenames::Vector{String})
    plots = []
    for file in filenames
        push!(plots, plot_log_data(file, time_lbl, data1_lbl, data2_lbl, data3_lbl))
    end
    
    if length(plots) > 1
        return plot(plots..., layout=(length(plots), 1), size=(800, 400*length(plots)))
    else
        return plots[1]
    end
end

# --- execution:
#; remark:
#; variable "filename" is specified at the top.
# -----------------------------------------------------------------------------
if isfile(filename)
    p = plot_log_data(filename, time_lbl, data1_lbl, data2_lbl, data3_lbl)
    Plots.display(p)
    # Save the plot
    Plots.savefig(p, plt_filename)
    println("Plot saved as $plt_filename")
else
    println("File not found: ", filename)
    println("Please specify the correct path to your log file.")
    
    # Alternative: let user input filename
    print("Enter the filename: ")
    filename = strip(readline())
    if isfile(filename)
        p = plot_log_data(filename, time_lbl, data1_lbl, data2_lbl, data3_lbl)
        Plots.display(p)
        Plots.savefig(p, plt_filename)
    else
        println("File still not found. Exiting.")
    end
end