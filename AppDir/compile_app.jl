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
# ... ...........................................................................................................................
# --- install Tulip from local repository:
# --- import Pkg; Pkg.rm("Tulip"); Pkg.add(path=raw"C:\data\git_repos\forks\Tulip.jl")
# -------------------------------------------------------------------------------------------------------------------------------
# --- packages which can not be installed in current version (are downgraded), status 21-03-2023:
# --- IrrationalConstants (current version v0.2.0, installed: v0.1.1): https://github.com/JuliaMath/IrrationalConstants.jl 
# --- Krylov (current version v0.9.0, installed v0.8.4): https://github.com/Jutho/KrylovKit.jl
# --- LDLFactorizations (current version v0.10.0, installed v0.9.0): https://github.com/JuliaSmoothOptimizers/LDLFactorizations.jl
# --- ---------------------------------------------------------------------------------------------------------------------------


import Pkg, Chain, Dates, Pkg
using PackageCompiler, Printf

# --- configuration parameters: -------------------------------------------------------------------------------------------------
b_instantiate           = false # may take some time ... (maybe set to "true", if issues must be resolved)
b_stop_in_project_env   = true
vJuliaLTS               = v"1.6.7" # version of Julia Long Time Support
case_nr                 = 1 # witch project should be compiled (1: MyAppHelloTulip)
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
if case_nr == 1
    s_app       = "MyAppHelloTulip"
    # import Pkg; Pkg.build("SpecialFunctions")
elseif case_nr == 2
    s_app       = "InteractiveNyquist"
elseif case_nr == 3
    s_app       = "InteractiveEquivalentCircuit"
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

# --- check situation and activate environment in current project. --------------------------------------------------------------
Pkg.activate(); Pkg.resolve() # make sure we are in the primary environment and check, if all dependencies are satisfied
# --- go to expected start directory:
startdir, _ = splitdir(@__FILE__());  cd(startdir)
println("\n--- Start dir: \"", startdir, "\" -------------------------------------------------")
if VERSION > vJuliaLTS
    if ispath(s_app)
        Base.Filesystem.cp(s_app, string(s_app, "_RC"); force=true )
    else
        error("Projectfolder \"", s_app, "\" not found!")
    end
    s_app = string(s_app, "_RC")
end

# ---
vPackageComp = get_pkg_version("PackageCompiler")  # read version of "PackageCompiler"
if isfile("Project.toml")
    @info("Project.toml found!")
else
    if isdir(string("./", s_app))
        cd(string("./", s_app))
    else
        error(string("Dir: ", s_app, " not found!"))
    end
end
if isfile("Manifest.toml") # delete existing "Manifest.toml", if it exists
    rm("Manifest.toml"; force=true)
else
    @info(string("Manifest.toml not found!"))
end

# --- we change from primary to secondary environment / project environment: ----------------------------------------------------
println("\n--- activate secondary environment / application project environment -------- \n")
Pkg.activate(".")
import Pkg # make Pkg available in secondary environment / project environment

# --- install packages, if they do not exist in current project environment: ----------------------------------------------------
s_package = "LLVMExtra_jll"
if VERSION >= v"1.7.0" && ~isinstalled(s_package)
    Pkg.add(s_package)
    @warn("\"$s_package\" had to be installed in the current project!")
    Pkg.rm("$s_package")
end

# --- make shure "PackageCompiler" is not includet in current project environment: ----------------------------------------------
if isinstalled("PackageCompiler")
    @warn("\"PackageCompiler\" was includet in local \"Project.toml\"")
    Pkg.rm("PackageCompiler")
end

println("\n--- resolve version conflicts, build Manifest.toml -------------------------- \n")
Pkg.resolve()
println("\n--- END activate project and resolve version conflicts ---------------------- \n")

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
if b_stop_in_project_env; error("Scheduled stop in project environment!"); end
# ### ######################################################################################################################### #
# --- end of activated secondary environment / application project environment ------------------------------------------------ #
# ### ######################################################################################################################### #

# --- switch back to primary environment & start compile via batch script: ------------------------------------------------------
Pkg.activate() # swtch back to common environment
cd("..") # get out of project directory
s_dir_above = []
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

