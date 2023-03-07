# --- compile_app.jl: -----------------------------------------------------------------------------------------------------------
# --- starts a new app-compilation process of the specified package via dynamic batch and julia-script-file
# ... relevant information: .....................................................................................................
# --- https://julialang.github.io/PackageCompiler.jl/stable/apps.html
# --- https://docs.julialang.org/en/v1/manual/command-line-options/
# --- https://docs.julialang.org/en/v1/manual/modules/#Module-initialization-and-precompilation
# --- https://docs.julialang.org/en/v1/manual/running-external-programs/
# --- relevant discussions: .....................................................................................................
# --- https://discourse.julialang.org/t/libdl-dlopen-or-libdl-find-library-does-not-find-a-shared-library/55161/6
# --- https://discourse.julialang.org/t/how-to-indicate-a-specific-path-to-julia-libdl-find-library/67794
# --- https://discourse.julialang.org/t/proper-way-to-create-sysimage-with-all-dependencies-of-a-given-package/91460/6
# --- https://discourse.julialang.org/t/building-and-releasing-a-fully-self-contained-application-written-in-julia/10418/16
# --- ENV["JULIA_DEBUG"] = "PackageCompiler"
# --- https://discourse.julialang.org/t/how-to-input-files-as-command-line-arguments-to-compiled-julia/64633/41?page=3
# --- ---------------------------------------------------------------------------------------------------------------------------

include("./Modules/MyEnvTools.jl")

import Pkg, Chain, Dates, PkgVersion
using PackageCompiler, Printf
# --- for the purpose of onedirectional synchronization -------------------------------------------------------------------------
using PyCall
py_setuptools   = PyCall.pyimport("setuptools")
py_distutils    = py_setuptools.distutils
py_copy_tree    = py_distutils.dir_util.copy_tree

# --- configuration parameters: -------------------------------------------------------------------------------------------------
case_nr                     = 7     # which project should be compiled (1: MyAppHelloTulip)
b_action                    = true # "true" build_appl, if (b_run=true)  || "false": to develop the script drop time consuming steps 
b_stop_in_priv_prim_env     = false # stop in primary environment
b_stop_in_project_env       = false # it makes sense to investigate secondary environment / project environment via Pkg.status()
b_instantiate               = true # may take some time ... (maybe set to "true", if issues must be resolved)
b_resolve                   = true # careful with this option, if packages are marked as development packages via: >dev PackageName<
b_update                    = true # send update command in primary and secondary environment
b_retry_load_extention      = true  # Base.retry_load_extensions() will also invoke "Pkg.resolve(), introduced in v1.9.0
b_debug_compile             = true
b_incremental               = false
b_run                       = true
# --- end configuration part:  --------------------------------------------------------------------------------------------------
std_pkg_in_prim_compile_env = ["PackageCompiler"]
Vers_aboveLTS = VersionNumber(1, 6, 9) 
# ---
if VERSION < VersionNumber(1, 8, 0)
    s_release_tag = "_LTS"
    if Sys.iswindows() 
        s_julia = raw"C:\bin\juliaLTS\bin\julia.exe"
    else 
        s_julia = "julia-1.6"
    end
elseif VERSION < VersionNumber(1, 8, 9)
    s_release_tag = "_Stable"
    if Sys.iswindows() 
        s_julia = raw"C:\bin\julia\bin\julia.exe"
    else 
        s_julia = "julia-1.8"
    end
elseif VERSION < VersionNumber(1, 9, 9)
    s_release_tag = "_RC"
    @warn("-------- use release candidate: -------------")
    if Sys.iswindows() 
            s_julia = raw"C:\bin\juliaRC\bin\julia.exe"
    else 
        s_julia = "julia-1.9"
    end
else
    error("Unexpected Julia Version Number: ", VERSION)
end
if b_retry_load_extention # switch off this option if Julia is older then v1.9.0
    b_retry_load_extention = VERSION >= VersionNumber(1, 9, 0)
end

