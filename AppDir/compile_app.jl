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
# ... ...........................................................................................................................
# --- install Tulip from local repository as development package:
# --- import Pkg; Pkg.rm("Tulip"); Pkg.dev(path=raw"C:\data\git_repos\forks\Tulip.jl")
# --- pkg> dev C:\data\git_repos\forks\Tulip.jl
# -------------------------------------------------------------------------------------------------------------------------------
# --- packages which can not be installed in current version (are downgraded), status 21-03-2023:
# --- IrrationalConstants (current version v0.2.0, installed: v0.1.1): https://github.com/JuliaMath/IrrationalConstants.jl 
# --- Krylov (current version v0.9.0, installed v0.8.4): https://github.com/Jutho/KrylovKit.jl
# --- LDLFactorizations (current version v0.10.0, installed v0.9.0): https://github.com/JuliaSmoothOptimizers/LDLFactorizations.jl
# --- ---------------------------------------------------------------------------------------------------------------------------

include("./Modules/MyEnvTools.jl")

import Pkg, Chain, Dates
using PackageCompiler, Printf

# --- configuration parameters: -------------------------------------------------------------------------------------------------
case_nr                     = 4 # which project should be compiled (1: MyAppHelloTulip)
b_stop_in_priv_prim_env     = false
b_stop_in_project_env       = false # it makes sense to investigate secondary environment / project environment via Pkg.status()
b_instantiate               = true # may take some time ... (maybe set to "true", if issues must be resolved)
b_resolve                   = true # careful with this option, if packages are marked as development packages via: >dev PackageName<
vJuliaLTS                   = v"1.6.7" # version of Julia Long Time Support
dir_local_projects          = raw"C:\data\git_repos\own_repos\Stefans_Julia_RePo\AppDir\cloned_packages"
std_packages_in_priv_prim_env = ["PackageCompiler"]
# ---
if VERSION == vJuliaLTS
    if Sys.iswindows() 
        s_julia = raw"C:\bin\juliaLTS\bin\julia.exe"
    else 
        s_julia = "julia-1.6"
    end
else
    if Sys.iswindows() 
        s_julia = raw"C:\bin\julia\bin\julia.exe"
    else 
        s_julia = "julia-1.8"
    end
end
# ---

if case_nr == 1                 # standard project name and UUID of package Tulip
    s_app       = "MyAppHelloTulip"   
    # import Pkg; Pkg.build("SpecialFunctions")
    s_MyAppCompileEnvironment   = "MyAppCompileEnv" # take standard primary environment
    # s_MyAppCompileEnvironment   = "" # take standard primary environment
    specific_packages_inside_both_env = []
    my_cloned_packages = []
    my_cloned_packages_in_AppProject = []
elseif case_nr == 2             # take clone of "Tulip", new name "MyTulip" and new UUID
    s_app       = "MyTulipHello"
    s_MyAppCompileEnvironment   = "MyInteractiveNyquistCompileEnv"
    specific_packages_inside_both_env = []
    my_cloned_packages = ["MyTulip"]
    my_cloned_packages_in_AppProject = ["MyTulip"]
elseif case_nr == 3             
    s_app       = "InteractiveNyquist"
    s_MyAppCompileEnvironment   = "PrimeEnvInteractiveNyquistApp"
    specific_packages_inside_both_env = []
    my_cloned_packages = []
    my_cloned_packages_in_AppProject = []
elseif case_nr == 4
    s_app       = "InteractiveEquivalentCircuit" # abbrev IEC
    s_MyAppCompileEnvironment   = "PrimeEnvIECApp"
    specific_packages_inside_both_env = []
    my_cloned_packages = []
    my_cloned_packages_in_AppProject = []
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
# ---
isinstalled(pkg::AbstractString) = pkg ∈ keys(Pkg.project().dependencies)
# --- useful function found here (currently not in use in this script): 
# --- https://discourse.julialang.org/t/proper-way-to-create-sysimage-with-all-dependencies-of-a-given-package/91460/4
depsof(package::String) = filter(!=(package), map(p->p.name, values(Pkg.dependencies())))

# ------------------------------------------------------------------------------------------------------------------------------ #
# --- I.)                                                                                                                        # 
# --- load private primary Environment and populate whith stard packages and cloned private packages: -------------------------- #
if ~isempty(s_MyAppCompileEnvironment) &&  ~any(occursin.(s_MyAppCompileEnvironment, Main.MyEnvTools.MyLib_select_primary_env())) 
    Main.MyEnvTools.MyLib_add_primary_env(s_MyAppCompileEnvironment)
end

# println("--- DGB1: ", Base.active_project())

if splitpath(Base.active_project())[end-1] != s_MyAppCompileEnvironment
    Main.MyEnvTools.MyLib_select_primary_env(s_MyAppCompileEnvironment);
