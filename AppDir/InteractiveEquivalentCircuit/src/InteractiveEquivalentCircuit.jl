# --------------------------------------------------------------------------------------------------------------------------
# packages that need to be installed:
# using Pkg; Pkg.rm("EquivalentCircuits"); Pkg.add(url="https://github.com/MaximeVH/EquivalentCircuits.jl.git#master")
# using Pkg; Pkg.add("GLMakie")
# using Pkg; Pkg.add("LLVMExtra_jll")
# using Pkg; Pkg.add("PackageCompiler")
# using Pkg; Pkg.add("Artifacts")
# using Pkg; Pkg.add("micromamba_jll")
# Pkg> add PackageCompiler@v2.1.4
# --------------------------------------------------------------------------------------------------------------------------
module InteractiveEquivalentCircuit

using Artifacts
using EquivalentCircuits 
using GLMakie 

if VERSION >= v"1.7.0"
    using LLVMExtra_jll
end

using micromamba_jll

const outputo = begin
    o = Base.JLOptions().outputo
    o == C_NULL ? "ok" : unsafe_string(o)
end

fooifier_path() = joinpath(artifact"fooifier", "bin", "fooifier" * (Sys.iswindows() ? ".exe" : ""))

function julia_main()::Cint
    try
        display(real_main())
    catch
        Base.invokelatest(Base.display_error, Base.catch_stack())
        return 1
    end
    return 0
end

if VERSION >= v"1.7.0"
    if isfile(LLVMExtra_jll.libLLVMExtra_path)
        println("LLVMExtra path: ok!")
    else
        println("LLVMExtra path: fail!")
    end
end

if isfile(micromamba_jll.micromamba_path)
    println("micromamba_jll path: ok!")
else
    println("micromamba_jll path: fail!")
end

if abspath(PROGRAM_FILE) == @__FILE__
    real_main()
end