# --- Optional parameters / default values:
s_MyAppCompileEnvironment = ""
executable_name = ""
packages_for_julia_stable   = [] # e.g. "LLVMExtra_jll"
# --- avalable projects:
if case_nr == 1                 # standard project name and UUID of package Tulip
    s_app       = "MyAppHelloTulip"             # ok
    # import Pkg; Pkg.build("SpecialFunctions")
    s_MyAppCompileEnvironment   = "MyAppHelloTulipCompileEnv" # if empty, take standard primary environment
    # s_MyAppCompileEnvironment   = "" # take standard primary environment
    specific_packages_inside_both_env = ["Tulip", "TOML"]
elseif case_nr == 2             # a bit mor complicated TOML-example
    s_app       = "MyTOML"                      # ok
    s_MyAppCompileEnvironment   = "MyTOMLCompileEnv"
    specific_packages_inside_both_env = ["TOML", "ArrayInterface"]
elseif case_nr == 3             # a bit mor complicated TOML-example
    s_app       = "MyAppReadToml"               # ok
    s_MyAppCompileEnvironment   = "MyAppReadTomlCompileEnv"
    specific_packages_inside_both_env = ["TOML", "InteractiveUtils", "DelimitedFiles"]
elseif case_nr == 4   
    s_app       = "MyGLMakieApp"                # ok
    s_MyAppCompileEnvironment   = "MyGLMakieAppCompileEnv"
    specific_packages_inside_both_env = ["GLMakie"]
elseif case_nr == 5             
    s_app       = "InteractiveNyquist"          # ok
    s_MyAppCompileEnvironment   = "PrimeEnvInteractiveNyquistApp"
    specific_packages_inside_both_env = ["GLMakie", "RobustModels", "Printf", "Tulip", 
        "MacroTools", "JuliaVariables", "MLStyle", "DataStructures", "Serialization"]
elseif case_nr == 6             # more simple figure (in comparison to "InteractiveEquivalentCircuit")
    s_app       = "InteractiveEquivalentCircuit_simple" # abbrev IEC   # gestartet
    s_MyAppCompileEnvironment   = "PrimeEnvIECSimpleApp"  
    specific_packages_inside_both_env = ["EquivalentCircuits", "GLMakie", "Printf", "RobustModels"]
elseif case_nr == 7             # result is un-portable :-(, it includes package "GeneralizedGenerated"
    s_app       = "InteractiveEquivalentCircuit"        # abbrev IEC   # chashing
    s_MyAppCompileEnvironment   = "PrimeEnvIECApp"
    specific_packages_inside_both_env = ["GeneralizedGenerated", "GLMakie", "EquivalentCircuits", "RobustModels", "Printf"]
else
    error("Case does not exist :-( ")
end

# --- local function: -----------------------------------------------------------------------------------------------------------
get_pkg_version(name::AbstractString) = Chain.@chain Pkg.dependencies() begin
        values
        [x for x in _ if x.name == name]
        only
        return _.version
end

# --- check, if a apckage is already installed:
isinstalled(pkg::AbstractString) = pkg ∈ keys(Pkg.project().dependencies)

# --- useful function found here (currently not in use in this script): 
# --- https://discourse.julialang.org/t/proper-way-to-create-sysimage-with-all-dependencies-of-a-given-package/91460/4
depsof(package::String) = filter(!=(package), map(p -> p.name, values(Pkg.dependencies())))

# ------------------------------------------------------------------------------------------------------------------------------ #
# --- I.)                                                                                                                        # 
# --- load private primary Environment and populate whith stard packages and eventually with cloned private packages: ---------- #
# --- change title of CLI (command line interface) / external REPL / terminal window:
d_ = Dates.format(Dates.now(), "_HHMM")
s_win_title = string("Start: ", d_, " --- Julia v", VERSION, ", App: ", s_app)
Sys.iswindows() ? run(`cmd /C 'title '"$s_win_title"`) : print("\033]0;$s_win_title\007")
# --- build full path to Compile Environment:
Pkg.activate()
s_compile_env = joinpath(splitdir( Base.active_project())[1], s_MyAppCompileEnvironment)
# --- add primary environment, if not yet exist:
if ~isempty(s_MyAppCompileEnvironment) &&  ~any(occursin.(s_MyAppCompileEnvironment, Main.MyEnvTools.MyLib_select_primary_env())) 
    Main.MyEnvTools.MyLib_add_primary_env(s_MyAppCompileEnvironment)
