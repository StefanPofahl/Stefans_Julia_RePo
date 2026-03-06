using PlotlyJS

#: ─────────────────────────────────────────────────────────────────────────
#:  Predefined CSS-Color Keywords:
#:  https://www.w3.org/TR/css-color-3/#svg-color
#: ─────────────────────────────────────────────────────────────────────────
# ==============================================================================
# SOLUTION: Hide X-axes for additional Y-axes
# ==============================================================================
# Problem: When creating multiple Y-axes, Plotly automatically creates 
# corresponding X-axes for each Y-axis. These appear as additional horizontal 
# lines in the plot that can be mistaken for extra grid lines.
#
# Solution: Force all secondary Y-axes to use the primary X-axis 
# by setting xaxis = "x" in their attributes.
# ==============================================================================

fn = raw"C:\temp\data\log\plt\four_axis.html"
# Example data
data_points = 10
x_vec = collect(1:data_points)

# Data for four different Y-axes
y1_data = rand(data_points, 1)  # Primary Y-axis (left)
y2_data = rand(data_points, 1)  # Second Y-axis (right)
y3_data = rand(data_points, 1)  # Third Y-axis (left of Y1)
y4_data = rand(data_points, 1)  # Fourth Y-axis (right of Y2)

# Labels
y1_labels = ["Data for Y1"]
y2_labels = ["Data for Y2"]
y3_labels = ["Data for Y3"]
y4_labels = ["Data for Y4"]

#: --- Default colorway is not accessible, but it is stable over many years now.
const default_colorway = [
    "#1f77b4",  # muted blue
    "#ff7f0e",  # safety orange
    "#2ca02c",  # cooked asparagus green
    "#d62728",  # brick red
    "#9467bd",  # muted purple
    "#8c564b",  # chestnut brown
    "#e377c2",  # raspberry yogurt pink
    "#7f7f7f",  # middle gray
    "#bcbd22",  # curry yellow-green
    "#17becf"   # blue-teal
]


# Create traces
traces = PlotlyJS.GenericTrace[]

# Y1 Trace (primary axis - standard left)
trace1 = PlotlyJS.scatter(;
    x = x_vec,
    y = y1_data[:, 1],
    mode = "lines+markers",
    name = y1_labels[1],
    line = PlotlyJS.attr(color= default_colorway[1]),
    marker = PlotlyJS.attr(color= default_colorway[1]),
    yaxis = "y"
)
push!(traces, trace1)

# Y2 Trace (second axis - right)
trace2 = PlotlyJS.scatter(;
    x = x_vec,
    y = y2_data[:, 1],
    mode = "lines+markers",
    name = y2_labels[1],
    line = PlotlyJS.attr(color=default_colorway[2]),
    marker = PlotlyJS.attr(color=default_colorway[2]),
    yaxis = "y2"
)
push!(traces, trace2)

# Y3 Trace (third axis - left of Y1)
trace3 = PlotlyJS.scatter(;
    x = x_vec,
    y = y3_data[:, 1],
    mode = "lines+markers",
    name = y3_labels[1],
    line = PlotlyJS.attr(color=default_colorway[3]),
    marker = PlotlyJS.attr(color=default_colorway[3]),
    yaxis = "y3"
)
push!(traces, trace3)

# Y4 Trace (fourth axis - right of Y2)
trace4 = PlotlyJS.scatter(;
    x = x_vec,
    y = y4_data[:, 1],
    mode = "lines+markers",
    name = y4_labels[1],
    line = PlotlyJS.attr(color=default_colorway[4]),
    marker = PlotlyJS.attr(color=default_colorway[4]),
    yaxis = "y4"
)
push!(traces, trace4)

# Define exact tick values for Y1-axis (0.0, 0.1, 0.2, ..., 1.0)
# This ensures grid lines appear exactly where we want them
y1_tickvals = collect(0:0.1:1.0)
y1_ticktext = [string(round(val, digits=1)) for val in y1_tickvals]

