module InteractiveNyquist
include("MyCircuitFunction.jl")
using GLMakie, RobustModels, Printf
import Tulip

Tulip.__init__();
# --- remark: ------------------------------------------------------------------------------------------------------------ #
# --- all packages that are loaded inside this module must be included in the "Project.toml" of this Application Project   #
# ... .................................................................................................................... #

# --- mandatory function "julia_main()": -----------------------------------------------------------------------------------
function julia_main()::Cint 
    try
        real_main()
    catch
        Base.invokelatest(Base.display_error, Base.catch_stack())
        return 1
    end
    return 0
end

# --- function DeltaTicks(dtick): ---------------------------------------------------------------------------------------- #
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
# --- necessary to enable function: DeltaTicks()
function GLMakie.Makie.get_tickvalues(_dt::DeltaTicks, ::Any, vmin, vmax)
    _f_start = ceil((vmin - _dt.offset) / _dt.delta)
    _start = _dt.offset + _f_start * _dt.delta
    return collect(_start:_dt.delta:vmax)
end
# --- end DeltaTicks() -----------------------------------------------------------------------------------------------------


# --- this is the real main function, which is called inside "julia_main()": -----------------------------------------------
function real_main()
    # --- measured values: -------------------------------------------------------------------------------------------------
    frequ_data = [0.0199553, 0.0251206, 0.0316296, 0.0398258, 0.0501337, 0.0631739, 0.0794492, 0.1001603, 0.1260081, 0.1588983, 
        0.2003205, 0.2520161, 0.316723, 0.400641, 0.5040323, 0.6334459, 0.7923428, 0.999041, 1.266892, 1.584686, 1.998082, 
        2.504006, 3.158693, 3.945707, 5.008013, 6.317385, 7.944915, 9.93114, 12.40079, 15.625, 19.86229, 24.93351, 31.25, 
        38.42213, 50.22321, 63.3446, 79.00281, 100.4464, 125.558, 158.3615, 198.6229, 252.4038, 315.5048, 397.9953, 505.5147, 
        627.7902, 796.875, 998.264, 1265.625, 1577.524, 1976.103, 2527.573]

    Z_data = ComplexF64[0.9814697912245967 - 0.0037228131590371894im, 0.9812805807383405 - 0.004541817311026915im, 
        0.9810437691249618 - 0.005545286937042057im, 0.9807439778191548 - 0.006773931551470225im, 0.9803595778877165 - 0.008275929086694679im, 
        0.9798559522934699 - 0.010121031228449179im, 0.9791942396150454 - 0.012352908512991463im, 0.9782930839600954 - 0.01509548153523514im, 
        0.9770718096573817 - 0.018380445339277213im, 0.975365535083125 - 0.022351663962338727im, 0.9729941725770648 - 0.027026350797889443im, 
        0.9697450049433056 - 0.03234827459977607im, 0.9653574004471115 - 0.03821250646524921im, 0.9594106323357426 - 0.04455919164804537im, 
        0.9521251303395071 - 0.05065952707397996im, 0.9436150305790347 - 0.05620940341192938im, 0.9345015730138716 - 0.060900481864809765im, 
        0.9248088105890082 - 0.065075600671394im, 0.9150406251320378 - 0.06909619659866516im, 0.906074046441051 - 0.07323386239214587im, 
        0.8968000092157945 - 0.07842611441950355im, 0.8873612498406966 - 0.08472823436853534im, 0.8766966349427485 - 0.09266893007361414im, 
        0.8650620144143906 - 0.10164345177037322im, 0.8505056931889721 - 0.1125530811610637im, 0.8337613003730493 - 0.1241012397136905im, 
        0.8143789128055314 - 0.1358625203233807im, 0.792579368446722 - 0.14701938572720907im, 0.7680147071972325 - 0.15711017826147636im, 
        0.7396893337971248 - 0.1657213462821573im, 0.7079415622643752 - 0.17179249645453626im, 0.676552652542632 - 0.17426744660285395im, 
        0.6451613683886926 - 0.17332223040897865im, 0.6171293092305955 - 0.16957581484858758im, 0.5829422876305477 - 0.16117924545169507im, 
        0.5560627948656406 - 0.15146286390152233im, 0.5332226186731637 - 0.1409170389640344im, 0.5114829653350961 - 0.1288449827762636im, 
        0.4939833593856589 - 0.11770576032438315im, 0.4781784078527428 - 0.10668963480838624im, 0.4646695476865268 - 0.09677580719404014im, 
        0.45192845274933935 - 0.08727373331793545im, 0.4410719645441521 - 0.07922589038903646im, 0.4304785560153798 - 0.07139711003732342im, 
        0.4201572713674723 - 0.06352977408827129im, 0.4113425966574627 - 0.056232475166844im, 0.40239676915697875 - 0.04773107296298696im, 
        0.39487964994816266 - 0.03912064920564358im, 0.3881066173087768 - 0.029425058931592557im, 0.3829084880809682 - 0.01986438882326411im, 
        0.37861399237183796 - 0.009498772031665036im, 0.3749485995402947 + 0.0026642817458245784im]

    x_ref = real(Z_data)
    y_ref = imag(Z_data)
        
    # --- generate frequency vector with n_elements with the same range_data as given in the measurement: ----------------------
    n_elements = 100
    frequ_vec  = exp10.(LinRange(log10(frequ_data[1]), log10(frequ_data[end]), n_elements))

    # --- Equivalent Circuit Model: "R1-L2-[P3,R4]-[P5,R6]-[P7,R8]": -----------------------------------------------------------
    ecirc_strg = "R1-L2-[P3,R4]-[P5,R6]-[P7,R8]"
    ecirc_strg_PR = "R1-L2-[P3,R4]"
    # ---
    R1_ref    = 0.3627398
    L2_ref    = 1.9482112e-6 
    # --- [PR1]:
    P3w_ref   = 0.0088869;              P3n_ref = 0.913665 
    R4_ref    = 0.0567510 
    # --- [PR2]:
    P5w_ref   = 0.0421738;              P5n_ref = 0.756012
    R6_ref    = 0.5040666 
    # --- [PR3]:
    P7w_ref   = 3.8225318;              P7n_ref = 0.999479  
    R8_ref    = 0.0588018 

    # --- local functions: ------------------------------------------------------------------------------------------------------
    function _simulateimpedance_noiseless(circuitfunc, parameters, frequencies) 
        return [circuitfunc(parameters, fr) for fr in frequencies] 
    end

    # --- The fitting errors calculated using the modulus weighted objective function,
    # --- you can adjust the function to see other fitting quality metrics (e.g. removal of the denominator gives the MSE). 
    function quality_func(_Z_measured, _Z_simulated)
        return mean((abs.(_Z_measured - _Z_simulated).^2)./(abs.(_Z_measured).^2 .+ abs.(_Z_simulated).^2))
    end
    # ---
    function imp_values(_circ_strg, _frequ, _R1, _L2, _P3w, _P3n, _R4, _P5w, _P5n, _R6, _P7w, _P7n, _R8 )
        _EC_params = (R1 = _R1, L2 = _L2, P3w = _P3w, P3n = _P3n, R4 = _R4, P5w = _P5w, P5n = _P5n, R6 = _R6, P7w = _P7w, P7n = _P7n, R8 = _R8)
        _circfunc_EC = My_circuitfunction(_circ_strg)        
        return _simulateimpedance_noiseless(_circfunc_EC, _EC_params, _frequ)
    end

    function imp_values_RP(_circ_strg, _frequ, _R1, _L2, _P3w, _P3n, _R4 )
        _EC_params = (R1 = _R1, L2 = _L2, P3w = _P3w, P3n = _P3n, R4 = _R4)
        _circfunc_EC = My_circuitfunction(_circ_strg)        
        return _simulateimpedance_noiseless(_circfunc_EC, _EC_params, _frequ)
    end

