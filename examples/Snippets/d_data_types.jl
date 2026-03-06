#: ─────────────────────────────────────────────────────────────────────────
#: Handling and Analysis of data types.
#: ─────────────────────────────────────────────────────────────────────────
#: --- Union-Type Variables:
m = [1.0, 2.0, 3.0, nothing, 4.0]
n::Union{Nothing, Float64} = nothing
o::Union{Nothing, Float64} = 1.0

println("m[4]: $(m[4]), isa(m[4], Float64): $(isa(m[4], Float64)), typeof(m[4]): $(typeof(m[4]))")

println("typeof(n): $(typeof(n)), typeof(o): $(typeof(o))")
println("typeof(m): $(typeof(m)), typeof(m[4]): $(typeof(m[4]))")