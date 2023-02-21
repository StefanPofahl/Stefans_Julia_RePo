# --- compile_app.jl: -----------------------------------------------------------------------------------------------------------
# --- starts a new app-compilation process of the specified package via dynamic batch and julia-script-file
# ... relevant information: .....................................................................................................
# --- https://julialang.github.io/PackageCompiler.jl/stable/apps.html
# --- https://docs.julialang.org/en/v1/manual/command-line-options/
# --- https://docs.julialang.org/en/v1/manual/modules/#Module-initialization-and-precompilation
# --- relevant discussions: .....................................................................................................
# --- https://discourse.julialang.org/t/libdl-dlopen-or-libdl-find-library-does-not-find-a-shared-library/55161/6
# --- https://discourse.julialang.org/t/how-to-indicate-a-specific-path-to-julia-libdl-find-library/67794
# ... ...........................................................................................................................
# --- install Tulip from local repository:
# --- import Pkg; Pkg.rm("Tulip"); Pkg.add(url=raw"C:\data\git_repos\forks\Tulip.jl")
# -------------------------------------------------------------------------------------------------------------------------------

import Pkg, Chain, Dates
using PackageCompiler, Printf

# --- configuration parameters: -------------------------------------------------------------------------------------------------
b_juliaLTS      = true
b_instantiate   = true
if b_juliaLTS
    s_julia = raw"C:\bin\juliaLTS\bin\julia.exe"
else
    s_julia = raw"C:\bin\julia\bin\julia.exe"
end
case_nr = 2
if case_nr == 1
    s_app       = "InteractiveNyquist"
    packages_   = ["DataStructures", "GLMakie", "MLStyle", "MacroTools", "JuliaVariables", "Printf", "RobustModels", "Serialization"] 
elseif case_nr == 2
    s_app       = "MyAppHelloTulip"
    packages_   = ["Tulip"] # packages that should be included in the "Project.toml"
    import Pkg; Pkg.build("SpecialFunctions")
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
isinstalled(pkg::AbstractString) = pkg ∈ keys(Pkg.project().dependencies)
# --- check situation and activate environment in current project. --------------------------------------------------------------
Pkg.activate(); Pkg.resolve() # make sure we are in the primary environment and check, if all dependencies are satisfied
# --- go to expected start directory:
startdir, _ = splitdir(@__FILE__());  cd(startdir)
println("\n--- Start dir: \"", startdir, "\" -------------------------------------------------")
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
if isfile("Manifest.toml") # delete existing "Manifest.toml", if it exist
    rm("Manifest.toml"; force=true)
else
    @info(string("Manifest.toml not found!"))
end
# --- change environment to local project environment to ensure all specified packages are in the "Project.toml"
if isfile("Project.toml")
    println("Project.toml is there!")
    println("\n--- activate project -------------------------------------------------------- \n")
    import Pkg; Pkg.activate(".")
    println("\n--- activate project resolve version conflicts, build Manifest.toml --------- \n")
    Pkg.resolve()
    println("\n--- END activate project and resolve version conflicts ---------------------- \n")
else 
    error("Project.toml is not there!")
end
# --- install packages, if they do not exist in current project environment:
s_package = "LLVMExtra_jll"
if VERSION >= v"1.7.0" && ~isinstalled(s_package)
    Pkg.add(s_package)
    error("\"$s_package\" had to be installed in the current project!")
end

# --- make shure "PackageCompiler" is not includet in current project environment:
if isinstalled("PackageCompiler")
    error("\"PackageCompiler\" is includet in local \"Project.toml\"")
end

for s_package in packages_
    if ~isinstalled(s_package)
        @warn("\"$s_package\" had to be installed in the current project!")
        Pkg.add(s_package)
    end
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

println("\npwd(): ", pwd(), "\n")

if isfile("Manifest.toml")
    rm("Manifest.toml"; force=true)
else
    @warn(string("After Base.active_project(): Manifest.toml not found!"))
end

# --- start compile: ------------------------------------------------------------------------------------------------------------
Pkg.activate() # swtch back to common environment
cd("..")
s_dir_above = []
if isdir(s_app)
    s_dir_above = pwd()
    println("\npwd(): ", pwd(), "\n")
    if isdir(s_compiled)
        d_ = Dates.format(Dates.now(), "_HHMM")
        s_compiled = string(s_compiled, d_)
    end
    s_start_PC = "start_PC.jl"
    if Sys.iswindows()
        cd_proj_sub_dir = string("cd \"", s_dir_above, "\"")
        s_comp_cmd = string("$s_julia -q --color=yes --startup-file=no --project --eval \"using PackageCompiler; create_app(\\\"$s_app\\\", \\\"$s_compiled\\\"; force=true, include_lazy_artifacts=true)\"")
        s_comp_cmd = string("$s_julia -q --color=yes --startup-file=no --project -- $s_start_PC")
        s_bat = "compile_app.bat"
        fid = open(s_bat, "w")
        println(fid, cd_proj_sub_dir)
        println(fid, s_comp_cmd)
        close(fid)
        fid = open(s_start_PC, "w")
            println(fid, string("run(`cmd /C 'title '\"", s_compiled, "\"`)"))
            println(fid, string("cd(raw\"", s_dir_above, "\")"))
            # println(fid, string("import Pkg; Pkg.build(\"Tulip\")"))
            # println(fid, string("println(\"abspath(PROGRAM_FILE): \", abspath(PROGRAM_FILE))"))
            # println(fid, string("println(\"@__FILE__: \", @__FILE__)"))
            println(fid, string("using PackageCompiler"))
            println(fid, string("create_app(\"$s_app\", \"$s_compiled\"; force=true, include_lazy_artifacts=true)"))
        close(fid)
        s_bat_full = joinpath(s_dir_above, s_bat)
        cmd_ = Cmd(`cmd /c start \"\" $s_bat`; windows_verbatim=true, detach=true)
        # cmd_ = Cmd(`cmd /k start \"\" $s_bat`; windows_verbatim=true, detach=true)
        # println(cmd_)
        run(cmd_)
    else
        error("Not yet ready for Linux- and Mac-OS")
    end
else
    error("Project folder not found!")
end
cd(startdir)

