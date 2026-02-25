#: ------------------------------------------------------------------------------------------------
#: Regular topics around arrays:
#: ------------------------------------------------------------------------------------------------

vec_a = [1, 2, 4, -2, 3]
println("Given is vector \"vec_a\": $vec_a")
#: ---
indx_min = findfirst(==(minimum(vec_a)), vec_a)
a_min = vec_a[findfirst(==(minimum(vec_a)), vec_a)]
a_min2 = maximum(vec_a)
println("Index of min value inside vector \"vec_a\": $indx_min, min value: $a_min")
#: --- declaration of a typespecific array:
vec_b = collect(UInt8, range(3, 3, 5));
println("Type of \"vec_b\": $(typeof(vec_b))") 

