# ----------------------------------------------------------------------------------------------------------------------------- #
# --- An example utilizing *.toml-configuration files.                                                                          #
# --- https://docs.julialang.org/en/v1/stdlib/TOML/                                                                             #
# ############################################################################################################################# #

# ******************************************************************************************************************** #
# ---  Lesson learned:                                                                                                 #
# ---  In the curren Julia Versions: v1.6.7 & V1.8.5 the following applies:                                            #
# ---  inside functions for output variables inside try-catch these variables need to be declared inside the function  #
# ---  outside the try-catch structure. In this code that applies to the variable "toml_content" inside the function   #
# ---  real_main().                                                                                                    #
# ******************************************************************************************************************** #

module MyAppReadToml
using TOML, InteractiveUtils, DelimitedFiles
# if VERSION >= v"1.7.0" && false  # currently not needed.
#     using LLVMExtra_jll
# end

# --- constants:
const TEMPLATE_DATA = Dict(
    "names" => ["Julia", "Julio"],
    "age" => [10, 20],
 );  
# --- initialization of variables: 
 
# --- local functions: 
_sentence(_dict, _i) = println(string("Dear ", _dict["names"][_i], " is ", _dict["age"][_i], " years old."))

# ---
function julia_main()::Cint
    # ---
    println("--- julia_main ---  Begin  ---  build variables and  make new folder for toml data  ---")
    # --- build variables and  make new folder for toml data:
    root_dir, _             = Base.Filesystem.splitdir(Sys.BINDIR)
    global input_dir        = Base.Filesystem.joinpath(root_dir,    "input_files")
    global s_template_toml  = Base.Filesystem.joinpath(input_dir,   "template.toml")
    global s_default_toml   = Base.Filesystem.joinpath(input_dir,   "default.toml")
    # --- creat folder "input_dir": ----------------------------------------------------------------
    println("---  mkpath($input_dir) --------------------------------")
    try
        Base.Filesystem.mkpath(input_dir)        
    catch
        Base.invokelatest(Base.display_error, Base.catch_stack())
    end
    # --- write default data to toml-file: ---------------------------------------------------------
    println("---  write toml-file ($s_template_toml) --------------------------------")
    try
        if ispath(input_dir)
            if ~Base.Filesystem.isfile(s_template_toml)
                Base.open(s_template_toml, "w") do io
                    TOML.print(io, TEMPLATE_DATA)
                end
            end
            Base.Filesystem.cp(s_template_toml, s_default_toml; force=true)
            Base.sleep(0.1)
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
            real_main()
        else
            if isa(ARGS[1], AbstractString)
                _s = ARGS[1]
                @info(println("--- Enter \"real_main()\" ARGS[1] = \"$_s\" --------------------"))
            else
                _s = ""
            end
            real_main(_s)
        end
    catch
        Base.invokelatest(Base.display_error, Base.catch_stack())
        return 1 
    end
    # ---
    return 0 # if things finished successfully
end                                                                               

function real_main(_toml_file::AbstractString="")
    global _toml_contend = [];     
    @info(println("--- Enter \"real_main()\" -----------------------------------------------"))
    @show Sys.BINDIR

    @info(println("--- \"real_main()\" @show modules ----------------------------"))
    try
        Base.@show filter(n -> isa(getfield(Main, n), Module), Base.names(Main))     
    catch
        Base.invokelatest(Base.display_error, Base.catch_stack())
    end
    
    @info(println("--- \"real_main()\" @show s_default_toml ------------------------"))
    try
        @show s_default_toml        
    catch
        Base.invokelatest(Base.display_error, Base.catch_stack())
    end
    
    @info(println("--- \"real_main()\" check input ------------------------"))
    if Base.any(Base.occursin.(_toml_file, ["-h", "-?", "--help", "/h", "/help", "/?", "--info", "-info"])) ||
        Base.isempty(_toml_file)
        @info(Base.string("\nInput is a file name of type \"*.toml\",
        e.g. \"default.toml\".
        Input toml-files are expected to be located in directory \"../input_files\" \n "))
        input_toml_file = s_default_toml
    else
        _, fn_ext = Base.splitext(_toml_file)
        if Base.cmp(fn_ext, ".toml") == 0
            input_toml_file = Base.Filesystem.joinpath(input_dir, _toml_file)
        else
            @warn("Wrong file extention, expected is \".toml\", default name \"default.toml\" is taken.")
            input_toml_file = s_default_toml
        end
    end
    if ~Base.Filesystem.isfile(input_toml_file)
        @warn("File \"$input_toml_file\" not found, default name \"$s_default_toml\" is taken.")
        input_toml_file = s_default_toml
    end
    # ---
    @info(println("--- \"real_main()\" investigate variable \"input_toml_file\" ------------------------"))
    @show input_toml_file
    @show isfile(input_toml_file)   
    @show typeof(input_toml_file)     

    @info(println("--- \"real_main()\" read in from input_toml_file, use \"tryparsefile()\" -----------"))
    try
        _toml_contend = TOML.tryparsefile(input_toml_file) 
    catch
        Base.invokelatest(Base.display_error, Base.catch_stack())
    end
    @info(println("--- \"real_main()\" after \"tryparsefile()\" for-loop ---------------------------"))
    @show _toml_contend

    @info(string("--- \"real_main()\" _sentence(_toml_contend, 1) ------------------------"))
    try
        _sentence(_toml_contend, 1)
    catch
        Base.invokelatest(Base.display_error, Base.catch_stack())
    end    
    @info(string("--- Exit \"real_main()\"   ---------------------------------------------"))
    # ---
    return
end

function __init__()
    @info(println("--- \"__init__()\" @show modules ----------------------------"))
    try
        Base.@show filter(n -> isa(getfield(Main, n), Module), Base.names(Main))     
    catch
        Base.invokelatest(Base.display_error, Base.catch_stack())
    end
    
    @info(println("--- \"__init__()\" display(TOML.Parser) ---------------------"))
    try
        Base.display(TOML.Parser)   
    catch
        Base.invokelatest(Base.display_error, Base.catch_stack())
    end
    println()
    @info(println("--- Exit \"__init__()\"  ------------------------------------"))
end

end # module
