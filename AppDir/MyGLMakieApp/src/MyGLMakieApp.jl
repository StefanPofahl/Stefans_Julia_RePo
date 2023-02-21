module MyGLMakieApp

# --- preface: ----------------------------------------------------------------------------------------------------------- #
# --- please follow the instractions of the manual of "PackageCompiler":                                                   #
# --- https://julialang.github.io/PackageCompiler.jl/stable/apps.html                                                      #
# --- For PackageCompiler v2.1.5 the compile command should be:                                                            #
# --- julia> using PackageCompiler                                                                                         #
# --- julia> create_app("MyGLMakieApp", "MyAppCompiled"; incremental= true, force= true, include_lazy_artifacts= true)     #
# ... ... address of my fork: ............................................................................................ #
# ... https://github.com/StefanPofahl/Tulip.jl
# ... install from this fork:
# --- import Pkg; Pkg.add()
# ... .................................................................................................................... #


using GLMakie
# --- remark: ------------------------------------------------------------------------------------------------------------ #
# --- all packages that loaded inside this module must be included in the "Project.toml" of this Application Project       #
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

# --- this is the real main function, which is called inside "julia_main()": -----------------------------------------------
function real_main()
    println("real_main(): Hello World!")
    # ---
    fig = Figure()

    ax = Axis(fig[1, 1])

    sg = SliderGrid(
        fig[1, 2],
        (label = "Voltage", range = 0:0.1:10, format = "{:.1f}V", startvalue = 5.3),
        (label = "Current", range = 0:0.1:20, format = "{:.1f}A", startvalue = 10.2),
        (label = "Resistance", range = 0:0.1:30, format = "{:.1f}Ω", startvalue = 15.9),
        width = 350,
        tellheight = false)

    sliderobservables = [s.value for s in sg.sliders]
    bars = lift(sliderobservables...) do slvalues...
        [slvalues...]
    end

    barplot!(ax, bars, color = [:yellow, :orange, :red])
    ylims!(ax, 0, 30)

    # --- https://discourse.julialang.org/t/makie-app-from-command-line/53890/5
    gl_screen = display(fig)
    wait(gl_screen)
    # ---
    return
end

end # module MyGLMakieApp
