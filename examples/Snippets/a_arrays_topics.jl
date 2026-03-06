#: ------------------------------------------------------------------------------------------------
#: Regular topics around arrays:
#: ------------------------------------------------------------------------------------------------

vec_a = [1, 2, 4, -2, 3]
println("Given is vector \"vec_a\": $vec_a")
#: ---
indx_min = findfirst(==(minimum(vec_a)), vec_a)
a_min = vec_a[findfirst(==(minimum(vec_a)), vec_a)]
a_min2 = minimum(vec_a)
println("Index of min value inside vector \"vec_a\": $indx_min, min value: $a_min")

#: --- declaration of a typespecific array:
vec_b = collect(UInt8, range(3, 3, 5));
println("Type of \"vec_b\": $(typeof(vec_b))") 
#: --- vector with oscillating value:
_time_vec = [1,2,3,4,5,1,2,3,4,6,1,2,3,4,5]
_indx_t_min = findfirst(==(minimum(_time_vec)), _time_vec)
_indx_t_max = findfirst(==(maximum(_time_vec[_indx_t_min:end])), _time_vec[_indx_t_min:end]) + _indx_t_min - 1

println("t_min  @: $_indx_t_min = $(_time_vec[_indx_t_min]), t_max @: $_indx_t_max = $(_time_vec[_indx_t_max])")

#: --- check if vector contains non-String elements:
m = [nothing, "a", "b"]
if all(isa.(m, AbstractString))
    println("Strings Only! ")
else
    println("Some Non-String-Elements! ")
end

#: --- Exportiere String-Vektor als Zahlenvektor:
v = [" 0 ", "1.5", "abc", "3.7"]
result = map(x -> something(tryparse(Float64, x), missing), v)

#: --- Test if one element is non-Float64:
m = [1.0, 2.0, 3.0, nothing, 4.0]
for (i, s) in enumerate(m)
    if !isa(m[i], Float64)
        println("#$i, s: \"$s\"")
    end
end
A = (.!isa.(m, Float64))
B = (isa.(m, Float64))
println("A: $A, B: $B")
xNonFloatFound_A = any(.!isa.(m, Float64))
xNonFloatFound_B = !all(isa.(m, Float64))
if xNonFloatFound_A
    println("Vector contains non-Float64-Elements! xNonFloatFound_A: $xNonFloatFound_A, xNonFloatFound_B: $xNonFloatFound_B ")
end

#: --- convert string vector => number vector (works fine with "dot" and "comma" as decimal delimiter): 
data_vec = ["1,0", "2,0", "3,0", missing, "4,0"]
data_converted = tryparse.(Float64, replace.(skipmissing(data_vec), ',' => '.'))






