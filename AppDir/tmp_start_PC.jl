run(`cmd /C 'title '"tmp_copy_InteractiveEquivalentCircuit_julia_stable_j1.8.5_PCv2.1.5"`)
cd(raw"C:\data\git_repos\own_repos\Stefans_Julia_RePo\AppDir")
using PackageCompiler
create_app("tmp_copy_InteractiveEquivalentCircuit_julia_stable", "tmp_copy_InteractiveEquivalentCircuit_julia_stable_j1.8.5_PCv2.1.5"; force=true, include_lazy_artifacts=true)
