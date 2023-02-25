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
if VERSION >= v"1.7.0"
    using LLVMExtra_jll
end

# ---
# variable_list() = filter(n -> !isa(getfield(Main, n), Module), Base.names(Main))

function julia_main()::Cint
    println("--- julia_main ---")
    @show ARGS
    @show Base.PROGRAM_FILE
    @show DEPOT_PATH
    @show LOAD_PATH
    @show pwd()
    @show Base.active_project()
    @show Sys.BINDIR

    @show Base.JLOptions().opt_level
    @show Base.JLOptions().nthreads
    @show Base.JLOptions().check_bounds

    display(Base.loaded_modules)
    println('-'^100)
    # --- do some real things, build variables and write data in a new folder:
    root_dir, _     = Base.Filesystem.splitdir(Sys.BINDIR)
    input_dir       = Base.Filesystem.joinpath(root_dir, "input_files")
    data_file_name  = Base.Filesystem.joinpath(input_dir, "template.toml")
    println("---  mkpath($input_dir) --------------------------------")
    try
        Base.Filesystem.mkpath(input_dir)        
    catch
        Base.invokelatest(Base.display_error, Base.catch_stack())
    end
    # ---
    _template_data = Dict(
          "names" => ["Julia", "Julio"],
          "age" => [10, 20],
       );    
    # ---
    println("---  write toml-file ($data_file_name) --------------------------------")
    try
        if ispath(input_dir)
            if ~Base.Filesystem.isfile(data_file_name)
                Base.open(data_file_name, "w") do io
                    TOML.print(io, _template_data)
                end
                println("---  toml-file \"$data_file_name\" written. -------------------------")
            end
        else
            @warn("Input path \"$input_dir\" does not exist!")
        end            
    catch
        Base.invokelatest(Base.display_error, Base.catch_stack())
    end
    # --- call function: real_main():
    try
        println("\n --- Call of \"real_main\": --------------------------------------------")
        if isempty(ARGS)
            real_main(string("Tulip Version: v", Tulip.version()))
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
    Base.@info("--- Exit \"__init__()\" ---------------------------------------- \n ")
    return
end

# --- end module ----------------------------------------------------------------------------------------------------------------
end # module