# Layout with four Y-axes in the desired arrangement
layout = PlotlyJS.Layout(;
    title  = "Plot with four Y-axes",
    width  = 900,
    height = 500,
    
    # Primary X-axis (for all traces)
    # The domain creates space on left and right for additional Y-axes
    xaxis = PlotlyJS.attr(
        title = "Time / s",
        domain = [0.15, 0.85],  # 15% space left, 15% space right for additional axes
        showgrid = true,          # Show grid for primary X-axis
        gridcolor = "lightgray",  # Optional: different color for X-grid
        gridwidth = 1
    ),
    
    # Y1 - Primary axis (left) with explicit ticks
    # This is the only axis that shows grid lines
    yaxis = PlotlyJS.attr(
        title = "Y1 Axis (primary)",
        titlefont_color = default_colorway[1],
        tickfont_color  = default_colorway[1],
        showgrid = true,           # ONLY Y1 shows grid lines
        side = "left",
        position   = 0.15,
        tickvals   = y1_tickvals,      # Exact positions of ticks
        ticktext   = y1_ticktext,       # Labels for ticks
        gridwidth  = 1,                 # Width of grid lines
        gridcolor  = "white",            # Color of grid lines
        zeroline   = true,                # Show the zero line
        zerolinecolor = "white",        # Color of zero line
        zerolinewidth = 2               # Width of zero line
    ),
    
    # Y2 - Second axis (right)
    # IMPORTANT: Use primary X-axis to avoid creating a separate X-axis with its own lines
    yaxis2 = PlotlyJS.attr(
        title = "Y2 Axis",
        titlefont_color = default_colorway[2],
        tickfont_color  = default_colorway[2],
        overlaying = "y",          # Overlay on the same plotting area
        side =   "right",
        position = 0.85,
        showgrid = false,           # No grid for secondary axes
        anchor = "free",            # Free positioning
        # CRITICAL: Use the primary X-axis to prevent creation of a separate X-axis
        # Without this, Plotly creates an independent X-axis for Y2 which appears 
        # as additional horizontal lines in the plot
        xaxis = "x"  # Use the primary X-axis
    ),
    
    # Y3 - Third axis (left of Y1)
    # IMPORTANT: Use primary X-axis to avoid creating a separate X-axis
    yaxis3 = PlotlyJS.attr(
        title = "Y3 Axis (left of Y1)",
        titlefont_color = default_colorway[3],
        tickfont_color = default_colorway[3],
        overlaying = "y",
        side = "left",
        position = 0.05,  # 5% from left edge (outside the plot area)
        showgrid = false,
        anchor = "free",
        # CRITICAL: Use the primary X-axis
        xaxis = "x"  # Use the primary X-axis
    ),
    
    # Y4 - Fourth axis (right of Y2)
    # IMPORTANT: Use primary X-axis to avoid creating a separate X-axis
    yaxis4 = PlotlyJS.attr(
        title = "Y4 Axis (right of Y2)",
        titlefont_color = default_colorway[4],
        tickfont_color  = default_colorway[4],
        overlaying = "y",
        side = "right",
        position = 0.94,  # 94% from left edge (6% from right edge)
        showgrid = false,
        anchor = "free",
        # CRITICAL: Use the primary X-axis
        xaxis = "x"  # Use the primary X-axis
    )
)

# Create and display the plot
p = PlotlyJS.plot(traces, layout)
PlotlyJS.relayout!(p)
PlotlyJS.display(p)
PlotlyJS.savefig(p, fn)

# ==============================================================================
# EXPLANATION OF THE CRITICAL FIX:
# ==============================================================================
# The "additional white lines" in the plot were NOT extra grid lines,
# but rather the X-axes belonging to the secondary Y-axes (Y2, Y3, Y4)!
#
# By default, when you create multiple Y-axes with overlaying = "y", 
# Plotly automatically creates corresponding X-axes for each Y-axis.
# Each of these X-axes draws its own axis line across the plot,
# appearing as horizontal lines that can be mistaken for grid lines.
#
# The solution is to explicitly tell each secondary Y-axis to use
# the primary X-axis by adding:
#     xaxis = "x"
#
# This means:
# - All Y-axes share the SAME X-axis (the primary one)
# - No additional X-axes are created
# - No extra horizontal lines appear in the plot
# - Only the primary X-axis shows grid lines (if enabled)
#
# The result is a clean plot with multiple Y-axes but only one
# consistent X-axis and grid system.
# ==============================================================================

# Additional tips:
# - To hide ALL X-axis grid lines, set showgrid = false in the primary xaxis
# - To customize grid line appearance, use gridcolor, gridwidth, etc.
# - The domain [0.15, 0.85] creates space for additional Y-axes on both sides
# - Position values (0.05, 0.15, 0.85, 0.94) place axes exactly where desired