end

println("--- : ", Base.active_project(), " -----------------------------------------------")

if splitpath(Base.active_project())[end-1] != s_MyAppCompileEnvironment
    Main.MyEnvTools.MyLib_select_primary_env(s_MyAppCompileEnvironment);
end
# --- packages to be available in current private primary Environment:
import Pkg; Pkg.gc()  # make Pkg available in primary private environment and clean

# --- install standard packages, if not yet installed: ------------------------------------------------------------------------- #
if ~isempty(std_pkg_in_prim_compile_env)
    for i_package in std_pkg_in_prim_compile_env
        if ~isinstalled(i_package)
            Pkg.add("$i_package")
        end
    end
end
try
    global vPackageComp = get_pkg_version("PackageCompiler")  # read version of "PackageCompiler"    
catch
    Base.invokelatest(Base.display_error, Base.catch_stack())
    error("\"PackageCompiler\" not found in environment")
end

if VERSION > Vers_aboveLTS
    specific_packages_inside_both_env = vcat(specific_packages_inside_both_env, packages_for_julia_stable)
end
if ~isempty(specific_packages_inside_both_env)
    for i_package in specific_packages_inside_both_env
        if ~isinstalled(i_package)
            Pkg.add("$i_package")
            # println("DBG:   $i_package")
        end
    end
end

if b_update && b_action
    println("\n--- update packages and precompile() ---------------------------------------- \n")
    Pkg.update(); Pkg.precompile()
    println("\n--- END update packages and precompile() ------------------------------------ \n")
end

if (b_resolve || b_retry_load_extention) && b_action  # to use the option b_retry_load_extention a manifest.toml must be established
    println("\n--- resolve version conflicts, build Manifest.toml -------------------------- \n")
    fn_manifest_toml = joinpath(splitdir(Base.active_project())[1], "Manifest.toml")
    Base.Filesystem.rm(fn_manifest_toml; force=true )
    Pkg.resolve(); Pkg.update()
    println("\n--- END activate project and resolve version conflicts ---------------------- \n")
end
if b_stop_in_priv_prim_env
    if b_action
        println("\n--- Pkg.precompile() ------------------------------------------------------------ \n")
        Pkg.precompile()
    end
    @show Pkg.status()
    @info('-'^100); @info("---  Scheduled stop in private primary environment: \"$s_MyAppCompileEnvironment\".  ---");     @info('-'^100)
    error("Scheduled stop in private primary environment.")
end

# --- establish directory variables: -------------------------------------------------------------------------------------------
startdir, _ = splitdir(@__FILE__());  cd(startdir)
dir_project = joinpath(startdir, s_app); 
@show startdir
@show dir_project

