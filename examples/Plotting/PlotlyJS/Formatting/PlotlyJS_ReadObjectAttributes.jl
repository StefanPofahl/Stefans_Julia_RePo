#: include(raw"C:\temp\Julia\test.jl")
#: --- Do not show verbose info:
using Logging
old_level = Logging.disable_logging(Logging.Info);
#: ---
using PlotlyJS
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
#: ---
xColorSpecified = false
x = collect(0:0.1:10);
y1 = sin.(x) ;  
#: ---             
if xColorSpecified
    trace_object = PlotlyJS.scatter(x = x, y = y1, line = PlotlyJS.attr(color = "blue", width = 3), )
else
    trace_object = PlotlyJS.scatter(x = x, y = y1, )
end

plt = PlotlyJS.plot(trace_object)

trace_number = findfirst(t -> t === trace_object, plt.plot.data)
println("trace_number: ", trace_number, "\n")

# line_color = Base.get(Base.get(trace_object, :line, Dict()), :color, "#1f77b4")
line_color = Base.get(Base.get(trace_object, :line, Dict()), :color, default_colorway[trace_number])

line_object = Base.get(trace_object, :line, Dict());
println("line_object: ", line_object, "\n")

line_color = Base.get(line_object, :color, default_colorway[trace_number])
println("line_color: ", line_color, "\n")

line_width = Base.get(line_object, :width, 0)
if line_width == 0
    println("No line width specified!")
else
    println("line_width: ", line_width, "\n")
end

#: --- restore previous Info-Setting:
Logging.disable_logging(old_level);
