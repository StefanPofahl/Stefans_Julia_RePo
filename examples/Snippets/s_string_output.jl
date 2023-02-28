# --- snippets around string output:

# --- formated output of numeric vectors: ---

# --- source: https://discourse.julialang.org/t/how-to-repeat-the-format-in-printf/66695/27
z_complex = ComplexF64[0.0192023 + 6.406656e-6im, 0.0191242 - 8.276627e-5im, 0.0190921 - 0.0001089im]
# --- with Printf:
println([@sprintf("%.3f, %.3fim", real(v), imag(v)) for v in z_complex]...)

# --- written as function for vectors with real numbers:
print_vec(x_vec) =  println([@sprintf("%.6g, ", v) for v in x_vec]...)
print_vec(real(z_complex))

# --- other methods:
println(string([@sprintf("%.3f", v) for v in rand(4)])[2:end-1])
println(round.(z_complex; digits = 4 ))
println(["$v " for v in z_complex])
Printf.format.(Ref(Printf.Format("%.3f")), real.(z_complex))


