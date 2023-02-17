import Tulip, GLMakie, Pkg
if isfile("Project.toml") 
    Pkg.activate(".")
else
    cd("InteractiveNyquist")
    if isfile("Project.toml") 
        Pkg.activate(".")
    else
        error("----------------  Project.toml is missing!   ------------------------")
    end
end
Pkg.resolve()
Pkg.build("Tulip")
Pkg.build("GLMakie")
Tulip.__init__();
GLMakie.Makie.__init__();
@info("======  End Precompile_app.jl   ======")
