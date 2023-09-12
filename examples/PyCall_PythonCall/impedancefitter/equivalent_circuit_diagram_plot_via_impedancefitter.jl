# --- relevant adresses -----------------------------------------------------------------------------------------------
# || https://pypi.org/project/impedancefitter/#files
# || online docu: https://impedancefitter.readthedocs.io/en/v2.0.0/
# || current version is listed here: https://libraries.io/pypi/impedancefitter
# || GitHub-Repository: https://github.com/j-zimmermann/ImpedanceFitter
# --- installation via Conda: -----------------------------------------------------------------------------------------
# || julia> using Conda; Conda.add("impedancefitter")
# || ------------------------------------------------------------------------------------------------------------------
# --- installation via PythonCall:
# || https://cjdoris.github.io/PythonCall.jl/stable/
# || https://github.com/cjdoris/PythonCall.jl/issues/245
# || ---
# || 1.) remove package reminders via Conda, if the package was already installed and is not operational:
# || julia> import Conda; Conda.rm("impedancefitter")
# || julia> import Conda; Conda.pip("uninstall", "impedancefitter")
# ||
# || 2.) restart julia
# ||
# || 3.) remove via CondaPkg.rm_pip(), if the package was already installed and is not operational:
# || julia> import CondaPkg; CondaPkg.rm_pip("impedancefitter")
# ||
# || 4.) Install via CondaPkg.add_pip():
# || julia> import CondaPkg; CondaPkg.add_pip("impedancefitter")
# || in case a specific version should be installed, specify the version:
# || julia> import CondaPkg; CondaPkg.add_pip("impedancefitter", version="2.0.7")
# ----------------------------------------------------------------------------------------------------------------------
# || Trouble shooting
# || if the package cannot be used, make sure the content of 
# || a.) the Conda-constant "Conda.ROOTENV" makes sense.
# || b.) the environment variable "CONDA_JL_HOME" is meaningfull
# || c.) figure out which directory is meaningfull on your computer,
# ||     (in my case it was: "/home/stefan/.julia/conda/3")
# ---------------------------------------------------------------------------------------------------------------------
# || the following should be started only once
if false
    ENV["CONDA_JL_HOME"] = "/home/stefan/.julia/conda/3"
    const Conda.ROOTENV = "/home/stefan/.julia/conda/3"
    import Pkg; Pkg.build("PyCall") # this will (re-)build as well "Conda"
    exit()
end

# ---------------------------------------------------------------------------------------------------------------------
b_PyCall = true
if b_PyCall
    using PyCall
    impfit = PyCall.pyimport("impedancefitter")
else
    using PythonCall
    impfit = PythonCall.pyimport("impedancefitter")
end

# --- circuit_model_preset = "R1-[C2,R3-[C4,R5]]" ("EquivalentCircuits.jl"-notation)
model = "R_f1 + parallel(C_f2 + parallel(C_f4, R_f5), R_f3)"

# --- draw / plot equivalent circuit diagram via impedancefitter.py
impfit.draw_scheme(model)
