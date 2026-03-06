using PlotlyJS

#: -------------------------------------------------------------------------------
#: Purpose:
#: General PlotlyJS plot function with two Y2-axis and colored axis labels
#: -------------------------------------------------------------------------------

#: --- set up sample data
data_points = 5
y1_number_of_variable  = 2
y2_number_of_variables = 3
#: ---
x_vec   = collect(1:data_points)
y1_data = rand(data_points, y1_number_of_variable)
y2_data = rand(data_points, y2_number_of_variables)
# y2_data = []  # Uncomment to test single Y-axis case

#: --- manual definition of lables:
y1_data_labels = ["Variable A_y1",    "Variable B_y1"]
y2_data_labels = ["Variable A_y2",    "Variable B_y2",    "Variable C_y2"]
x_axis_lable   = "time / s"
y1_axis_labels = ["A on y1/ kg",      "B on y1/ km/h"]
y2_axis_labels = ["A on y2 / unit A", "B on y2 / unit B", "C on y2 / unit C"]
# y2_axis_labels = ["A on y2 / unit A", "", ""]

#: ---  function definition
function plot_data(_x_vec::AbstractVector, _y1_data::AbstractMatrix, _y2_data::Union{AbstractMatrix, AbstractVector, Nothing}=nothing, 
          _y1_data_labels::AbstractVector=[""], _y2_data_labels::Union{AbstractVector, Nothing}=nothing, 
          _x_axis_lable::AbstractString="", _y1_axis_labels::AbstractVector=[], _y2_axis_labels::Union{AbstractVector, Nothing}=nothing)
    
    # Initialize vector to hold all traces
    vector_of_traces = PlotlyJS.GenericTrace[]
    
    # Dictionaries to store colors for each label
    y1_colors = Dict{String, String}()
    y2_colors = Dict{String, String}()
    
    #: --- Define a color palette (PlotlyJS default colors)
    #: --- Default colorway is not accessible, but it is stable over many years now.
    _color_palette = [
        "#1f77b4", "#ff7f0e", "#2ca02c", "#d62728", "#9467bd",
        "#8c564b", "#e377c2", "#7f7f7f", "#bcbd22", "#17becf"
    ]
    
    # Determine if we have data for second Y-axis
    has_y2_data = !isnothing(_y2_data) && !isempty(_y2_data)
    
    # Create traces for Y1 axis
    for i in 1:size(_y1_data, 2)
        # Get color from palette (cycle if more traces than colors)
        color = _color_palette[mod1(i, length(_color_palette))]
        
        # Get label for this trace
        trace_label = i <= length(_y1_data_labels) ? _y1_data_labels[i] : "Variable Y1_$i"
        
        # Store color for this label
        y1_colors[trace_label] = color
        
        # Get axis label if available
        axis_label = i <= length(_y1_axis_labels) ? _y1_axis_labels[i] : ""
        
        # Create trace with specific color
        trace = PlotlyJS.scatter(;
            x = _x_vec,
            y = _y1_data[:, i],
            mode = "lines+markers",
            name = trace_label,
            line = PlotlyJS.attr(color=color),
            marker = PlotlyJS.attr(color=color),
            yaxis = "y"  # Use primary y-axis
        )
        
        push!(vector_of_traces, trace)
    end
    
    # Create traces for Y2 axis if data exists
    if has_y2_data
        for i in 1:size(_y2_data, 2)
            # Get color from palette (continue from Y1 indices)
            color = _color_palette[mod1(i + size(_y1_data, 2), length(_color_palette))]
            
            # Get label for this trace
            trace_label = i <= length(_y2_data_labels) ? _y2_data_labels[i] : "Variable Y2_$i"
            
            # Store color for this label
            y2_colors[trace_label] = color
            
            # Get axis label if available
            axis_label = i <= length(_y2_axis_labels) ? _y2_axis_labels[i] : ""
            
            # Create trace with specific color
            trace = PlotlyJS.scatter(;
                x = _x_vec,
                y = _y2_data[:, i],
                mode = "lines+markers",
                name = trace_label,
                line = PlotlyJS.attr(color=color),
                marker = PlotlyJS.attr(color=color),
                yaxis = "y2"  # Use secondary y-axis
            )
            
            push!(vector_of_traces, trace)
        end
    end
    
    # Create colored axis title for Y1
    y1_title_parts = String[]
    for i in 1:min(length(_y1_axis_labels), length(_y1_data_labels))
        if !isempty(_y1_axis_labels[i])
            # Get color for this label
            label = _y1_data_labels[i]
            color = PlotlyJS.get(y1_colors, label, "#000000")
            
            # Create HTML span with color
            colored_part = "<span style='color:$color'>$(_y1_axis_labels[i])</span>"
            push!(y1_title_parts, colored_part)
        end
    end
    
    y1_title = !isempty(y1_title_parts) ? join(y1_title_parts, " • ") : "Y1 Axis"
    
    # Create colored axis title for Y2 if needed
    y2_title = "Y2 Axis"
    if has_y2_data
        y2_title_parts = String[]
        for i in 1:min(length(_y2_axis_labels), length(_y2_data_labels))
            if !isempty(_y2_axis_labels[i])
                # Get color for this label
                label = _y2_data_labels[i]
                color = PlotlyJS.get(y2_colors, label, "#000000")
                
                # Create HTML span with color
                colored_part = "<span style='color:$color'>$(_y2_axis_labels[i])</span>"
                push!(y2_title_parts, colored_part)
            end
        end
        y2_title = !isempty(y2_title_parts) ? join(y2_title_parts, " • ") : "Y2 Axis"
    end
    
    # Create layout
    layout = PlotlyJS.Layout(;
        title = "Plot with $(has_y2_data ? "Two" : "One") Y-Axis",
        xaxis = PlotlyJS.attr(;
            title = _x_axis_lable,
            showgrid = true,
            zeroline = true
        ),
        yaxis = PlotlyJS.attr(;
            title = y1_title,  # Use HTML colored title
            titlefont = PlotlyJS.attr(size=14),  # Adjust font size if needed
            showgrid = true,
            zeroline = true
        ),
        # legend = PlotlyJS.attr(orientation = "h"),
        legend = PlotlyJS.attr(x = 0.01, y = 0.99),    
        width  = 1000,
        height = 600,
)
    
    # Add second Y-axis if needed
    if has_y2_data
        layout[:yaxis2] = PlotlyJS.attr(;
            title = y2_title,  # Use HTML colored title
            titlefont = PlotlyJS.attr(size=14),
            overlaying = "y",
            side = "right",
            showgrid = false,
            zeroline = true
        )        
        println("Plot with two y-Axis!")
    else
        println("Omit 2nd y-Axis!")
    end
    
    # Create the plot
    p = PlotlyJS.plot(vector_of_traces, layout)
    
    return p
end

#: --- Main Part ----------------------------------------------------------------------------------

#: 1) read data from recorder file.
# [...] (This would be your file reading logic)

#: 2) call plot function 
p = plot_data(x_vec, y1_data, y2_data, y1_data_labels, y2_data_labels, x_axis_lable, y1_axis_labels, y2_axis_labels)

if isnothing(p) || !(p isa PlotlyJS.SyncPlot)
    println("plot failure!")
else
    PlotlyJS.display(p)
end