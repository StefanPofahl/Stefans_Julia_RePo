using GLMakie
# --- -------------------------------------------------------------------------------------------------------------------- #
# motivation: espacially in graphs with equidistant axis scaling, also the tick spacing should be equidistant as well.     #
# source:                                                                                                                  #
# https://discourse.julialang.org/t/optimal-layouting-with-dataaspect/75121/7                                              #
# ........................................................................................................................ #
struct DeltaTicks
    delta::Float64
    offset::Float64
end
# --- implizit function definition DeltaTicks(dtick):
DeltaTicks(_dtick) = DeltaTicks(_dtick, 0.0)

function GLMakie.Makie.get_tickvalues(_dt::DeltaTicks, ::Any, vmin, vmax)
    _f_start = ceil((vmin - _dt.offset) / _dt.delta)
    _start = _dt.offset + _f_start * _dt.delta
    println("vmin: ", vmin, ", \tvmax: ", vmax, ", \t_f_start: ", _f_start, ", \tstart: ", _start)
    println("dticks: ", collect(_start:_dt.delta:vmax))
    return collect(_start:_dt.delta:vmax)
end
println("\n--- figure: -------------------------------------------------------------------------------\n")
# --- plot: 
fig = Figure()
dtick = 1.1
ax = Axis(fig[1,1]; aspect = DataAspect(), xticks = DeltaTicks(dtick), yticks = DeltaTicks(dtick),)

println("\n--- lines: --------------------------------------------------------------------------------\n")

lines!(ax, 
    cumsum(randn(10) .* 3), 
    )

println("\n--- display: ------------------------------------------------------------------------------\n")
# --- explanation: 
# --- to plot / display the the figure, the axis object has to astablished, during this process  
# --- the function DeltaTicks() is called several times inside the axis definition / declaration.
display(fig)

