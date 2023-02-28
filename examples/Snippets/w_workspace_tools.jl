# --- workspace tools, e.g. evailable variables

# *******************************************************************************************************************************
# --- display available moduls (alternative to "varinfo()"):
Base.@show filter(n -> isa(getfield(Main, n), Module), Base.names(Main)) 
# --- display variables (all but moduls):
Base.@show filter(n -> !isa(getfield(Main, n), Module), Base.names(Main)) 
# --- source: https://discourse.julialang.org/t/list-existing-global-variables-e-g-via-varinfo/95124/2
