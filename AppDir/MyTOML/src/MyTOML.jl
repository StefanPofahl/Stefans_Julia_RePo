module MyTOML
import TOML
# ******************************************************************************************************************** #
# ---  Lesson learned:                                                                                                 #
# ---  In the curren Julia Versions: v1.6.7 & V1.8.5 the following applies:                                            #
# ---  inside functions for output variables inside try-catch these variables need to be declared inside the function  #
# ---  outside the try-catch structure. In this code that applies to the variable "toml_content" inside the function   #
# ---  real_main().                                                                                                    #
# ******************************************************************************************************************** #
# --- constants:
const TEMPLATE_DATA = Dict(
    "names" => ["Julia", "Julio"],
    "age" => [10, 20],
 );  
# --- entry point ---
function julia_main()::Cint
    # --- call function: real_main():
    try
        real_main()
    catch
        Base.invokelatest(Base.display_error, Base.catch_stack())
        return 1 
    end
    # ---
    return 0 # if things finished successfully
end                                                                               
# --- do some stuff ---
function real_main()
    global toml_content = []
    @info(" ----- enter \"real_main()\" ------ ")
    root_dir, _ = Base.Filesystem.splitdir(Sys.BINDIR)
    fn_toml     = Base.Filesystem.joinpath(root_dir, "data.toml")
    @show fn_toml
    println(" ----- write to \"data.toml\" ------ ")
    try
        Base.open(fn_toml, "w") do io 
            TOML.print(io, TEMPLATE_DATA)
        end
    catch
        Base.invokelatest(Base.display_error, Base.catch_stack())
    end
    println(" ----- read content of \"data.toml\" as string ------ ")
    try
        @show read(fn_toml, String)
    catch
        Base.invokelatest(Base.display_error, Base.catch_stack())
    end

    println(" ----- read content of \"data.toml\" inside try-catch via \"tryparsefile()\" ------ ")
    try
        toml_content = TOML.tryparsefile(fn_toml)
    catch
        Base.invokelatest(Base.display_error, Base.catch_stack())
    end
    @show toml_content 

    println(" ----- read content of \"data.toml\" inside try-catch via \"parsefile()\" ------ ")
    try
        toml_content = TOML.parsefile(fn_toml)
    catch
        Base.invokelatest(Base.display_error, Base.catch_stack())
    end
    @show toml_content 

    println(" ----- read content of \"data.toml\" outside try-catch via \"parsefile()\" ------ ")
    toml_content = TOML.parsefile(fn_toml)
    @show toml_content 

    println(" ----- read content of \"data.toml\" outside try-catch via \"tryparsefile()\" ------ ")
    toml_content = TOML.tryparsefile(fn_toml)
    @show toml_content 

    println();     @info(" ----- exit \"real_main()\" ------ ")
end

end # module
