#: --- My Julia startup.jl ------------------------------------------------------------------------
#: To determine the location of the default loacation of the "startup.jl" on your system do:
#: Default folder is located above first entry in package depot path
# println("loaction of your startup.jl: \"$(joinpath([DEPOT_PATH[1], "config", "startup.jl"]))\"") 
#: Note: It meight be that the folder "config" does not yet exit 
#: ---
try
    @eval using Revise  # Optional: for automatic code reloading
catch e
    @info "Revise not available"
end
#: --- Configure plotting to use ElectronDisplay
try
    @eval using ElectronDisplay
    ElectronDisplay.CONFIG.focus = false  # Don't steal window focus
    @info "ElectronDisplay loaded for plot windows"
catch e
    @warn "ElectronDisplay not available for plot windows"
end

#: --- Set environment variable to control plotting behavior
ENV["GKSwstype"] = "100"  # Can help with some display backends

#: --- Optional: Precompile often-used packages for faster startup
@eval begin
    if Base.isfile(joinpath(DEPOT_PATH[1], "compiled", "v$(VERSION.major).$(VERSION.minor)", "Preferences.ji"))
        @info "Precompiled packages available"
    end
end
