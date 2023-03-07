# ----------------------------------------------------------------------------------------------------------------------------- #
# --- MyAppHelloTulip is spme kind of "HelloWorld" code example, inspired by:                                                   #
# --- https://github.com/JuliaLang/PackageCompiler.jl/blob/master/examples/MyApp/src/MyApp.jl                                   #
# --- For further information, please relay on the "PackageCompiler"-Manual:                                                    #
# --- https://julialang.github.io/PackageCompiler.jl/stable/apps.html                                                           #
# ... ......................................................................................................................... #
# --- further information, e.g. about "__init__():                                                                              #
# --- https://docs.julialang.org/en/v1/manual/modules/#Module-initialization-and-precompilation                                 #
# ... ......................................................................................................................... #
# --- Motivation:                                                                                                               #
# --- The package "Tulip" before Version v0.9.5 violated the relocatability criteria, see:                                      #
# --- https://discourse.julialang.org/t/missing-relocatability-of-tulip/94886/16                                                #
# --- for historical reasons this example stays in my collection and does not change its name.                                  #
# ... ......................................................................................................................... #
# --- New focus:                                                                                                                #
# --- Add the feature of configuration via TOML-file, please refer to the TOML-manual for further information:                  #
# --- https://docs.julialang.org/en/v1/stdlib/TOML/                                                                             #
# ############################################################################################################################# #

module MyAppHelloTulip
import Tulip, TOML
# --- constants:
const PROJECTVERSION = let 
    project_toml = joinpath(@__DIR__, "..", "Project.toml")
    Base.include_dependency(project_toml)
    VersionNumber(TOML.parsefile(project_toml)["version"])
end

const PROJECTNAME = let 
    project_toml = joinpath(@__DIR__, "..", "Project.toml")
    Base.include_dependency(project_toml)
    TOML.parsefile(project_toml)["name"]
end

# --- functions:
version() = PROJECTVERSION

function julia_main()::Cint
    # --- call function: real_main():
    @info("\n --- Call of \"real_main\": -------------------------------------------- \n ")
    try
        if isempty(ARGS)
            real_main(string("Projectname: \"$PROJECTNAME\", Projectversion: \"$PROJECTVERSION\", Tulip Version: v", Tulip.version()))
        else
            real_main(ARGS[1])
        end
    catch
        Base.invokelatest(Base.display_error, Base.catch_stack())
        return 1 
    end
    # ---
    return 0 # if things finished successfully
end                                                                               
  
function real_main(_s::AbstractString="Hello Julia!") 
    @info("\n ----   Enter   ----   real_main()  ------- \n ")
    @show ARGS
    return println(_s)
end

function __init__()
    # --- mainly to show that there is limited access to modules and built in variables at initial phase. ---
    Base.@info("--- Enter \"__init__()\" ---------------------------------------- \n ")
    Base.@show Base.PROGRAM_FILE
    Base.@show Sys.BINDIR
    println('-'^100)
    Base.@show filter(n -> isa(getfield(Main, n), Module), Base.names(Main))
    println('-'^100)
    Base.@show filter(n -> !isa(getfield(Main, n), Module), Base.names(Main))
    println('-'^100)    
    Base.@info("--- \"__init__()\" \"Base.loaded_modules\" --------------------- \n ")
    display(Base.loaded_modules)
    println()
    Base.@info("--- Exit \"__init__()\" ---------------------------------------- \n ")
    return
end

# --- end module ----------------------------------------------------------------------------------------------------------------
end # module