# ----------------------------------------------------------------------------------------------------------------------------- #
# --- II.)                                                                                                                  --- # 
# --- copy project directory, if julia is different from"LTS":                                                              --- #
# ----------------------------------------------------------------------------------------------------------------------------- #
@info(string("\n--- Start dir: \"", startdir, "\" ------------------------------------------------- \n "))
if VERSION > Vers_aboveLTS
    tmp_dir_project = joinpath(startdir, string("tmp", s_release_tag, "_", s_app))
    tmp_fn_project_toml         = joinpath(tmp_dir_project, "Project.toml")
    tmp_fn_project_toml_backup  = joinpath(tmp_dir_project, "Project~.toml")
    tmp_fn_manifest_toml        = joinpath(tmp_dir_project, "Manifest.toml")
    tmp_fn_manifest_toml_backup = joinpath(tmp_dir_project, "Manifest~.toml")
    if ~ispath(tmp_dir_project)
        @info(string("Julia Version: v", VERSION, ", copy of project folder: \"", tmp_dir_project, "\" exists! \n "))
        @info(string("A new folder with the modified name: \"", tmp_dir_project, "\" will be copied!  ------"))
        if ~ispath(dir_project)
            error("Projectfolder \"$dir_project"\" not found!")
        end
        Base.Filesystem.cp(dir_project, tmp_dir_project; force=true )
        Base.Filesystem.rm(tmp_fn_manifest_toml; force=true )
        Pkg.activate(tmp_fn_project_toml); Pkg.instantiate(); Pkg.resolve()
        # Pkg.upgrade_manifest(); 
    else
        @info("---  Update folder: \"$tmp_dir_project\". -------------------------- \n ")
        # --- backup copy of "Project.toml" to restore old version after folder synchronisation 
        if ~isfile(tmp_fn_project_toml)
            error("$tmp_fn_project_toml not found!")
        end
        Base.Filesystem.cp(tmp_fn_project_toml, tmp_fn_project_toml_backup; force=true )
        # --- backup copy of "Manifest.toml" to restore old version after folder synchronisation 
        if isfile(tmp_fn_manifest_toml)
            Base.Filesystem.cp(tmp_fn_project_toml, tmp_fn_project_toml_backup; force=true )
        else
            @warn("$tmp_fn_project_toml not found!")
        end
        # --- one way synchronization of project folder for Julia-Stable and Julia-RC:
        py_copy_tree(dir_project, tmp_dir_project, verbose=true, update=true) # copy only files that have been change in sourcs-dir
        # --- restore privious versions of "Project.toml" and "Manifest.toml":
        Base.Filesystem.cp(tmp_fn_project_toml_backup, tmp_fn_project_toml; force=true )
        if isfile(tmp_fn_manifest_toml_backup)
            Base.Filesystem.cp(tmp_fn_manifest_toml_backup, tmp_fn_manifest_toml; force=true )
        end
    end
    dir_project = tmp_dir_project
    @info(string("\nJulia Version: ", VERSION,"  ---  Synchronization of: \"$dir_project\"\n"))
end

# ----------------------------------------------------------------------------------------------------------------------------- #
# --- III.)                                                                                                                      # 
# --- change to project folder and from primary to secondary environment / project environment: ------------------------------- #
# ----------------------------------------------------------------------------------------------------------------------------- #
# --- change to project directory: 
if isdir(dir_project)
    cd(dir_project)
else
    error("Project directory: \"$dir_project"\" does not exist!")
end
# --- check if "Project.toml" exist and delete previous "Manifest.toml" (if it exists) 
if isfile("Project.toml")
    @info("Project.toml found!")
else
    @show pwd();  error("Project.toml not found!")
end

println("\n--- current directory: \"", pwd(), "\" ------------------------------ \n")
# --- change from primary to secondary environment / project environment:
println("--- activate secondary environment / application project environment -------- \n")
if cmp(dir_project, pwd()) == 0
    Pkg.activate(dir_project); Pkg.gc(); # activate secondary environment and clean
else
    @show dir_project
    @show pwd()
    error("Wrong directory! To activate directory!")
end

# --- install packages, if they do not exist in current project environment: ----------------------------------------------------
if VERSION > Vers_aboveLTS
    specific_packages_inside_both_env = vcat(specific_packages_inside_both_env, packages_for_julia_stable)
end
# --- it is possible to specify for each package a specific version to be installed:
if ~isempty(specific_packages_inside_both_env)
    for i_package in specific_packages_inside_both_env
        if isa(i_package, Vector)
            _Pkg = i_package[1]
            _vers = i_package[2]
            if ~isinstalled(i_package[1])
                Pkg.add(name="$(i_package[1])", version="$(i_package[2])")
            end
        else            
            if ~isinstalled(i_package)
                Pkg.add("$i_package")
            end
        end
    end
end
# --- it is possible to specify for each package a specific version to be installed:
if ~isempty(specific_packages_inside_both_env)
    for i_package in specific_packages_inside_both_env
        if isa(i_package, Vector)
            _Pkg = i_package[1]
            _vers = i_package[2]
            if ~isinstalled(i_package[1])
                Pkg.add(name="$(i_package[1])", version="$(i_package[2])")
            end
        else            
            if ~isinstalled(i_package)
                Pkg.add("$i_package")
            end
        end
    end
