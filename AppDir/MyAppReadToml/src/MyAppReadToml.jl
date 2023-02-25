# ----------------------------------------------------------------------------------------------------------------------------- #
# --- An example utilizing *.toml-configuration files.                                                                          #
# --- https://docs.julialang.org/en/v1/stdlib/TOML/                                                                             #
# ############################################################################################################################# #
module MyAppReadToml
import TOML, Tulip
if VERSION >= v"1.7.0"
    using LLVMExtra_jll
end
# --- 
sentense_(_dict, _i) = println(string(_dict["names"][_i], " is ", _dict["age"][_i], " old."))
# ---
function julia_main()::Cint
    println("--- julia_main ---")
    # --- build variables and  make new folder for toml data:
    root_dir, _      = Base.Filesystem.splitdir(Sys.BINDIR)
    input_dir        = Base.Filesystem.joinpath(root_dir,  "input_files")
    s_template_toml  = Base.Filesystem.joinpath(input_dir,  "template.toml")
    s_default_toml   = Base.Filesystem.joinpath(input_dir,  "default.toml")
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
                    TOML.print(io, _template_data)
                end
            end
            Base.Filesystem.cp(s_template_toml, s_default_toml; force=true)
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
    @info(println("--- Enter \"real_main()\" -----------------------------------------------"))
    @show Sys.BINDIR
    @info(println("--- \"real_main()\" -----------------------------------------------"))

    if Base.any(Base.occursin.(_toml_file, ["-h", "-?", "--help", "/h", "/help", "/?", "--info", "-info"])) ||
        Base.isempty(_toml_file)
        @info(Base.string("\nInput is a file name of type \"*.toml\",
        e.g. \"default.toml\" (double quotes are necessary).
        Toml-files are expected to be located in directory \"../input_files\" \n "))
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
    try
        global _content = TOML.parsefile(input_toml_file)        
    catch
        Base.invokelatest(Base.display_error, Base.catch_stack())
    end
    sentense_(_content, 1)
    return
end

function __init__()
    global input_dir        = ""
    global s_template_toml  = ""
    global s_default_toml   = ""
    global _template_data = Dict(
        "names" => ["Julia", "Julio"],
        "age" => [10, 20],
     );    

end

end # module
