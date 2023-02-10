# AppDir
This is a directory for projects that should be compiled via "PackageCompiler".

Julia Version should be at least v1.8.5

Currently the compiled *.exe crashes :-(

For compilation advice I refer to the site:
https://julialang.github.io/PackageCompiler.jl/stable/apps.html

The project "InteractiveEquivalentCircuit" is an interactive "GLMakie" figure.
I relays on the package: "EquivalentCircuits.jl"

It might be necessary to install the master version of this package via:

```
using Pkg; Pkg.add(url="https://github.com/MaximeVH/EquivalentCircuits.jl.git#master")

```
If compilation makes trouble and the error message starts with:

```
InitError(mod=:micromamba_jll, 
```

You may have a look at:

https://github.com/JuliaLang/PackageCompiler.jl/issues/784
