# AppDir
This is a directory for projects that should be compiled via "PackageCompiler".

Julia Version should be at least v1.6.7

For compilation advice I refer to the site:
https://julialang.github.io/PackageCompiler.jl/stable/apps.html

There are two projects:
- "`MyGLMakieApp`" is the example figure from the `GLMakie` manual with the feature "`SliderGrid()`"
- "`InteractiveEquivalentCircuit`" is an interactive `GLMakie` figure. <br />
It depends on the package: "`EquivalentCircuits.jl`". <br />
Depicted is a `Nyquist Plot` that changes it shape dependent on the parameters of an `EquivalentCircuit` <br />
of the form `R1-L2-[P3,R4]-[P5,R6]-[P7,R8]` (where `P` stands for: *constant phase element*, also referred to as `CPE` or `Q`)