end
# --- packages to be available in current private primary Environment:
import Pkg # make Pkg available in primary private environment
# --- install standard packages, if not yet installed: ------------------------------------------------------------------------- #
s_package = "LLVMExtra_jll"
if VERSION >= v"1.7.0" && ~isinstalled(s_package)
    Pkg.add("$s_package")
    @warn("\"$s_package\" had to be installed in the current project!")
end
if ~isempty(std_packages_in_priv_prim_env)
    for i_package in std_packages_in_priv_prim_env
        if ~isinstalled(i_package)
            Pkg.add("$i_package")
        end
    end
end
if ~isempty(specific_packages_inside_both_env)
    for i_package in specific_packages_inside_both_env
        if ~isinstalled(i_package)
            # Pkg.add("$i_package")
            println("DBG:   $i_package")
        end
    end
end


# --- install private clones of packages in primary environment, if not yet installed: ----------------------------------------- #
if ~isempty(my_cloned_packages)
    for i_package in my_cloned_packages
        i_package_path = joinpath(dir_local_projects, i_package)
        if ispath(i_package_path)
            if ~isinstalled(i_package)
                Pkg.develop(path="$i_package_path")
            end
        else 
            error("Path \"", i_package_path,"\" for cloned package \"", i_package,"\" is missing")
        end
    end
end

Pkg.resolve() # make sure we are in the primary environment and check, if all dependencies are satisfied
if b_stop_in_priv_prim_env
    @info('-'^100); @info("---  Scheduled stop in private primary environment.  ---");     @info('-'^100)
    error("Scheduled stop in private primary environment.")
end

# --- go to expected start directory: -------------------------------------------------------------------------------------------
startdir, _ = splitdir(@__FILE__());  cd(startdir)
println("\n--- Start dir: \"", startdir, "\" -------------------------------------------------")
if VERSION > vJuliaLTS
    tmp_s_app = string("tmp_copy_", s_app, "_julia_stable")
    if ispath(tmp_s_app)
        @info(string("Julia Version: v", VERSION, ", copy of project folder: \"", tmp_s_app, "\" exists already!  ------"))
    else
        println("Julia Version: v", VERSION, ", copy project folder to: \"", tmp_s_app, "\"   ------")
        if ispath(s_app)
            Base.Filesystem.cp(s_app, tmp_s_app; force=true )
        else
            error("Projectfolder \"", s_app, "\" not found!")
        end
        println("Copy Project folder to: \"", tmp_s_app, "\"  concludet! ------")
    end
    s_app = tmp_s_app
end
dir_project = joinpath(startdir, s_app); 
if isdir(dir_project)
    cd(dir_project)
else
    error("Project directory: \"", dir_project, "\" does not exist!")
end

# ---
vPackageComp = get_pkg_version("PackageCompiler")  # read version of "PackageCompiler"
if isfile("Project.toml")
    @info("Project.toml found!")
else
    error("Project.toml not found!")
end
if isfile("Manifest.toml") # delete existing "Manifest.toml", if it exists
    rm("Manifest.toml"; force=true)
else
    @info(string("Manifest.toml not found!"))
end
println("\n--- current directory: \"", pwd(), "\" ------------------------------ \n")

# ----------------------------------------------------------------------------------------------------------------------------- #
# --- II.)                                                                                                                      # 
# --- we change from primary to secondary environment / project environment: -------------------------------------------------- #
# ----------------------------------------------------------------------------------------------------------------------------- #
println("--- activate secondary environment / application project environment -------- \n")
Pkg.activate(".")
import Pkg # make Pkg available in secondary environment / project environment

# --- install packages, if they do not exist in current project environment: ----------------------------------------------------
s_package = "LLVMExtra_jll"
if VERSION >= v"1.7.0" && ~isinstalled(s_package)
    Pkg.add("$s_package")
    @warn("\"$s_package\" had to be installed in the current project!")
end

if ~isempty(my_cloned_packages_in_AppProject)
    for i_package in my_cloned_packages_in_AppProject
        i_package_path = joinpath(dir_local_projects, i_package)
        if ispath(i_package_path)
            if ~isinstalled(i_package)
                Pkg.develop(path="$i_package_path")
            end
        else 
            error("Path \"", i_package_path,"\" for cloned package \"", i_package,"\" is missing")
        end
    end
end
if ~isempty(specific_packages_inside_both_env)
    for i_package in specific_packages_inside_both_env
        if ~isinstalled(i_package)
            Pkg.add("$i_package")
        end
    end
end


# --- make shure "PackageCompiler" is not includet in current project environment: ----------------------------------------------
if isinstalled("PackageCompiler")
    @warn("\"PackageCompiler\" was includet in local \"Project.toml\"")
    Pkg.rm("PackageCompiler")