function real_main()
    if abspath(PROGRAM_FILE) == @__FILE__
        real_main()
    end
    println("function real_main(): Hello World!")
    # --- measured values: -------------------------------------------------------------------------------------------------
    frequ_data = [0.0199553, 0.0251206, 0.0316296, 0.0398258, 0.0501337, 0.0631739, 0.0794492, 0.1001603, 0.1260081, 0.1588983, 
        0.2003205, 0.2520161, 0.316723, 0.400641, 0.5040323, 0.6334459, 0.7923428, 0.999041, 1.266892, 1.584686, 1.998082, 
        2.504006, 3.158693, 3.945707, 5.008013, 6.317385, 7.944915, 9.93114, 12.40079, 15.625, 19.86229, 24.93351, 31.25, 
        38.42213, 50.22321, 63.3446, 79.00281, 100.4464, 125.558, 158.3615, 198.6229, 252.4038, 315.5048, 397.9953, 505.5147, 
        627.7902, 796.875, 998.264, 1265.625, 1577.524, 1976.103, 2527.573]
    Z_data = ComplexF64[0.0192023 + 6.406656e-6im, 0.0191242 - 8.276627e-5im, 0.0190921 - 0.0001089im, 0.0190038 - 0.0001645im, 
        0.0189117 - 0.0002133im, 0.0188934 - 0.0002243im, 0.0188256 - 0.0002757im, 0.0187806 - 0.0003211im, 0.0187788 - 0.0003745im, 
        0.018721 - 0.0004454im, 0.0186957 - 0.0005298im, 0.0186338 - 0.0006171im, 0.0185409 - 0.0007205im, 0.0184303 - 0.0008409im, 
        0.0182806 - 0.0009458im, 0.0181321 - 0.0010522im, 0.0179509 - 0.0011472im, 0.017754 - 0.0012429im, 0.0175502 - 0.0013275im, 
        0.0173766 - 0.0014186im, 0.0171844 - 0.0015215im, 0.0169962 - 0.0016264im, 0.0167821 - 0.0017693im, 0.0165568 - 0.0019212im, 
        0.0162894 - 0.0021114im, 0.0160016 - 0.0023279im, 0.0156597 - 0.002562im, 0.0152661 - 0.0027968im, 0.0147982 - 0.0030195im, 
        0.0142456 - 0.0032134im, 0.0136019 - 0.00335im, 0.0129721 - 0.0033938im, 0.0123483 - 0.0033619im, 0.0118009 - 0.0032698im, 
        0.011152 - 0.0030826im, 0.010654 - 0.0028835im, 0.0102355 - 0.0026797im, 0.0098378 - 0.0024579im, 0.0095112 - 0.0022581im, 
        0.0092073 - 0.0020614im, 0.0089405 - 0.0018805im, 0.0086829 - 0.0017002im, 0.0084644 - 0.0015397im, 0.0082576 - 0.0013784im, 
        0.0080616 - 0.0012167im, 0.0078987 - 0.0010697im, 0.0077369 - 0.0009059im, 0.0075978 - 0.0007438im, 0.0074675 - 0.0005658im, 
        0.0073608 - 0.0003879im, 0.0072638 - 0.0001883im, 0.0071759 + 5.594581e-5im]  
    x_ref = real(Z_data)
    y_ref = imag(Z_data)
        
    # --- generate frequency vector with n_elements with the same range_data as given in the measurement: ----------------------
    n_elements = 100
    # frequ_vec_all   = exp10.(LinRange(log10(frequ_data_all[1].val, log10(frequ_data_all[end].val, n_elements))
    frequ_vec       = exp10.(LinRange(log10(frequ_data[1]), log10(frequ_data[end]), n_elements))

    # --- Equivalent Circuit Model: "R1-L2-[P3,R4]-[P5,R6]-[P7,R8]": -----------------------------------------------------------
    ecirc_strg = "R1-L2-[P3,R4]-[P5,R6]-[P7,R8]"
    R1_ref    = 0.007031                                          # Gamry: HFR
    L2_ref    = 0.00000004257                                     # Gamry: Lstray
    # ---
    P3w_ref   = 149.9;                  P3n_ref   = 0.9763        # Gamry: Q_3, a_3
    R4_ref    = 0.00132                                           # Gamry: R_3
    # ---
    P5w_ref   = 1.948;                  P5n_ref   = 0.7817        # Gamry: Q_2, a_2
    R6_ref    = 0.009341                                          # Gamry: R2
    # ---
    P7w_ref   = 0.2224;                 P7n_ref   = 9.97E-01      # Gamry: Q_1, a_1
    R8_ref    = 0.001118                                          # Gamry: R_1

    # --- interactive plotting: ------------------------------------------------------------------------------------------------ 
    fig = Figure(resolution= (1500, 600))
    ax = Axis(fig[1, 1], title = ecirc_strg, xlabel = L"\text{z_{real}}", ylabel = L"\text{z_{imag}}", aspect=DataAspect(),)

    # --- function parameters must be of type "Observable": --------------------------------------------------------------------
    obs_ = [Observable(0.0) for s in 1:11]

    function imp_values(_circ_strg, _frequ, _R1, _L2, _P3w, _P3n, _R4, _P5w, _P5n, _R6, _P7w, _P7n, _R8 )
        _EC_params   = (R1 = _R1, L2 = _L2, P3w = _P3w, P3n = _P3n, R4 = _R4, P5w = _P5w, P5n = _P5n, R6 = _R6, P7w = _P7w, P7n = _P7n, R8 = _R8)
        _circfunc_EC = EquivalentCircuits.circuitfunction(_circ_strg)
        return EquivalentCircuits.simulateimpedance_noiseless(_circfunc_EC, _EC_params, _frequ)
    end

    # --- about makro @lift(): https://docs.makie.org/stable/documentation/nodes/index.html#shorthand_macro_for_lift
    Z_sim_data = @lift(imp_values(ecirc_strg, frequ_data, $(obs_[1]), $(obs_[2]), $(obs_[3]), $(obs_[4]), $(obs_[5]), $(obs_[6]), $(obs_[7]), $(obs_[8]), $(obs_[9]), $(obs_[10]), $(obs_[11]) ))
    x_ = @lift(real($Z_sim_data))
    y_ = @lift(imag($Z_sim_data))

    sg = SliderGrid(
        fig[1, 2],
        (label = "R1",  range = 0: 0.01*R1_ref:     10*R1_ref,  format = "{:.1e}Ω",     startvalue = R1_ref),
        (label = "L2",  range = 0: 0.01*L2_ref:     2*L2_ref,   format = "{:.1e}H",     startvalue = L2_ref),
        (label = "P3w", range = 0: 0.01*P3w_ref:    2*P3w_ref,  format = "{:.1e}S*s^n", startvalue = P3w_ref),
        (label = "P3n", range = 0: 0.01*P3n_ref:    2*P3n_ref,  format = "{:.1e}-",     startvalue = P3n_ref),
        (label = "R4",  range = 0: 0.01*R4_ref:     2*R4_ref,   format = "{:.1e}Ω",     startvalue = R4_ref),
        (label = "P5w", range = 0: 0.01*P5w_ref:    2*P5w_ref,  format = "{:.1e}S*s^n", startvalue = P5w_ref),
        (label = "P5n", range = 0: 0.01*P5n_ref:    2*P5n_ref,  format = "{:.1e}-",     startvalue = P5n_ref),
        (label = "R6",  range = 0: 0.01*R6_ref:     2*R6_ref,   format = "{:.1e}Ω",     startvalue = R6_ref),
        (label = "P7w", range = 0: 0.01*P7w_ref:    2*P7w_ref,  format = "{:.1e}S*s^n", startvalue = P7w_ref),
        (label = "P7n", range = 0: 0.01*P7n_ref:    2*P7n_ref,  format = "{:.1e}-",     startvalue = P7n_ref),
        (label = "R8",  range = 0: 0.01*R8_ref:     2*R8_ref,   format = "{:.1e}Ω",     startvalue = R8_ref),
        width = 350,
        tellheight = false)


    sliderobservables = [s.value for s in sg.sliders]  

    # --- link sliders to container: "obs_" ------------------------------------------------------------------------------------
    for (_i, _object) in enumerate(obs_)
        connect!(_object, sliderobservables[_i])
    end

    # --- important: at least one plot variable must be of type: "Observable", in this case "x_" and "y_" are both of this type.
    scatter!(ax, x_ref, y_ref)
    lines!(ax, x_, y_)

    # colsize!(fig.layout, 1, Aspect(1, /(ax.finallimits[].widths...)))
    # resize_to_layout!(fig)
    # --- 
    return fig
end # --- end function ---

end # module
