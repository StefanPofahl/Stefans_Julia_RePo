# ─────────────────────────────────────────────────────────────────────────────────────────────────
#   Minimal Julia script: Dual Y-axes plot using native Plotly (PlotlyJS.jl)
# ─────────────────────────────────────────────────────────────────────────────────────────────────
#   Sample recorder file "your_log_file.csv" is located in the same folder.
#   This sample has german localization: 
#   decimal delimiter ",", column delimiter ";"
# ─────────────────────────────────────────────────────────────────────────────────────────────────
#   Installation of necessary packages:
#   Install once: ] add PlotlyJS
#   or:
#   julia> import Pkg
#   julia> Pkg.add(["CSV", "DataFrames", "Dates", "PlotlyJS"])
#: ────────────────────────────────────────────────────────────────────────────────────────────────
#:
#:  Predefined CSS-Color Keywords:
#:  https://www.w3.org/TR/css-color-3/#svg-color
#:
#: ────────────────────────────────────────────────────────────────────────────────────────────────
# ─────────────────────────────────────────────────────────────────────────────────────────────────
#   Author: Stefan Pofahl, Version 0.1, Date: 26-Feb-2026
# ─────────────────────────────────────────────────────────────────────────────────────────────────

using PlotlyJS
#: --- Do not show verbose info:
using Logging
old_level = Logging.disable_logging(Logging.Info);

#: --- Select Plot Window or default HTML-Browser:
xPlotWindow = false

# Sample data (different scales)
x = collect(0:0.1:10)
y1 = sin.(x)                # left axis, range ≈ [-1, 1]
y2 = 50 .* cos.(x) .+ 30    # right axis, range ≈ [-20, 80]

p = PlotlyJS.plot(
    [
        PlotlyJS.scatter(
            x = x,
            y = y1,
            name = "sin(x)",
            mode = "lines",
            yaxis = "y1",
            line = PlotlyJS.attr(color = "blue", width = 3)
        ),
        PlotlyJS.scatter(
            x = x,
            y = y2,
            name = "50·cos(x) + 30",
            mode = "lines",
            yaxis = "y2",                  # ← attaches to right axis
            line = PlotlyJS.attr(color = "red", width = 3, dash = "dash")
        )
    ],
    PlotlyJS.Layout(
        title = "Minimal Dual Y-Axes Example (Plotly)",
        xaxis_title = "x",
        yaxis = PlotlyJS.attr(
            title = "Left Y-Axis: sin(x)",
            side  = "left",
            # color = "blue",
        ),
        yaxis2 = PlotlyJS.attr(
            title = "Right Y-Axis: 50·cos(x) + 30",
            side = "right",
            showgrid = false,           # optional: cleaner look
            overlaying = "y",
            xaxis = "x",                # use same x-axis
        ),
        legend = PlotlyJS.attr(x = 0.01, y = 0.99, bgcolor = "rgba(255,255,255,0.8)")
    )
);

if xPlotWindow
    PlotlyJS.display(p);          # opens in browser (interactive!)
else
    temp_html_file = tempname(suffix=".html")
    println("temp_html_file: $temp_html_file")
    PlotlyJS.relayout!(p);
    # PlotlyJS.display(p);  
    PlotlyJS.savefig(p, temp_html_file, format="html");   # uncomment to save as HTML
    # --- open in different OS in your default browser
    if Sys.iswindows()
        run(`cmd /c start $temp_html_file`)
    elseif Sys.isapple()
        run(`open $temp_html_file`)
    elseif Sys.islinux()
        run(`xdg-open $temp_html_file`)
    end
    # rm(temp_html_file)
end

#: --- restore previous Info-Setting:
Logging.disable_logging(old_level);