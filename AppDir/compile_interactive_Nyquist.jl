# ---      julia -q --startup-file=no --project
# ---      include("compile_interactive_Nyquist.jl")
# --- https://julialang.github.io/PackageCompiler.jl/stable/apps.html
# -------------------------------------------------------------------------------------------

import Pkg, Chain
using PackageCompiler, Printf

# --- local function:
get_pkg_version(name::AbstractString) =
    Chain.@chain Pkg.dependencies() begin
        values
        [x for x in _ if x.name == name]
        only
        _.version
end

# ---
vPackageComp = get_pkg_version("PackageCompiler") 
s_app = "InteractiveNyquist"
s_compiled = string(s_app, "_j", VERSION, "_PCv", vPackageComp)
s_env = @sprintf("%s/%s", splitpath(Base.active_project())[end-2], splitpath(Base.active_project())[end-1])
s_win_title = string("v", VERSION, ", App: ", s_app, s_env)
run(`cmd /C 'title '"$s_win_title"`)

println("Environment: ", Base.active_project())

if isfile(string("./", s_app, "/Manifest.toml"))
    println("is there!")
end
# create_app(s_app, s_compiled; 
#     force=true, include_lazy_artifacts=true)