end


# --- make shure "PackageCompiler" is not includet in current project environment: ----------------------------------------------
if isinstalled("PackageCompiler")
    @warn("\"PackageCompiler\" was includet in local \"Project.toml\"")
    Pkg.rm("PackageCompiler")
end

if b_update && b_action
    println("\n --- update packages and precompile() in secondary environmet ----- \n")
    Pkg.update(); Pkg.precompile()
    println("\n --- END update packages and precompile() ------------------------- \n")
end

if b_instantiate
    @info("---- Pkg.instantiate() --------------------------------------------------")
    fn_manifest_toml        = joinpath(dir_project, "Manifest.toml")
    Base.Filesystem.rm(fn_manifest_toml; force=true )    
    Pkg.instantiate() # make sure to ensure all packages in the environment are installed, build new "Manifest.toml".
    Pkg.precompile()
end
if b_resolve && b_action
    println("\n--- resolve version conflicts, build Manifest.toml --------------- \n")
    fn_manifest_toml = joinpath(splitdir(Base.active_project())[1], "Manifest.toml")
    Base.Filesystem.rm(fn_manifest_toml; force=true )
    Pkg.resolve(); Pkg.update()
    println("\n--- END activate project and resolve version conflicts ----------- \n")
end

# ---
s_env = @sprintf("%s/%s", splitpath(Base.active_project())[end-2], splitpath(Base.active_project())[end-1])

@info(string("Environment: ", Base.active_project()))

if isfile("Manifest.toml") # "Manifest.toml" will be build during compilation of project ...
    @warn(string("After Base.active_project(): Manifest.toml not found!"))
end

# --- one of the last things after deletion of the old Manifest.toml
if b_retry_load_extention && b_action
    println("\n--- Pkg.build() & Base.retry_load_extensions() ------------------------------ \n")
    Pkg.build()
    Base.retry_load_extensions()
    println("\n--- END Pkg.build() & Base.retry_load_extensions() -------------------------- \n")
end

if b_stop_in_project_env
    @show Pkg.status()
    @info('-'^100); @info("---  Scheduled stop in project environment: \"$s_env\"!  ---");     @info('-'^100)
    error("Scheduled stop in project environment!"); 
end
# ### ######################################################################################################################### #
# --- end of activated secondary environment / application project environment ------------------------------------------------ #
# ### ######################################################################################################################### #


# ----------------------------------------------------------------------------------------------------------------------------- #
# --- IV.)                                                                                                                     # 
# --- a.) change back from the secondary environment / project environment back to the selected primary environment             #
# --- b.) create a batch and a julia script file and invoce the batch script                                                    #
# ----------------------------------------------------------------------------------------------------------------------------- #
# --- switch back to primary environment & change directory above the project directory (startdirectory): 
Main.MyEnvTools.MyLib_select_primary_env(s_MyAppCompileEnvironment); # swtch back to specified primary environment
cd(startdir) # get out of project directory
# --- create a batch and a julia script file and invoce the batch script : ------------------------------------------------------
if ~isdir(startdir) # modify name of target directory, if it exist already to enable next compilation, before previous is concluded
    error("This should not heapen!")
end
s_compiled = string("tmp", s_release_tag, "_", s_app, "_compiled_j", VERSION, "_PCv", vPackageComp)
s_compiled_full = joinpath(startdir, s_compiled)
if ispath(s_compiled_full)
    d_ = Dates.format(Dates.now(), "_HHMM")
    s_compiled = string(s_compiled, d_)
else
    d_ = ""
end
# --- s_start_time: --- & window title: -----------------------------------------------------------------------------------
s_start_time = Dates.format(Dates.now(), "HH:MM")
s_win_title = string("start: $s_start_time,  v", VERSION, ", App: ", s_app, d_, ", env: ", s_env)
# --- change title of CLI (command line interface):
Sys.iswindows() ? run(`cmd /C 'title '"$s_win_title"`) : print("\033]0;$s_win_title\007")
# --- common part (common for linux and ms-windows)
s_start_PC = string("tmp_start_PC", s_release_tag, ".jl")
cd_proj_sub_dir = string("cd \"", startdir, "\"")
s_comp_cmd = string("$s_julia -q --color=yes --startup-file=no --project -- $s_start_PC")
Sys.iswindows() ?  (s_bat = "tmp_compile_app.bat") : (s_bat = "tmp_compile_app.sh")
fid = open(s_bat, "w")
    if ~Sys.iswindows(); println(fid, "#!/bin/bash"); end
    println(fid, cd_proj_sub_dir)
    println(fid, s_comp_cmd)