# --- interactive plotting: -----------------------------------------------------------------------------------------------------
    Δtick       = 0.05 
    fig_height  = 700; height_top = round(Int, 0.7 * fig_height)
    rgb1 = RGBf(0.2, 0.7, 0.9); rgb2 = RGBf(0.7, 0.2, 0.9); rgb3 = RGBf(0.2, 0.9, 0.1); cbutton = RGBf(0.92, 0.92, 0.92)

    # --- open figure object:
    fig = Figure(resolution = (1400, fig_height))

    # --- RC time constant / cut-off frequencies: -------------------------------------------------------------------------------
    # --- https://en.wikipedia.org/wiki/RC_time_constant
    fc_PR1_ref = 1 / (2*π* P3w_ref * R4_ref)
    fc_PR2_ref = 1 / (2*π* P5w_ref * R6_ref)
    fc_PR3_ref = 1 / (2*π* P7w_ref * R8_ref)
    # println(@sprintf("cut-off trequencies, fc_PR1_ref: \t %.3fHz, \t fc_PR2_ref: \t %.3fHz, \t fc_PR3_ref: \t %.3fHz", fc_PR1_ref, fc_PR2_ref, fc_PR3_ref))
    str_fc_PR1_ref = @sprintf("%.3fHz", fc_PR1_ref); str_fc_PR2_ref = @sprintf("%.3fHz", fc_PR2_ref); str_fc_PR3_ref = @sprintf("%.3fHz", fc_PR3_ref); 
    sub_title = @sprintf("cut-off trequencies, PR1_ref: %.3fHz, PR2_ref: %.3fHz, PR3_ref: %.3fHz", fc_PR1_ref, fc_PR2_ref, fc_PR3_ref)
    sub_title = rich("cut-off frequencies: ", 
    rich("PR1", subscript("ref"), ": ", str_fc_PR1_ref, color = rgb1), ", ",
    rich("PR2", subscript("ref"), ": ", str_fc_PR2_ref, color = rgb2), ", ",
    rich("PR3", subscript("ref"), ": ", str_fc_PR3_ref, color = rgb3))

    # --- Impedance points on reference impedance curve @cut-off frequencies of the individual [PR]-circuits: ------------------
    Z_PR1_ref = imp_values(ecirc_strg, fc_PR1_ref, R1_ref, L2_ref, P3w_ref, P3n_ref, R4_ref, P5w_ref, P5n_ref, R6_ref, P7w_ref, P7n_ref, R8_ref )
    x_fc_PR1_ref = real(Z_PR1_ref);         y_fc_PR1_ref = imag(Z_PR1_ref); 

    Z_PR2_ref = imp_values(ecirc_strg, fc_PR2_ref, R1_ref, L2_ref, P3w_ref, P3n_ref, R4_ref, P5w_ref, P5n_ref, R6_ref, P7w_ref, P7n_ref, R8_ref )
    x_fc_PR2_ref = real(Z_PR2_ref);         y_fc_PR2_ref = imag(Z_PR2_ref); 

    Z_PR3_ref = imp_values(ecirc_strg, fc_PR3_ref, R1_ref, L2_ref, P3w_ref, P3n_ref, R4_ref, P5w_ref, P5n_ref, R6_ref, P7w_ref, P7n_ref, R8_ref )
    x_fc_PR3_ref = real(Z_PR3_ref);         y_fc_PR3_ref = imag(Z_PR3_ref); 
    
    # --- function parameters must be of type "Observable": --------------------------------------------------------------------
    obs_R1  = Observable(0.0);  obs_L2  = Observable(0.0);  
    obs_P3w = Observable(0.0);  obs_P3n = Observable(0.0);  obs_R4  = Observable(0.0); 
    obs_P5w = Observable(0.0);  obs_P5n = Observable(0.0);  obs_R6  = Observable(0.0); 
    obs_P7w = Observable(0.0);  obs_P7n = Observable(0.0);  obs_R8  = Observable(0.0); 

    # --- SliderGrid(): ---------------------------------------------------------------------------------------------------------
    sg = SliderGrid( fig[1, 2][1,1],
        (label = "R1",  range = 0: 0.01*R1_ref:     3*R1_ref,  format = "{:.1e}Ω",     startvalue = R1_ref),
        (label = "L2",  range = 0: 0.01*L2_ref:     2*L2_ref,   format = "{:.1e}H",     startvalue = L2_ref),
        (label = rich("P3w", color = rgb1), range = 0: 0.01*P3w_ref:    2*P3w_ref,  format = "{:.1e}S*s^n", startvalue = P3w_ref),
        (label = rich("P3n", color = rgb1), range = 0: 0.01*P3n_ref:    2*P3n_ref,  format = "{:.1e}-",     startvalue = P3n_ref),
        (label = rich("R4",  color = rgb1), range = 0: 0.01*R4_ref:     2*R4_ref,   format = "{:.1e}Ω",     startvalue = R4_ref),
        (label = rich("P5w", color = rgb2), range = 0: 0.01*P5w_ref:    2*P5w_ref,  format = "{:.1e}S*s^n", startvalue = P5w_ref),
        (label = rich("P5n", color = rgb2), range = 0: 0.01*P5n_ref:    2*P5n_ref,  format = "{:.1e}-",     startvalue = P5n_ref),
        (label = rich("R6",  color = rgb2), range = 0: 0.01*R6_ref:     2*R6_ref,   format = "{:.1e}Ω",     startvalue = R6_ref),
        (label = rich("P7w", color = rgb3), range = 0: 0.01*P7w_ref:    2*P7w_ref,  format = "{:.1e}S*s^n", startvalue = P7w_ref),
        (label = rich("P7n", color = rgb3), range = 0: 0.01*P7n_ref:    2*P7n_ref,  format = "{:.1e}-",     startvalue = P7n_ref),
        (label = rich("R8",  color = rgb3), range = 0: 0.01*R8_ref:     2*R8_ref,   format = "{:.1e}Ω",     startvalue = R8_ref),
        width = 350,
        tellheight = false)


    # --- build vector of individual slider values: ----------------------------------------------------------------------------------
    sliderobservables = [s.value for s in sg.sliders]  
    # --- link sliders to container: "obs_XYZ" ------------------------------------------------------------------------------------
    connect!(obs_R1,    sliderobservables[ 1]) 
    connect!(obs_L2,    sliderobservables[ 2]) 
    connect!(obs_P3w,   sliderobservables[ 3]) 
    connect!(obs_P3n,   sliderobservables[ 4]) 
    connect!(obs_R4,    sliderobservables[ 5]) 
    connect!(obs_P5w,   sliderobservables[ 6]) 
    connect!(obs_P5n,   sliderobservables[ 7]) 
    connect!(obs_R6,    sliderobservables[ 8]) 
    connect!(obs_P7w,   sliderobservables[ 9]) 
    connect!(obs_P7n,   sliderobservables[10]) 
    connect!(obs_R8,    sliderobservables[11]) 
    
    # --- definition of common plot axis, it contains a function call to determine the position of equidistant ticks: -----------
    ax = Axis(fig[1, 1][1, 1:2]; height = height_top, valign = :bottom,
        title = ecirc_strg, titlegap = 30.0, 
        subtitle = sub_title,
        xlabel = rich("normalized z", subscript("real"), " / -"), ylabel = rich("inverted normalized z", subscript("imag"), " / -"), 
        aspect=DataAspect(), xticks = DeltaTicks(Δtick), yticks = DeltaTicks(Δtick),
        yreversed = true, tellheight = true, tellwidth = true, 
        )

    # --- reference / measured values (static): ---------------------------------------------------------------------------------
    scatter!(ax, x_ref, y_ref)

    pt_PR1_ref = Point2f(x_fc_PR1_ref[], y_fc_PR1_ref[])
    scatter!(ax, pt_PR1_ref, color = rgb1, markersize = 20)

    pt_PR2_ref = Point2f(x_fc_PR2_ref[], y_fc_PR2_ref[])
    scatter!(ax, pt_PR2_ref, color = rgb2, markersize = 20)

    pt_PR3_ref = Point2f(x_fc_PR3_ref[], y_fc_PR3_ref[])
    scatter!(ax, pt_PR3_ref, color = rgb3, markersize = 20)

    # --- simulated impedance values at current EC-parameter values (dynamic/interactive): --------------------------------------
    # --- about makro @lift(): https://docs.makie.org/stable/documentation/nodes/index.html#shorthand_macro_for_lift
    Z_sim_vec = @lift(imp_values(ecirc_strg, frequ_vec, $(obs_R1), $(obs_L2), $(obs_P3w), $(obs_P3n), $(obs_R4), $(obs_P5w), $(obs_P5n), $(obs_R6), $(obs_P7w), $(obs_P7n), $(obs_R8) ))
    x_ = @lift(real($Z_sim_vec));           y_ = @lift(imag($Z_sim_vec))

    # "R1-L2-[P3,R4]"  (part of: "R1-L2-[P3,R4]-[P5,R6]-[P7,R8]")
    Z_sim_vecRP1 = @lift(imp_values_RP(ecirc_strg_PR, frequ_vec, $(obs_R1), $(obs_L2), $(obs_P3w), $(obs_P3n), $(obs_R4) ))
    x_RP1 = @lift(real($Z_sim_vecRP1));     y_RP1 = @lift(imag($Z_sim_vecRP1))
    # "(R1+R4)-L2-[P5,R6]"  (part of: "R1-L2-[P3,R4]-[P5,R6]-[P7,R8]")
    Z_sim_vecRP2 = @lift(imp_values_RP(ecirc_strg_PR, frequ_vec, $(obs_R1) + $(obs_R4), $(obs_L2), $(obs_P5w), $(obs_P5n), $(obs_R6) ))
    x_RP2 = @lift(real($Z_sim_vecRP2));     y_RP2 = @lift(imag($Z_sim_vecRP2))
    # "(R1+R4+R6)-L2-[P7,R8]"  (part of: "R1-L2-[P3,R4]-[P5,R6]-[P7,R8]")
    Z_sim_vecRP3 = @lift(imp_values_RP(ecirc_strg_PR, frequ_vec, $(obs_R1) + $(obs_R4) + $(obs_R6), $(obs_L2), $(obs_P7w), $(obs_P7n), $(obs_R8) ))
    x_RP3 = @lift(real($Z_sim_vecRP3));     y_RP3 = @lift(imag($Z_sim_vecRP3))

    # --- important: at least one plot variable must be of type: "Observable", in this case "x_" and "y_" are both of this type.
    lines!(ax, x_, y_)
    # --- impedance points @cut-off frequencies: --------------------------------------------------------------------------------
    fc_PR1   = @lift(1 / (2*π* $(obs_P3w) * $(obs_R4)))
    Z_fc_PR1 = @lift(imp_values(ecirc_strg, $(fc_PR1), $(obs_R1), $(obs_L2), $(obs_P3w), $(obs_P3n), $(obs_R4), $(obs_P5w), $(obs_P5n), $(obs_R6), $(obs_P7w), $(obs_P7n), $(obs_R8) ))
    x_PR1    = @lift(real($(Z_fc_PR1)));       y_PR1 = @lift(imag($(Z_fc_PR1)))
    pt_PR1   = @lift[Point2f($(x_PR1)[], $(y_PR1)[])]
    scatter!(ax, pt_PR1, color = rgb1, markersize = 20)
    # ---
    fc_PR2   = @lift(1 / (2*π* $(obs_P5w) * $(obs_R6)))
    Z_fc_PR2 = @lift(imp_values(ecirc_strg, $(fc_PR2), $(obs_R1), $(obs_L2), $(obs_P3w), $(obs_P3n), $(obs_R4), $(obs_P5w), $(obs_P5n), $(obs_R6), $(obs_P7w), $(obs_P7n), $(obs_R8) ))
    x_PR2    = @lift(real($(Z_fc_PR2)));       y_PR2 = @lift(imag($(Z_fc_PR2)))
    pt_PR2   = @lift[Point2f($(x_PR2)[], $(y_PR2)[])]
    scatter!(ax, pt_PR2, color = rgb2, markersize = 20)
    # ---
    fc_PR3   = @lift(1 / (2*π* $(obs_P7w) * $(obs_R8)))
    Z_fc_PR3 = @lift(imp_values(ecirc_strg, $(fc_PR3), $(obs_R1), $(obs_L2), $(obs_P3w), $(obs_P3n), $(obs_R4), $(obs_P5w), $(obs_P5n), $(obs_R6), $(obs_P7w), $(obs_P7n), $(obs_R8) ))
    x_PR3    = @lift(real($(Z_fc_PR3)));       y_PR3 = @lift(imag($(Z_fc_PR3)))
    pt_PR3   = @lift[Point2f($(x_PR3)[], $(y_PR3)[])]
    scatter!(ax, pt_PR3, color = rgb3, markersize = 20)

    # --- set-up label to display current quality / deviation of values from reference impedance values: ------------------------
    Z_sim_data = @lift(imp_values(ecirc_strg, frequ_data , $(obs_R1), $(obs_L2), $(obs_P3w), $(obs_P3n), $(obs_R4), $(obs_P5w), $(obs_P5n), $(obs_R6), $(obs_P7w), $(obs_P7n), $(obs_R8) ))
    # --- round at leftenside digit position 12:
    obs_Q = @lift(round(quality_func($(Observable(Z_data)), $(Z_sim_data)); digits = 12))

    label = lift(obs_Q) do s1
        return string("Q (deviation from original) = ", @sprintf("%.4g", s1))
    end
    
    Label(fig[1, 1][2, 2], label, tellheight = false, tellwidth = false, valign = :top,)
    
    # --- set-up grid of buttons (4 buttons): -----------------------------------------------------------------------------------
    fig[1, 1][2, 1] = buttongrid = GridLayout(tellwidth = false)
    btncolors = [RGBf(1.0, 0.0, 0.4), rgb1, rgb2, rgb3]
    buttonlabels = ["reset", "R1-L2-[P3,R4]", "(R1+R4)-L2-[P5,R6]", "(R1+R4+R6)-L2-[P7,R8]"]
    buttons = buttongrid[1, 1:length(buttonlabels)] = 
        [Button(fig, label = _s, strokewidth = 6, cornerradius = 10, strokecolor = btncolors[_i]) 
                for (_i, _s) in enumerate(buttonlabels) ]
        

    # --- reset all sliders inside SliderGrid "sg": -----------------------------------------------------------------------------
    on(buttons[1].clicks) do n      # n = number of clicks
        for i_slider in sg.sliders
            set_close_to!(i_slider, i_slider.startvalue[])
        end
    end

    # --- three lines for each subplot, first define line colors: ---------------------------------------------------------------
    l1 = []; l2 = []; l3 = [];
    on(buttons[2].clicks) do n_clicks 
        global l1
        if n_clicks == 1
            l1 = lines!(ax, x_RP1, y_RP1, linestyle = :dash, color = rgb1)
        end
        if iseven(n_clicks)
            l1.visible = false
            buttons[2].buttoncolor = cbutton
        else
            l1.visible = true
            buttons[2].buttoncolor = rgb1
        end
    end
    on(buttons[3].clicks) do n_clicks
        global l2
        if n_clicks == 1
            l2 = lines!(ax, x_RP2, y_RP2, linestyle = :dash, color = rgb2)
        end
        if iseven(n_clicks)
            l2.visible = false
            buttons[3].buttoncolor = cbutton
        else
            l2.visible = true
            buttons[3].buttoncolor = rgb2
        end
    end
    on(buttons[4].clicks) do n_clicks
        global l3
        if n_clicks == 1
            l3 = lines!(ax, x_RP3, y_RP3, linestyle = :dash, color = rgb3)
        end
        if iseven(n_clicks)
            l3.visible = false
            buttons[4].buttoncolor = cbutton
        else
            l3.visible = true
            buttons[4].buttoncolor = rgb3
        end
    end
    # ---
    resize_to_layout!(fig)
    # --- 
    # keep window open by "wait(gl_screen)", see:
    # https://discourse.julialang.org/t/makie-app-from-command-line/53890/5
    gl_screen = display(fig)
    wait(gl_screen)
    # ---
    return 
end # --- end function real_main() ------------------------------------------------------------------------------------------



# ###########################################################################################################################
end # module
# ###########################################################################################################################
