# AppDir

This is a directory for projects that should be compiled via "PackageCompiler".

Julia Version should be at least v1.6.7

For compilation advice I refer to the site:
https://julialang.github.io/PackageCompiler.jl/stable/apps.html

There are six projects:

- "`MyAppHelloTulip`" minimal example with the package `Tulip`
- "`MyTulipHello`" experimental project including a renamed version of `Tulip` (new name is `MyTulip` )
- "`MyGLMakieApp`" is the example figure from the `GLMakie` manual with the feature "`SliderGrid()`"
- "`InteractiveEquivalentCircuit_simple`" is an interactive `GLMakie` figure. <br />
It depends on the package: "`EquivalentCircuits.jl`". <br />
Depicted is a `Nyquist Plot` that changes it shape dependent on the parameters of an `EquivalentCircuit` <br />
of the form `R1-L2-[P3,R4]-[P5,R6]-[P7,R8]` (where `P` stands for: *constant phase element*, also referred to as `CPE` or `Q`)
- "`InteractiveEquivalentCircuit`" is similar to "`InteractiveEquivalentCircuit_simple`", <br />
with the difference: there are additional plots for each of the three [RP]-elements (often reffered to as RC-circuit). <br />
These additional plots can be switched on and off.
- "`InteractiveNyquist`" the interface is the same as for the previous, but this project does not relay <br />
on the package "`EquivalentCircuits.jl`" 

## Current Status (17-Feb-2023):

The compiled `*.exe*` are only operational on the build machine :-( <br />
Suggestions how to fix it are welcome!