end
if b_resolve
println("\n--- resolve version conflicts, build Manifest.toml -------------------------- \n")
Pkg.resolve()
println("\n--- END activate project and resolve version conflicts ---------------------- \n")
end

if b_instantiate
    println("---- Pkg.instantiate() -------------------------------------------------------")
    Pkg.instantiate() # make sure to ensure all packages in the environment are installed.
end

# ---
s_compiled = string(s_app, "_j", VERSION, "_PCv", vPackageComp)
s_env = @sprintf("%s/%s", splitpath(Base.active_project())[end-2], splitpath(Base.active_project())[end-1])
s_win_title = string("v", VERSION, ", App: ", s_app, ", env: ", s_env)
# --- change title of CLI (command line interface):
Sys.iswindows() ? run(`cmd /C 'title '"$s_win_title"`) : print("\033]0;$s_win_title\007")

println("Environment: ", Base.active_project())

if isfile("Manifest.toml") # "Manifest.toml" will be build during compilation of project ...
    rm("Manifest.toml"; force=true)
else
    @warn(string("After Base.active_project(): Manifest.toml not found!"))
end
if b_stop_in_project_env
    @info('-'^100); @info("---  Scheduled stop in project environment!  ---");     @info('-'^100)
    error("Scheduled stop in project environment!"); 
end
# ### ######################################################################################################################### #
# --- end of activated secondary environment / application project environment ------------------------------------------------ #
# ### ######################################################################################################################### #


# ----------------------------------------------------------------------------------------------------------------------------- #
# --- III.)                                                                                                                     # 
# --- a.) change back from the secondary environment / project environment back to the selected primary environment             #
# --- b.) create a batch and a julia script file and invoce the batch script                                                    #
# ----------------------------------------------------------------------------------------------------------------------------- #
# --- switch back to primary environment & change directory above the project directory: ----------------------------------------
Main.MyEnvTools.MyLib_select_primary_env(s_MyAppCompileEnvironment); # swtch back to common environment
cd(startdir) # get out of project directory
s_dir_above = []
# --- create a batch and a julia script file and invoce the batch script : ------------------------------------------------------
if isdir(s_app)
    s_dir_above = pwd()
    println("\npwd(): ", pwd(), "\n")
    if isdir(s_compiled) # modify name of target directory, if it exist already to enable next compilation, before previous is concluded
        d_ = Dates.format(Dates.now(), "_HHMM")
        s_compiled = string(s_compiled, d_)
    end
    # --- common part (common for linux and ms-windows)
    s_start_PC = "tmp_start_PC.jl"
    cd_proj_sub_dir = string("cd \"", s_dir_above, "\"")
    s_comp_cmd = string("$s_julia -q --color=yes --startup-file=no --project -- $s_start_PC")
    Sys.iswindows() ?  (s_bat = "tmp_compile_app.bat") : (s_bat = "tmp_compile_app.sh")
    fid = open(s_bat, "w")
        if ~Sys.iswindows(); println(fid, "#!/bin/bash"); end
        println(fid, cd_proj_sub_dir)
        println(fid, s_comp_cmd)
    close(fid)
    fid = open(s_start_PC, "w")
        if Sys.iswindows() 
            println(fid, string("run(`cmd /C 'title '\"", s_compiled, "\"`)"))
        else
            println(fid, string("print(\"\\033]0;$s_win_title\\007\")"))
        end
        println(fid, string("cd(raw\"", s_dir_above, "\")"))
        # println(fid, string("import Pkg; Pkg.build(\"Tulip\")"))
        # println(fid, string("println(\"abspath(PROGRAM_FILE): \", abspath(PROGRAM_FILE))"))
        # println(fid, string("println(\"@__FILE__: \", @__FILE__)"))
        println(fid, string("using PackageCompiler"))
        println(fid, string("create_app(\"$s_app\", \"$s_compiled\"; force=true, include_lazy_artifacts=true)"))
    close(fid)
    s_bat_full = joinpath(s_dir_above, s_bat)

    if Sys.iswindows()
        cmd_ = Cmd(`cmd /c start \"\" $s_bat`; windows_verbatim=true, detach=true)
    elseif Sys.islinux()
        Base.Filesystem.chmod(s_bat, 0o500) # +500= a.) execute by user= 100, b.) read by user= 400
        cmd_ = Cmd(`konsole --noclose -e ./$s_bat \&`; windows_verbatim=true, detach=true)
        println("cmd: ", cmd_)
    else
        error("Not yet ready for other then Linux- and MS-Windows-OS")
    end
    run(cmd_)
else
    error("Project folder not found!")
end
cd(startdir)