close(fid)
fid = open(s_start_PC, "w")
    if Sys.iswindows() 
        println(fid, string("run(`cmd /C 'title '\"$s_win_title\"`)"))
    else
        println(fid, string("print(\"\\033]0;$s_win_title\\007\")"))
    end
    println(fid, "@info(string(\"\\n---- start compilation: ", s_start_time, "  ---  Julia Version: ", VERSION, "    -----\\n \"))")
    println(fid, string("import Pkg"))
    println(fid, string("using PackageCompiler"))
    println(fid, string("cd(raw\"$dir_project\")"))
    println(fid, string("Pkg.activate(raw\"$dir_project\")"))
    println(fid, string("Pkg.instantiate(; verbose = true)"))   
    println(fid, string("Pkg.resolve()"))  
    if any(occursin.("GLMakie", specific_packages_inside_both_env))
        println(fid, "@info(string(\"\\n----      start build \\\"ModernGL\\\"     -----\\n \" ))" )        
        println(fid, string("Pkg.build(\"ModernGL\")") )
        println(fid, "@info(string(\"\\n----      start build \\\"GLMakie\\\"     -----\\n \" ))" )
        if b_debug_compile
            println(fid, string("ENV[\"MODERNGL_DEBUGGING\"] = \"true\"; Pkg.build(\"GLMakie\")") )
        else
            println(fid, string("Pkg.build(\"GLMakie\")") )
        end
        println(fid, "@info(string(\"\\n#######      END  build \\\"GLMakie\\\"     ##########\\n \" ))" )
    end
    if b_update
        println(fid, string("Pkg.update()"))  
    end
    println(fid, string("Pkg.precompile()"))  
    println(fid, string("Pkg.activate(raw\"$s_compile_env\")") )
    println(fid, string("cd(raw\"$startdir\")") )    
    # println(fid, string("import Pkg; Pkg.build(\"Tulip\")"))
    if b_debug_compile; println(fid, string("ENV[\"JULIA_DEBUG\"] = \"PackageCompiler\"") ); end
    println(fid, string("function compile_it()") )
    if isempty(executable_name)
        println(fid, string("    names_ = [Pair(\"$s_app\", \"julia_main\")]") )
    else
        println(fid, string("    names_ = [Pair(\"$executable_name\", \"julia_main\")]") )
    end
    b_incremental ? s_incremental = "true" : s_incremental = "false"
    println(fid, string("    create_app(\"$s_app\", \"$s_compiled\"; incremental=$s_incremental, force=true, include_lazy_artifacts=true, executables=names_)"))
    println(fid, string("end"))
    println(fid, string("@time compile_it()"))
close(fid)
s_bat_full = joinpath(startdir, s_bat)

if Sys.iswindows()
    cmd_ = Cmd(`cmd /c start \"\" $s_bat`; windows_verbatim=true, detach=true)
elseif Sys.islinux()
    Base.Filesystem.chmod(s_bat, 0o500) # +500= a.) execute by user= 100, b.) read by user= 400
    cmd_ = Cmd(`konsole --noclose --show-menubar --separate -e ./$s_bat \&`; windows_verbatim=true, detach=true)
else
    error("Not yet ready for other then Linux- and MS-Windows-OS")
end
if b_run && b_action
    run(cmd_; wait=false)
else
    @info(string("system call cmd would be: ", cmd_))
    @info("Compilation option \"b_run\" is set to \"false\"!")
end
# --- switch back to common / default primary environment:
Pkg.activate()
@info("--- End of script execution :-)  -------------------------------------------------------------------------------")
